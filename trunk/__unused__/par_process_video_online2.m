% online video processing pipeline
pdisp(repmat('=',1,80))

%% load persistent data
curr_mfile = which(mfilename());
mfile_dir = fileparts(curr_mfile);
data_dir=[mfile_dir,filesep,'..',filesep,'data'];
try
  if ~exist('descriptor_representatives','var')
    load([data_dir,filesep,'descriptor_representatives.mat'],'descriptor_representatives')
%     load descriptor_representatives descriptor_representatives
  end
  if ~exist('classifiers','var')
    load classifiers3.mat classifiers
  end
  if ~exist('regressors','var')
    load classifiers3.mat regressors
  end
  if ~exist('blur_classifier','var')
    %load([mfile_dir,filesep,'..',filesep,'data',filesep,'blur_classifier3.mat'],'blur_classifier')
%     load blur_classifier3 blur_classifier
        blur_classifier=load([data_dir,filesep,'blur_classifier_net.mat'],'net');
  end
catch e
  warning(e.identifier,e.message)
end

%% init params and options

video_filenames = read_files_list([mfile_dir,filesep,'video_files_list.txt']);
% TEST:
% video_filenames = repmat({'test.mp4'},1,length(video_filenames));

params.FeatureDetector = 'SURF';
params.Dimension = 64;
params.NumFeatureClusters = 4000;
params.NumSemanticClusters = 20;
params.NumWorkers = 4;
params.StartFrame = 100;
params.L2DeltaThreshold = 0.15;
params.NumFrames = 200;
params

% process options:
options.Plot                  = true;
options.Save                  = false;
options.GatherDescriptors     = true;
options.EstimateBlur          = true;
options.ComputeSuperpixels    = false;
options.ComputeObjectHeatMap  = false;
options.GatherBagsOfWords     = true;
options.GatherSemanticCues    = false;
options.ComputeCandidateBOWs  = false;

options

% coreset params

feature_coreset_alg = KMedianCoresetAlg;
feature_coreset_alg.k = params.NumFeatureClusters;
feature_coreset_alg.t = 50;
feature_coreset_alg.coresetType = KMedianCoresetAlg.linearInK;
feature_coreset_alg.bicriteriaAlg.robustAlg.beta = 10;
feature_coreset_alg.bicriteriaAlg.robustAlg.partitionFraction = 1/2;
feature_coreset_alg.bicriteriaAlg.robustAlg.costMethod = ClusterVector.maxDistanceCost;
feature_coreset_alg.bicriteriaAlg.robustAlg.nIterations = 2;
feature_coreset_alg.bicriteriaAlg.robustAlg.gamma = 1;
feature_coreset_alg.bicriteriaAlg.robustAlg.figure.sample = false;
feature_coreset_alg.bicriteriaAlg.robustAlg.figure.opt = false;
feature_coreset_alg.bicriteriaAlg.robustAlg.figure.iteration = false;
feature_coreset_save_tree = false;
feature_coreset_leaf_size = 100;

semantic_coreset_alg = KMedianCoresetAlg;
semantic_coreset_alg.k = params.NumSemanticClusters;
semantic_coreset_alg.t = 10;
semantic_coreset_alg.coresetType = KMedianCoresetAlg.linearInK;
semantic_coreset_alg.bicriteriaAlg.robustAlg.beta = 10;
semantic_coreset_alg.bicriteriaAlg.robustAlg.partitionFraction = 1/2;
semantic_coreset_alg.bicriteriaAlg.robustAlg.costMethod = ClusterVector.maxDistanceCost;
semantic_coreset_alg.bicriteriaAlg.robustAlg.nIterations = 2;
semantic_coreset_alg.bicriteriaAlg.robustAlg.gamma = 1;
semantic_coreset_alg.bicriteriaAlg.robustAlg.figure.sample = false;
semantic_coreset_alg.bicriteriaAlg.robustAlg.figure.opt = false;
semantic_coreset_alg.bicriteriaAlg.robustAlg.figure.iteration = false;
semantic_coreset_save_tree = true;
semantic_coreset_leaf_size = 20;

coreset_params.FeatureCoresetLeafSize = feature_coreset_leaf_size;
coreset_params.FeatureCoresetAlgorithm = feature_coreset_alg;
coreset_params.FeatureCoresetSaveTree = feature_coreset_save_tree;
coreset_params.SemanticCoresetLeafSize = semantic_coreset_leaf_size;
coreset_params.SemanticCoresetAlgorithm = semantic_coreset_alg;
coreset_params.SemanticCoresetSaveTree = semantic_coreset_save_tree;
coreset_params

%% init cluster

% create attached files
attached_files = {};
attached_files = cat(2,attached_files,dirrec('../../matlab_distributed_coreset','.m'));
attached_files = cat(2,attached_files,dirrec(pwd,'.m'));

% create cluster
cluster = init_cluster('local','restart','NumWorkers',params.NumWorkers, ...
  'AttachedFiles',attached_files);

% if 1%spmd params and options
if 1%spmd
  
  spmd_options.Verbose = (labindex == 1);
  pdisp([],'SetVerbose',spmd_options.Verbose);

end

%% init video stream
pdisp('Initializing video stream ...');
if 1%spmd
  
  % get filename and start frame from labindex
  video_filename = video_filenames{labindex};
  start_frame = 1;
  % TEST:
  start_frame = 1000*(labindex-1)+1;
  
  % create video stream
  video_stream = VideoStream(video_filename,'StartFrame',start_frame);
  curr_frame = 0;
  prev_frame = 0;
  num_frames_processed = 0;
  
end
pdisp('Done!')

%% init coreset streams
pdisp('Initializing coreset streams ...');

if options.GatherDescriptors
  
  % root feature coreset
  root_feature_coreset = Stream;
  root_feature_coreset.leafSize = coreset_params.FeatureCoresetLeafSize;
  root_feature_coreset.coresetAlg = coreset_params.FeatureCoresetAlgorithm;
  root_feature_coreset.saveTree = coreset_params.FeatureCoresetSaveTree;
  pdisp('  feature coreset root initialized')

  % worker feature coresets
  if 1%spmd
    spmd_feature_coreset = Stream;
    spmd_feature_coreset.leafSize = coreset_params.FeatureCoresetLeafSize;
    spmd_feature_coreset.coresetAlg = coreset_params.FeatureCoresetAlgorithm;
    spmd_feature_coreset.saveTree = coreset_params.FeatureCoresetSaveTree;
    pdisp('  feature coreset worker initialized')
  end
  
end

if options.GatherBagsOfWords
  
  % root semantic coreset
  root_semantic_coreset = Stream;
  root_semantic_coreset.leafSize = coreset_params.SemanticCoresetLeafSize;
  root_semantic_coreset.coresetAlg = coreset_params.SemanticCoresetAlgorithm;
  root_semantic_coreset.saveTree = coreset_params.SemanticCoresetSaveTree;
  pdisp('  semantic coreset root initialized')
  
  % worker semantic coresets
  if 1%spmd
    spmd_semantic_coreset = Stream;
    spmd_semantic_coreset.leafSize = coreset_params.SemanticCoresetLeafSize;
    spmd_semantic_coreset.coresetAlg = coreset_params.SemanticCoresetAlgorithm;
    spmd_semantic_coreset.saveTree = coreset_params.SemanticCoresetSaveTree;
    pdisp('  semantic coreset worker initialized')
  end

end

disp('Done!')

%% init variables
pdisp('Initializing variables ...')

% seed rng
% this is preferred syntax to rand/randn seed
rng(0,'twister')

if 1%spmd
  
  % feature level variables
  I = [];
  tracklets = [];
  tracklets.current_frame = 0;
  tracklets.tracklet_cnt = 0;
  trackletss = cell(1,params.NumFrames);
  descriptors = [];
  descriptor_count = 0;
  
  % semantic level variables
  bags_of_words = [];
  norm_bows = [];
  semantic_cues = [];
  semantic_cues2 = [];
  blur_measure = [];
  blur_measure2 = [];
  
  processed_frame_idx = [];

end

pdisp('Done!')

%% process video
pdisp(repmat('-',1,60))
pdisp('Streaming ...')

if 1%spmd
  
  tic
  while video_stream.IsActive && num_frames_processed < params.NumFrames
    
    % store previous frame vars
    prev_frame = curr_frame;
    prev_tracklets = tracklets;
    prev_I = I;
    
    % read next frame
    [I,curr_frame] = video_stream.get_next_frame();
    pdisp(['processing frame ' num2str(curr_frame)])
    Igray=rgb2gray(double(I)/255);
    % update frame indexing
    num_frames_processed = num_frames_processed+1;
    
    %% feature level processing
    
    % TODO: explain, get rid of continue
    if isfield(tracklets,'old_I')
      track_norm = norm(double(tracklets.old_I(:))-double(I(:)))/norm(double(I(:)));
      if track_norm < params.L2DeltaThreshold
        continue
      end
    end
    
    % update tracklets
    tracklet_params.method = params.FeatureDetector;
    tracklet_params.current_frame = curr_frame;
    tracklet_params.tracklet_cnt_start = tracklets.tracklet_cnt;
    tracklet_params.interference_mask = video_stream.InterferenceMask;
    try
      
      tracklets = update_tracklets(prev_tracklets,I,tracklet_params);
 
    catch e
      %warning(e.identifier,e.message)
      pdisp('  Tracklet update failed: restarting tracking ...')
      
      % reset tracklets
      prev_tracklets = [];
      prev_tracklets.current_frame = tracklet_params.current_frame;
      
      try
        % update tracklets (using reset previous tracklets)
        tracklets = update_tracklets(prev_tracklets,I,tracklet_params);
        pdisp('  Updated OK.')
      catch e
        %warning(e.identifier,e.message)
        pdisp('  Tracklet restart failed: resetting tracklets.')
        tracklets = [];
      end
      
    end
    
    % estimate blur
    update_descriptors = true;
    if options.EstimateBlur
      bb = 40;
%       bv=estimate_blur_indicators3(double(Igray(bb:(end-bb),bb:(end-bb),:)),[1  4 8],tracklet_params.interference_mask(bb:(end-bb),bb:(end-bb),:));
      bv=estimate_blur_indicators3(double(Igray(:,:,:)),[1  4 8],tracklet_params.interference_mask(:,:,:));
%       blur_measure(end+1) = estimate_blur(I(bb:(end-bb),bb:(end-bb),:));
%       Ib = I(bb:(end-bb),bb:(end-bb),:);
%       Ib = Ib(1:2:end,1:2:end,:);
      
%       bv = estimate_blur_indicators2(Ib,[2*1.5.^[0:4]]);
%       blur_measure2(end+1) = svmclassify(blur_classifier,bv(:)');
      blur_measure2(end+1)=blur_classifier.net(bv)>0.6;
      if blur_measure2(end)
        update_descriptors = false;
      end
    end
    
    % update descriptors
    if options.GatherDescriptors
      if update_descriptors
        
        F = tracklets.features;
        
        % record new descriptors
        descriptors = cat(1,descriptors,F);
        
        % add descriptors to coreset
        spmd_feature_coreset.addPointSet(PointFunctionSet(Matrix(F)));
        pdisp(['  feature coreset: added ' num2str(size(F,1)) ' points'])
        
      end
    end

    % compute superpixels
    if options.ComputeSuperpixels
      tracklets.superpixels = mexSEEDS(I,50);
      tracklets.superpixels = tracklets.superpixels+1;
      tracklets.merged_superpixels = update_superpixels(tracklets.superpixels,double(I));
    end
    
    % compute object heat map
    if options.ComputeObjectHeatMap
      %RESCALE_FACTOR = 4;
      %I2 = imresize(I,1/RESCALE_FACTOR,'bilinear');
      %tracklets.boxes = runObjectness(I,500);
      tracklets.boxes = runObjectness(I(1:4:end,1:4:end,:),400);tracklets.boxes(:,1:4) = tracklets.boxes(:,1:4)*4;
      tracklets.boxes = prune_boxes_by_mask(tracklets.boxes,tracklet_params.interference_mask,4);
      tracklets.boxes = tracklets.boxes(1:min(end,20),:);
      %tracklets.boxes(:,1:4) = tracklets.boxes(:,1:4)*RESCALE_FACTOR;
      tracklets.objHeatMap = computeObjectnessHeatMap(I,tracklets.boxes);
    end
    
    % TODO: explain
    if curr_frame > 1
      try
        tracklets2 = tracklets;
        tracklets2 = rmfield(tracklets2,'old_I');
        tracklets2 = rmfield(tracklets2,'interference_mask');
        trackletss{curr_frame} = tracklets2;
      catch e
        warning(e.identifier,e.message)
      end
    end
    
    %% semantic level processing

    % gather bag of words
    if options.GatherBagsOfWords

      % TODO: knn
      pdists = pdist2(tracklets.features,descriptor_representatives);
      [~,knn_idx] = (min(pdists,[],2));
      B = hist(knn_idx,1:params.NumFeatureClusters);
      B_norm = B./sum(B);
      
      % record new bag of words
      bags_of_words = cat(1,bags_of_words,B);
      norm_bows = cat(1,norm_bows,B_norm);
      
      % add bow vector to coreset
      spmd_semantic_coreset.addPointSet(PointFunctionSet(Matrix(B)));
      pdisp(['  semantic coreset: added ' num2str(size(B,1)) ' points'])
 
    end
    
    % gather semantic cues
    if options.GatherSemanticCues
      %cue = [];
      %for i = 1:length(classifiers)
      %  cue(i) = svmclassify(classifiers{i},bags_of_words(:,end)');
      %end
      sbow = generate_semantic_cues(I,[],tracklets.features,...
        tracklets.current_trackpoints,classifiers,descriptor_representatives);
      semantic_cues(:,end+1) = sbow;
    end
    
    % compute candidate bags of words
    if options.ComputeCandidateBOWs
      sbow = generate_semantic_cues(I,tracklets.boxes,tracklets.features, ...
        tracklets.current_trackpoints,regressors,descriptor_representatives);
      semantic_cues2(:,end+1) = sbow;
    end
    
    %% 
    
    % update indices of processed frames
    processed_frame_idx = cat(1,processed_frame_idx,curr_frame);
    
    %% plot
    if options.Plot
      try
        
%         figure(101)
        subplot(221);
        image(I)
        hold on
        px = tracklets.current_trackpoints.Location(:,1);
        py = tracklets.current_trackpoints.Location(:,2);
        plot(px,py,'xy','LineWidth',2)
        
        title_str = ['frame ' num2str(curr_frame)];
        if options.EstimateBlur
          title_str = strcat(title_str,[', blur = ' num2str(blur_measure2(end))]);
        end
        title(title_str)
         
        if options.ComputeObjectHeatMap
%           figure(102)
          subplot(223);
          imshow(tracklets.objHeatMap,[]);
        end        
        
        if options.GatherBagsOfWords
%           figure(201)
          subplot(1,3,3)
          
          % display last n bow vectors
          num_last_frames = 60;
          
          % pick k_disp best clusters to display
          k_disp = 20;
          [~,sorted_idx] = sort(sum(bags_of_words,1));
          best_idx = sorted_idx(end:-1:end-k_disp+1);
          
          lastn_bows = norm_bows(:,best_idx).*255;
          if size(lastn_bows,1) <= num_last_frames
            lastn_bows = cat(1,lastn_bows,zeros(num_last_frames-size(lastn_bows,1),k_disp));
          else
            lastn_bows = lastn_bows(end-num_last_frames+1:end,:);
          end
          
          % boost color display
          lastn_bows = lastn_bows.*10;
          image(lastn_bows');
          
          % display best clusters
          set(gca,'ytick',1:k_disp)
          set(gca,'YTickLabel',{num2str(best_idx')})
          
        end
        
        if options.GatherSemanticCues
%           figure(202)
          subplot(222)
          %imshow([semantic_cues2(:,i1:end);semantic_cues(:,i1:end);bags_of_words(:,i1:end)/3],[0 1])
          %colormap jet
          %subplot(222)
          imshow(imresize(semantic_cues2(:,i1:end),[230,numel(i1:size(semantic_cues2,2))],'nearest'),[])
          colormap jet
        end
        
        drawnow
        
      catch e
        warning(e.identifier,e.message)
      end
    end
    
  end
  
  t = toc;
  mins = floor(t/60);
  secs = rem(t,60);
  pdisp('Done!')
  pdisp([num2str(mins) ' minutes and ' num2str(secs) ' seconds elapsed'])
  pdisp([num2str(curr_frame) '/' num2str(video_stream.NumFrames) ' frames processed'])
  
end

%% process results
pdisp(repmat('-',1,60))
pdisp('Finished streaming:')
if 1%spmd
  pdisp([],'SetVerbose',true);
end

if options.GatherDescriptors
  
  % get unified feature coreset
  pdisp('Computing unified feature coreset ...')
  for i = 1:size(Composite)
    if size(spmd_feature_coreset,2) > 1
      C = spmd_feature_coreset{i};
    else
      C = spmd_feature_coreset;
    end
    U = C.getUnifiedCoreset();
    root_feature_coreset.addPointSet(PointFunctionSet(Matrix(U.M.m),Matrix(U.W.m)))
    pdisp(['  Lab ' num2str(i) ' feature coreset: added ' num2str(C.numPointsStreamed) ' points'])
  end
  U1 = root_feature_coreset.getUnifiedCoreset();
  feature_core_points = double(U1.M.m);
  feature_weights = double(U1.W.m);
  pdisp('Done!')
  
  % compute feature clustering
  pdisp('Computing feature clustering ...')
  %   here we compute descriptor representatives
  %   for k = 4000 we need a lot more frames
  %   descriptor representatives file contains this from previous runs
  %   use k1 = 10 as dummy example
  k1 = 10;
  opt_weights = struct('weight',feature_weights);
  [feature_idx,feature_ctrs,feature_dists] = fkmeans(feature_core_points,k1,opt_weights);
  pdisp('Done!')
  
end

if options.GatherBagsOfWords

  % get unified semantic coreset
  pdisp('Computing unified semantic coreset ...')
  for i = 1:size(Composite)
    if size(spmd_semantic_coreset,2) > 1
      C = spmd_semantic_coreset{i};
    else
      C = spmd_semantic_coreset;
    end
    U = C.getUnifiedCoreset();
    root_semantic_coreset.addPointSet(PointFunctionSet(Matrix(U.M.m),Matrix(U.W.m)))
    pdisp(['  Lab ' num2str(i) ' semantic coreset: added ' num2str(C.numPointsStreamed) ' points'])
  end
  U2 = root_semantic_coreset.getUnifiedCoreset();
  semantic_core_points = double(U2.M.m);
  semantic_weights = double(U2.W.m);
  pdisp('Done!')

  % compute semantic clustering
  pdisp('Computing semantic clustering ...')
  k2 = params.NumSemanticClusters;
  opt_weights = struct('weight',semantic_weights);
  [semantic_idx,semantic_ctrs,semantic_dists] = fkmeans(semantic_core_points,k1,opt_weights);
  pdisp('Done!')

end

%% save data
pdisp('Saving data ...')
if options.Save
  for i = 1:size(Composite)
    [savefile_path,savefile_name,savefile_ext] = fileparts(video_filename);
    save(['data/' savefile_name '_save_' num2str(labindex) '.mat']);
  end
end
pdisp('Done!')

%% plot
if options.Plot
  
  if options.GatherDescriptors
    figure(110)
    plot_kmeans(feature_core_points,k1,feature_idx,feature_ctrs,'title','feature coreset kmeans')
  end
  
  if options.GatherBagsOfWords
%     figure(210)
%     plot_kmeans(semantic_core_points,k2,semantic_idx,semantic_ctrs,'title','semantic coreset kmeans')
  end
  
  % re-run the video, show track matches between subsequent frames
%   figure(301)  
%   for i = 2:params.NumFrames
%     I = video_stream.get_frame(i);
%     tracklets = trackletss{i};
%     prev_I = video_stream.get_frame(i-1);
%     tracklets.old_I = prev_I;
%     if i>1
%       try
%         show_points
%       catch e
%         warning(e.identifier,e.message)
%       end
%       drawnow
%     end
%   end
  
  % draw a tracking-indices graph
%   figure(302)
%   for i = 1:length(trackletss)
%     if isempty(trackletss{i})
%       continue
%     end
%     plot(i*ones(size(trackletss{i}.track_indices(:))),trackletss{i}.track_indices(:),'.')
%     drawnow
%   end
%   xlabel('Frame')
%   ylabel('Track Index')
  
end

function res=process_file(video_filename,labindex,params,options,feature_coreset_alg,semantic_coreset_alg,coreset_params)
if (~exist('labindex','var'))
    labindex=1;
end
% online video processing pipeline
profile off, profile on
pdisp(repmat('=',1,80))
res=[];
spmd_feature_coreset=[];
root_semantic_coreset=[];
bow_leaf_buffer=[];
%% load persistent data
try
    if ~exist('descriptor_representatives','var')
        load descriptor_representatives_66 descriptor_representatives
        vq_preproc_mtx=eye(66);
        desc=66;
        descriptors_kdtree=KDTreeSearcher(descriptor_representatives*vq_preproc_mtx);
        %             load descriptor_representatives_64 descriptor_representatives
        %             vq_preproc_mtx=diag([ones(1,64),0,0]);
        %             desc=64;
        %         load descriptors5000
    end
    if ~exist('classifiers','var')
        load classifiers3.mat classifiers
        
    end
    if ~exist('regressors','var')
        load classifiers3.mat regressors
    end
    if ~exist('blur_classifier','var')
        %load([mfile_dir,filesep,'..',filesep,'data',filesep,'blur_classifier3.mat'],'blur_classifier')
        %load blur_classifier3 blur_classifier
        blur_classifier = load('blur_classifier_net.mat','net');
    end
catch e
    warning(e.identifier,e.message)
end
%% init params and options

% video_filenames = read_files_list('video_files_list2.txt');
% video_filenames={video_filenames{1:10}};
caffe=[];

%% init cluster

% create attached files
attached_files = {};
attached_files = cat(2,attached_files,dirrec(pwd,'.m'));
attached_files = cat(2,attached_files,dirrec('../../matlab_distributed_coreset','.m'));

% create cluster
%     cluster = init_cluster('local','restart','NumWorkers',params.NumWorkers, ...
%         'AttachedFiles',attached_files);
if (params.use_caffe)
    caffe=CaffeWrapper(struct('model_def_file','/home/rosman/Downloads/caffe-master/examples/imagenet_deploy.prototxt',...
        'model_data_file','/home/rosman/Downloads/caffe-master/data/caffe_reference_imagenet_model'));
end
% spmd% if 1 params and options
%     spmd% if 1
if options.Save
    [savefile_path,savefile_name,savefile_ext] = fileparts(video_filename);
    save_name=['data/' savefile_name '_results.mat'];
    disp(save_name);
    
    if exist(save_name,'file')
        return;
    end
end

spmd_options.Verbose = (labindex == 1);
pdisp([],'SetVerbose',spmd_options.Verbose);

%     end
%     REREAD_VIDEO_STREAM=true;
% REREAD_VIDEO_STREAM=false; % false for debug only, use true otherwise
%% init video stream
%     fidx=unique(min(numel(video_filenames),n_worker+(1:params.NumWorkers)));
%     video_filenames2={video_filenames{fidx}};

pdisp('Initializing video stream ...');
%     spmd% if 1
%         fidx2=labindex+(n_worker-1);
%         disp(fidx2);
% get filename and start frame from labindex
%         video_filename = video_filenames2{fidx2};
start_frame = 1;
% TEST:
%start_frame = 1000*(labindex-1)+1;

% create video stream
%         if (REREAD_VIDEO_STREAM) || ~exist('video_stream','var')
video_stream = VideoStream(video_filename,'StartFrame',start_frame);
%         else
%             video_stream.set_next_frame(1);
%         end

curr_frame = 0;
prev_frame = 0;
num_frames_processed = 0;

%     end
pdisp('Done!')
%% init coreset streams
pdisp('Initializing coreset streams ...');

% init feature coresets
if options.GatherDescriptors
    
    % root feature coreset
    root_feature_coreset = Stream;
    root_feature_coreset.leafSize = coreset_params.FeatureCoresetLeafSize;
    root_feature_coreset.coresetAlg = coreset_params.FeatureCoresetAlgorithm;
    root_feature_coreset.saveTree = coreset_params.FeatureCoresetSaveTree;
    pdisp('  feature coreset root initialized')
    
    % worker feature coresets
    %         spmd% if 1
    spmd_feature_coreset = Stream;
    spmd_feature_coreset.leafSize = coreset_params.FeatureCoresetLeafSize;
    spmd_feature_coreset.coresetAlg = coreset_params.FeatureCoresetAlgorithm;
    spmd_feature_coreset.saveTree = coreset_params.FeatureCoresetSaveTree;
    pdisp('  feature coreset worker initialized')
    %         end
    
end

% init semantic coresets
if options.GatherBagsOfWords
    
    % root semantic coreset
    root_semantic_coreset = Stream;
    root_semantic_coreset.leafSize = coreset_params.SemanticCoresetLeafSize;
    root_semantic_coreset.coresetAlg = coreset_params.SemanticCoresetAlgorithm;
    root_semantic_coreset.saveTree = coreset_params.SemanticCoresetSaveTree;
    pdisp('  semantic coreset root initialized')
    
    % worker semantic coresets
    %         spmd% if 1
    spmd_semantic_coreset = Stream;
    spmd_semantic_coreset.leafSize = coreset_params.SemanticCoresetLeafSize;
    spmd_semantic_coreset.coresetAlg = coreset_params.SemanticCoresetAlgorithm;
    spmd_semantic_coreset.saveTree = coreset_params.SemanticCoresetSaveTree;
    pdisp('  semantic coreset worker initialized')
    %         end
    
end

disp('Done!')

%% init variables
pdisp('Initializing variables ...')

% seed rng
% this is preferred syntax to rand/randn seed
rng(0,'twister')

%     spmd% if 1

% feature level variables
I = [];
tracklets = [];
tracklets.current_frame = 0;
tracklets.tracklet_cnt = 0;
descriptors = [];
%         descriptor_count = 0;
%         prev_tracklets=[];
% semantic level variables
bags_of_words = [];
%     norm_bows = [];
semantic_cues = [];
semantic_cues2 = [];
%         blur_measure = [];
blur_measure2 = [];
heatmaps=[];
feature_weights=[];
feature_core_points=[];

processed_frame_idx = [];
BOW_buffer=[];
%     end

pdisp('Done!')

%% process video
pdisp(repmat('-',1,60))
pdisp('Streaming ...')

%     spmd% if 1

tic
while video_stream.IsActive && num_frames_processed < params.NumFrames
    
    % store previous frame vars
    prev_frame = curr_frame;
    prev_tracklets = tracklets;
    prev_I = I;
    
    % read next frame
    [I,curr_frame] = video_stream.get_next_frame();
    if (isfield(params,'ResampleImageSize'))
        I=imresize(I,params.ResampleImageSize,'nearest');
    end
    if (isempty(I))
        break;
    end
    pdisp(['processing frame ' num2str(curr_frame)])
    
    % update frame indexing
    num_frames_processed = num_frames_processed+1;
    
    %% feature level processing
    
    % TODO: explain, get rid of continue
    % do not collect descriptors,
    % add indicator function to not collect bags of words
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
        if (~params.use_tracking)
            prev_tracklets = [];
            prev_tracklets.current_frame = tracklet_params.current_frame;
        end
        
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
            tracklets2 = [];
            tracklets2.tracklet_cnt=tracklets.tracklet_cnt;
            tracklets=tracklets2;
        end
        
    end
    
    % estimate blur
    if options.EstimateBlur
        bv=estimate_blur_indicators3(double(Igray(:,:,:)),[1  4 8],tracklet_params.interference_mask(:,:,:));
        %       blur_measure(end+1) = estimate_blur(I(bb:(end-bb),bb:(end-bb),:));
        %       Ib = I(bb:(end-bb),bb:(end-bb),:);
        %       Ib = Ib(1:2:end,1:2:end,:);
        
        %       bv = estimate_blur_indicators2(Ib,[2*1.5.^[0:4]]);
        %       blur_measure2(end+1) = svmclassify(blur_classifier,bv(:)');
        blur_measure2(end+1)=blur_classifier.net(bv)>0.6;
        if blur_measure2(end)
            params.update_descriptors = false;
        end
    end
    
    % update descriptors
    if options.GatherDescriptors
        if params.update_descriptors
            
            F = tracklets.features;
            
            % record new descriptors
            descriptors = cat(1,descriptors,F);
            
            % add descriptors to coreset
            try
                spmd_feature_coreset.addPointSet(PointFunctionSet(Matrix(F)));
                pdisp(['  feature coreset: added ' num2str(size(F,1)) ' points'])
            catch
                spmd_feature_coreset;
            end
            
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
        tracklets.boxes_full = prune_boxes_by_mask(tracklets.boxes,tracklet_params.interference_mask,4);
        tracklets.boxes = tracklets.boxes_full(1:min(end,20),:);
        %tracklets.boxes(:,1:4) = tracklets.boxes(:,1:4)*RESCALE_FACTOR;
        tracklets.objHeatMap = computeObjectnessHeatMap(I,tracklets.boxes);
        save_heat_map=true;
        if (save_heat_map)
            heatmaps(:,:,end+1)=tracklets.objHeatMap;
        end
    end
    
    % TODO: explain
    % this is for tracklet difference plot
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
        if (params.use_caffe)
            B=0;
            for ii=1:size(tracklets.boxes,1)
                im=crop_image_box(I,tracklets.boxes(ii,1:4));
                caffe_res=caffe.classify_image(im);
                B=B+caffe_res;
            end
            
            B_norm = B(:)'./sum(B(:));
            BOW_buffer=cat(1,BOW_buffer,B_norm);
            if (size(BOW_buffer,1)>params.IIR_buffer_length)
                BOW_buffer=BOW_buffer(2:end,:);
            end
            BOW_weights=(1-params.IIR_alpha).^[-1:-1:-size(BOW_buffer,1)];
            B=sum(bsxfun(@times,BOW_buffer,BOW_weights(:)),1)/sum(BOW_weights);
            bags_of_words = cat(1,bags_of_words,B);
            bow_leaf_buffer=[bow_leaf_buffer,B(:)];
            if (size(bow_leaf_buffer,2)>40)
                spmd_semantic_coreset.addPointSet(PointFunctionSet(Matrix(bow_leaf_buffer)));
                bow_leaf_buffer=[];
            end
        else
            if isfield(tracklets,'features') && ~isempty(tracklets.features)
                
                % TODO: knn
                
%                 knn_idx=descriptors_kdtree.knnsearch(double(tracklets.features));
                                        pdists = pdist2(double(tracklets.features),double(descriptor_representatives*vq_preproc_mtx));
                                        [~,knn_idx] = (min(pdists,[],2));
                B = hist(knn_idx,1:params.NumFeatureClusters);
                %       BOW_buffer_idx=mod(BOW_buffer_idx,params.BOW_buffer_length)+1;
                %       BOW_weights_buffer(
                %       BOW_buffer(:,BOW_buffer_idx)=B;
                % record new bag of words
                %             BOW_buffer=cat(1,BOW_buffer,B);
                B_norm = B./sum(B);
                BOW_buffer=cat(1,BOW_buffer,B_norm);
                if (size(BOW_buffer,1)>params.IIR_buffer_length)
                    BOW_buffer=BOW_buffer(2:end,:);
                end
                BOW_weights=(1-params.IIR_alpha).^[-1:-1:-size(BOW_buffer,1)];
                B=sum(bsxfun(@times,BOW_buffer,BOW_weights(:)),1)/sum(BOW_weights);
                bags_of_words = cat(1,bags_of_words,B);
                %             norm_bows = cat(1,norm_bows,B_norm);
                
                % add bow vector to coreset
                spmd_semantic_coreset.addPointSet(PointFunctionSet(Matrix(B)));
                pdisp(['  semantic coreset: added ' num2str(size(B,1)) ' points'])
            end
        end
    end
    
    % gather semantic cues
    if options.GatherSemanticCues
        %cue = [];
        %for i = 1:length(classifiers)
        %  cue(i) = svmclassify(classifiers{i},bags_of_words(:,end)');
        %end
        sbow = generate_semantic_cues(I,[],tracklets.features,...
            tracklets.current_trackpoints,classifiers,vq_preproc_mtx*descriptor_representatives);
        semantic_cues(:,end+1) = sbow;
    end
    
    %     % compute candidate bags of words
    %     if options.ComputeCandidateBOWs
    %       sbow = generate_semantic_cues(I,tracklets.boxes,tracklets.features, ...
    %         tracklets.current_trackpoints,regressors,descriptor_representatives);
    %       semantic_cues2(:,end+1) = sbow;
    
    if options.UpdateCandidateBOWs%     end
        updated_classifiers=update_classifiers(I,[],tracklets.boxes,tracklets.features,tracklets.current_trackpoints,updated_classifiers,descriptor_representatives);
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
                subplot(222);imshow(I,[]);
                subplot(221);
                imshow(tracklets.objHeatMap,[]);
            end
            
            if options.GatherBagsOfWords
                %           figure(201)
                %           subplot(222)
                subplot(2,2,3:4);
                
                % display last n bow vectors
                num_last_frames = 500;
                
                % pick k_disp best clusters to display
                k_disp = 100;
                [~,sorted_idx] = sort(sum(bags_of_words,1));
                best_idx = sorted_idx(end:-1:end-k_disp+1);
                
                lastn_bows = bags_of_words(:,best_idx).*255;
                if size(lastn_bows,1) <= num_last_frames
                    lastn_bows = cat(1,lastn_bows,zeros(num_last_frames-size(lastn_bows,1),k_disp));
                else
                    lastn_bows = lastn_bows(end-num_last_frames+1:end,:);
                end
                
                % boost color display
                lastn_bows = lastn_bows.*10;
                image(lastn_bows');
                
                % display best clusters
                set(gca,'xtick',1:curr_frame)
                set(gca,'XTickLabel',num2str((max(curr_frame-num_last_frames+1,1):curr_frame)'))
                set(gca,'ytick',1:k_disp)
                set(gca,'YTickLabel',num2str(best_idx'))
                
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

%     end

%% process results
pdisp(repmat('-',1,60))
pdisp('Finished streaming:')
spmd% if 1
    pdisp([],'SetVerbose',true);
end

% get unified feature coreset
if options.GatherDescriptors
    
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
    try
        U1 = root_feature_coreset.getUnifiedCoreset();
        feature_core_points = double(U1.M.m);
        feature_weights = double(U1.W.m);
    catch
        U1=[];
        feature_core_points = [];
        feature_weights = [];
    end
    pdisp('Done!')
    
    % compute feature clustering
    pdisp('Computing feature clustering ...')
    %   here we compute descriptor representatives
    %   for k = 4000 we need a lot more frames
    %   descriptor representatives file contains this from previous runs
    %   use k1 = 10 as dummy example
    try
        k1 = 10;
        opt_weights = struct('weight',feature_weights);
        [feature_idx,feature_ctrs,feature_dists] = fkmeans(feature_core_points,k1,opt_weights);
    catch
    end
    pdisp('Done!')
end

% get unified semantic coreset
if options.GatherBagsOfWords
    pdisp('Computing unified semantic coreset ...')
    try
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
    catch
    end
    %         U2 = root_semantic_coreset.getUnifiedCoreset();
    %         semantic_core_points = double(U2.M.m);
    %         semantic_weights = double(U2.W.m);
    pdisp('Done!')
    
    % compute semantic clustering
    pdisp('Computing semantic clustering ...')
    %         k2 = params.NumSemanticClusters;
    %         opt_weights = struct('weight',semantic_weights);
    %     [semantic_idx,semantic_ctrs,semantic_dists] = fkmeans(semantic_core_points,k2,opt_weights);
    pdisp('Done!')
end
if (size(bow_leaf_buffer,2)>0)
    spmd_semantic_coreset.addPointSet(PointFunctionSet(Matrix(bow_leaf_buffer)));
    bow_leaf_buffer=[];
end

%% save data
pdisp('Saving data ...')
if options.Save
    %         for i = 1:numel(Composite)
    %             [savefile_path,savefile_name,savefile_ext] = fileparts(video_filename);
    %             save_name=['data/' savefile_name '_results.mat'];
    disp(save_name);
    spmd_feature_coreset1=[];
    if options.GatherDescriptors
        spmd_feature_coreset1=spmd_feature_coreset;
        
    end
    %             if options.GatherBagsOfWords
    %                 root_semantic_coreset
    %             end
    % TODO: add here what ever variables you want to save
    save(save_name,'spmd_feature_coreset1','bags_of_words','processed_frame_idx','feature_core_points','feature_weights','root_semantic_coreset');
    res.spmd_feature_coreset1=spmd_feature_coreset1;
    res.bags_of_words=bags_of_words;
    res.processed_frame_idx=processed_frame_idx;
    res.feature_core_points=feature_core_points;
    res.feature_weights=feature_weights;
    %         end
end
pdisp('Done!')

%% plot
if options.Plot
    
    if options.GatherDescriptors
        figure(110)
        try
            plot_kmeans(feature_core_points,k1,feature_idx,feature_ctrs,'title','feature coreset kmeans')
        catch
        end
    end
    
    if options.GatherBagsOfWords
        %     figure(210)
        %     plot_kmeans(semantic_core_points,k2,semantic_idx,semantic_ctrs,'title','semantic coreset kmeans')
    end
    %   catch
    %   end
    
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

%%
% profile off
% profile report
end
% end
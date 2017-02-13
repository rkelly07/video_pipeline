%% parallel classify
disp(repmat('=',1,80))
warning('off','vision:transition:usesOldCoordinates')

%% init parameters
params.NumRoundsL2 = 999;
params.NumVisualWordLabels = 10;
params

d2 = k;
k2 = params.NumVisualWordLabels;

%% init L2 coreset streams

% client stream
disp('Initializing L2 root coreset ...');
L2_root_coreset = Stream;
L2_root_coreset.leafSize = 1;
L2_root_coreset.coresetAlg = coreset_alg;
L2_root_coreset.coresetAlg.t = 1;
disp('Done!')

% disp('Initializing L2 coreset nodes ...');
% L2_coreset_nodes = cell(1,params.NumWorkers);
% parfor i = 1:params.NumWorkers
%   L2_coreset_nodes{i} = Stream;
%   L2_coreset_nodes{i}.leafSize = coreset_leaf_size;
%   L2_coreset_nodes{i}.coresetAlg = coreset_alg;
% end
% disp('Done!')

%% process data
knn_idx = cell(0);
visual_words = zeros(0,k);

curr_frame_offset = 0;

for round = 1:params.NumRoundsL2
  
  disp(repmat('- ',1,20))
  disp([' Round ' num2str(round) ' of ' num2str(params.NumRoundsL2) ':'])
  
  % get N frames at a time in parallel
  % compute knn for each frame's features to
  % the coreset kmeans centroids
  knn_idx = cat(1,knn_idx,cell(params.NumWorkers,1));
  nframes = cell(1,params.NumWorkers);
  nfeatures = cell(1,params.NumWorkers);
  
  % TODO: parfor
  parfor i = 1:params.NumWorkers
    [I,F] = vstream.par_get_next_frame(i);
    knn_idx{curr_frame_offset+i} = knnsearch(single(L1_ctrs),F);
    nframes{i} = I;
    nfeatures{i} = F;
  end
  % make sure to update data source
  vstream.update_par_get(params.NumWorkers,size(cell2mat(nfeatures(:)),1));
  
  visual_words = cat(1,visual_words,zeros(params.NumWorkers,k));
  parfor i = 1:params.NumWorkers
    visual_words(curr_frame_offset+i,:) = hist(knn_idx{curr_frame_offset+i},1:k);
  end
  visual_words_norm = visual_words./repmat(sum(visual_words,2),1,k);
  
  % add L2 vector 
  curr_frame_indices = curr_frame_offset+[1:params.NumWorkers];
  curr_L2_vector = visual_words_norm(curr_frame_indices,:);
  L2_root_coreset.addPointSet(PointFunctionSet(Matrix(curr_L2_vector)));

  % display last n frames
  num_last_frames = 100;
  vw_disp = visual_words_norm*255;
  if size(vw_disp,1) <= num_last_frames
    vw_disp = cat(1,vw_disp,zeros(num_last_frames-size(vw_disp,1),k));
  else
    vw_disp = vw_disp(end-num_last_frames+1:end,:);
  end  
  figure(400), subplot(211)
  image(vw_disp');
  
  % next n frames
  curr_frame_offset = curr_frame_offset+params.NumWorkers;
  
end

disp(repmat('- ',1,20))
disp('Done!')

%% process results
disp(repmat('-',1,60))
disp('Finished streaming:')
disp([' num visual words collected = ' num2str(size(visual_words,1))])

disp('Getting unified coreset ...')
U2 = L2_root_coreset.getUnifiedCoreset();
L2_core_points = U2.M.m;
L2_weights = U2.W.m;
disp([' coreset size = ' num2str(size(L2_core_points,1))])
disp('Done!')

%% calculate L2 labels
[L2_labels,L2_ctrs,L2_dist] = fkmeans(L2_core_points,k,struct('weight',L2_weights));
figure(210)
plot_kmeans(L2_core_points,k,L2_labels,L2_ctrs,'title','L2 coreset kmeans')


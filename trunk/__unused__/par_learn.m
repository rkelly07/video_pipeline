%% parallel learn
disp(repmat('=',1,80))
warning('off','vision:transition:usesOldCoordinates')

%% init parameters
params.Dimension = 64;
params.NumKMeans = 10;
params.NumWorkers = 12;
params.BlockSize = params.NumWorkers*100;
params.SliceSize = params.BlockSize/params.NumWorkers;
params.NumRoundsL1 = 200;

% SURF params
params.SURF_MetricThreshold = 200;
params.SURF_NumOctaves = 5;

params

d = params.Dimension;
k = params.NumKMeans;

%% init cluster
if matlabpool('size') == 0
  cluster = init_cluster('local')
else
  matlabpool updateattachedfiles
end

%% init video stream
disp(repmat('-',1,60))
disp('Initializing video stream ...')
VIDEO_FILENAME = 'data/test.mp4';
vstream = VideoStream(VIDEO_FILENAME);
vstream.Dimension = params.Dimension;
vstream.BlockSize = params.BlockSize;
vstream.MetricThreshold = params.SURF_MetricThreshold;
vstream.NumOctaves = params.SURF_NumOctaves;
disp('Done!')

%% coreset params
coreset_alg = KMedianCoresetAlg;
coreset_alg.k = params.NumKMeans;
coreset_alg.coresetType = KMedianCoresetAlg.linearInK;
coreset_alg.t = 50;

coreset_alg.bicriteriaAlg.robustAlg.beta = 10;
coreset_alg.bicriteriaAlg.robustAlg.partitionFraction = 1/2;
coreset_alg.bicriteriaAlg.robustAlg.costMethod = ClusterVector.maxDistanceCost;
coreset_alg.bicriteriaAlg.robustAlg.nIterations = 2;
coreset_alg.bicriteriaAlg.robustAlg.gamma = 1;

coreset_alg.bicriteriaAlg.robustAlg.figure.sample = false;
coreset_alg.bicriteriaAlg.robustAlg.figure.opt = false;
coreset_alg.bicriteriaAlg.robustAlg.figure.iteration = false;

coreset_leaf_size = 100;

%% init L1 coreset streams

% client stream
disp('Initializing L1 root coreset ...');
L1_root_coreset = Stream;
L1_root_coreset.leafSize = coreset_leaf_size;
L1_root_coreset.coresetAlg = coreset_alg;
disp('Done!')

% distributed streams:

% spmd stream
% disp('Initializing SPMD stream ...');
% spmd_stream = Composite(params.NumWorkers);
% spmd
%   spmd_stream = Stream;
%   spmd_stream.leafSize = coreset_leaf_size;
%   spmd_stream.coresetAlg = coreset_alg;
% end
% disp('Done!')

% parallel stream
disp('Initializing L1 coreset nodes ...');
L1_coreset_nodes = cell(1,params.NumWorkers);
parfor i = 1:params.NumWorkers
  L1_coreset_nodes{i} = Stream;
  L1_coreset_nodes{i}.leafSize = coreset_leaf_size;
  L1_coreset_nodes{i}.coresetAlg = coreset_alg;
end
disp('Done!')

%% process data
disp(repmat('-',1,60))
disp('Streaming ...')
wbar_str = ['Streaming ... ' sprintf('\n') '0 minutes and 0 seconds elapsed'];
wb = waitbar(0,wbar_str);

tic
round = 1;
while round < params.NumRoundsL1
  
  disp(repmat('- ',1,20))
  disp([' Round ' num2str(round) ' of ' num2str(params.NumRoundsL1) ':'])
  
  % get next block from video stream
  disp('Getting next block and slicing for workers ...')
  block = vstream.get_next_block();
  
  % split block into smaller slices for each worker
  slice = zeros([params.SliceSize d params.NumWorkers]);
  for i = 1:params.NumWorkers
    x1 = (i-1)*(params.BlockSize/params.NumWorkers)+1;
    x2 = i*(params.BlockSize/params.NumWorkers);
    slice(:,:,i) = block(x1:x2,:);
  end
  
  disp('Done!')
  
  % add point set
  disp('Adding L1 point sets ...')
  parfor i = 1:params.NumWorkers
    Xi = slice(:,:,i);
    s = L1_coreset_nodes{i};
    s.addPointSet(PointFunctionSet(Matrix(Xi)));
    L1_coreset_nodes{i} = s;
  end
  %   spmd
  %     curr_worker = mod(r-1,params.NumWorkers)+1;
  %     spmd_stream.addPointSet(PointFunctionSet(Matrix(S(:,:,labindex))));
  %   end
  
  %   parfor i = 1:params.NumWorkers
  %     [frames{i},features{i}] = vstream.par_get_next_frame(i);
  %     s = par_stream{i};
  %     Xi = features{i};
  %     s.addPointSet(PointFunctionSet(Matrix(Xi)));
  %     par_stream{i} = s;
  %   end
  %   vstream.update_par_get(params.NumWorkers,size(cell2mat(features(:)),1))
  
  disp('Done!')
  
  % next round
  round = round+1;
  
  % display progress
  f = round/params.NumRoundsL1;
  %f = vstream.CurrFrame/vstream.TotalFrames;
  t = toc;
  mins_str = sprintf('%2.0f',floor(t/60));
  secs_str = sprintf('%02.0f',rem(t,60));
  wbar_str = ['Streaming ... ' sprintf('\n') mins_str ' minutes and ' secs_str ' seconds elapsed'];
  waitbar(f,wb,wbar_str);
  
end

t = toc;
mins_str = sprintf('%2.0f',floor(t/60));
secs_str = sprintf('%02.0f',rem(t,60));
wbar_str = ['Done! ' sprintf('\n') mins_str ' minutes and ' secs_str ' seconds elapsed'];
waitbar(f,wb,wbar_str);
close(wb)
disp(repmat('- ',1,20))
disp('Done!')
disp([num2str(round) '/' num2str(params.NumRoundsL1) ' rounds completed'])
disp([num2str(vstream.CurrFrame) '/' num2str(vstream.TotalFrames) ' frames processed'])

%% process results
disp(repmat('-',1,60))
disp('Finished streaming:')
for i = 1:params.NumWorkers
  s = L1_coreset_nodes{i};
  disp([' worker ' num2str(i) ': num points streamed = ' num2str(s.numPointsStreamed)])
end

% get unified coreset
disp('Getting unified coreset ...')
for i = 1:params.NumWorkers
  s = L1_coreset_nodes{i};
  U1 = s.getUnifiedCoreset();
  disp([' adding point set from worker ' num2str(i)])
  L1_root_coreset.addPointSet(PointFunctionSet(Matrix(U1.M.m), Matrix(U1.W.m)));
end
U1 = L1_root_coreset.getUnifiedCoreset();
L1_core_points = U1.M.m;
L1_weights = U1.W.m;
disp('Done!')

%% calculate L1 labels
[L1_labels,L1_ctrs,L1_dist] = fkmeans(L1_core_points,k,struct('weight',L1_weights));
figure(110)
plot_kmeans(L1_core_points,k,L1_labels,L1_ctrs,'title','L1 coreset kmeans')


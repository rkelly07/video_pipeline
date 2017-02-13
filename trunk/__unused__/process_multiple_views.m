% vid1=VideoReader('../video1.ogv')
% vid2=VideoReader('../video2.ogv')

% online video processing pipeline
profile off, profile on
pdisp(repmat('=',1,80))

%% load persistent data
try
    if ~exist('descriptor_representatives','var')
        load descriptor_representatives_66 descriptor_representatives
        vq_preproc_mtx=eye(66);
        desc=66;
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
% TEST:
% video_filenames = repmat({'test.mp4'},1,length(video_filenames));
% video_filenames = repmat({'/media/My Passport/MyRecord/20130712/KANE0302_20130712122913.ogv'},1,length(video_filenames));
% video_filenames = repmat({'KANE0302_20130712122913.ogv'},1,length(video_filenames));
% video_filenames = repmat({'/media/My Passport/MyRecord/20130717/KANE0302_20130717051659.avi'},1,length(video_filenames));
params.FeatureDetector = 'SURF';
params.Dimension = 64;
params.NumFeatureClusters = size(descriptor_representatives,1);
params.NumSemanticClusters = 20;
params.NumWorkers = 2;
params.ResampleImageSize=[480 640];
params.StartFrame = 1;
params.L2DeltaThreshold = 0.1;
params.NumFrames = 5e5;
params.IIR_alpha=0.025;
params.IIR_buffer_length=1;
params.use_tracking=false;
params.use_caffe=false;
params.update_descriptors = true;
params

% for n_worker=1:params.NumWorkers:numel(video_filenames)
    clear options video_stream spmd_options;
    clear video_filenames2 fidx num_frames_processed;
    clear feature_coreset_alg semantic_coreset_alg;
    clear tracklet_params
% process options:
options.Plot                  = true;
options.Save                  = true;

options.GatherDescriptors     = false;
options.EstimateBlur          = false;
options.ComputeSuperpixels    = false;
options.ComputeObjectHeatMap  = false;

options.GatherBagsOfWords     = true;
options.GatherSemanticCues    = false;
options.ComputeCandidateBOWs  = false;
options.UpdateCandidateBOWs=false;
options
if options.UpdateCandidateBOWs
    updated_classifiers=classifiers;
end
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
feature_coreset_leaf_size = 50;

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
attached_files = cat(2,attached_files,dirrec(pwd,'.m'));
attached_files = cat(2,attached_files,dirrec('../../matlab_distributed_coreset','.m'));

% create cluster
cluster = init_cluster('local','restart','NumWorkers',params.NumWorkers, ...
    'AttachedFiles',attached_files);
    % spmd% if 1 params and options
            process_file('../video1.ogv',labindex,params,options,feature_coreset_alg,semantic_coreset_alg,coreset_params);
            process_file('../video2.ogv',labindex,params,options,feature_coreset_alg,semantic_coreset_alg,coreset_params);
% end


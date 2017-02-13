% online video processing pipeline
% myclear, close all, clc
profile off, profile on
disp(repmat('=',1,80))

%% load offline data
try
    if not(exist('descriptor_representatives','var'))
        load descriptor_representatives_66
        vq_preproc_mtx = eye(66);
        descriptor_dim = 66;
        VQs = single(descriptor_representatives(:,1:66));
    end
    if not(exist('classifiers','var'))
        load classifiers3.mat classifiers
    end
    if not(exist('regressors','var'))
        load classifiers3.mat regressors
    end
    if not(exist('blur_classifier','var'))
        blur_classifier = load('blur_classifier_net.mat','net');
    end
    if not(exist('dictionary','var'))
        load('learned_dictionary.mat','solution');
        dictionary = single(solution.D);
    end
    if not(exist('BOW_tform','var'))
        load BOW_tform_HOG.mat BOW_tform
    end
    
catch e
    warning(e.identifier,e.message)
end
try
offline_data.VQs = VQs;
offline_data.classifiers = classifiers;
offline_data.regressors = regressors;
offline_data.blur_classifier = blur_classifier;
offline_data.dictionary = dictionary;
catch
    offline_data.VQs = eye(66);
offline_data.classifiers = [];
offline_data.regressors = [];
offline_data.blur_classifier = [];
offline_data.dictionary = [];

end
clear VQs classifiers regressors blur_classifier dictionary

%% init params

params.DescriptorType = 'SURF';
params.DescriptorDim = descriptor_dim;
params.NumFeatureClusters = size(descriptor_representatives,1);
params.NumBOWClusters = 20;
params.NumWorkers = 2;
params.MaxFrames = 6e6;
params.rescale=[480 640];

% params.LinearTransform = eye(size(descriptor_representatives,1));
% params.LinearTransform = BOW_tform.T;
params.LinearTransform = [];
params.StartFrame = 1;
params.medfilt_size = 10;
params.L2DeltaThreshold = 0.00;
params.IIR_alpha = 0.05;
params.IIR_buffer_length = 1;
params.UseTracking = false;
params.UseCaffe = false;
params.UpdateDescriptors = true;
params.d_eps = 0.05;
params.Interlacing = false;
params.NumInterlacedSources = 4;
params.WebcamNo = 0;
if 1
    params.semantic_words=true;
    params.semantic_model=get_semantic_model(cfg,'rcnn');
else
    params.semantic_words=false;
end

params.skipframe=39;
params

feature_coreset_alg = KMedianCoresetAlg;
feature_coreset_alg.k = params.NumFeatureClusters;
feature_coreset_alg.t = 50;
feature_coreset_alg.coresetType = KMedianCoresetAlg.linearInK;
feature_coreset_alg.bicriteriaAlg.robustAlg.beta = 100;
feature_coreset_alg.bicriteriaAlg.robustAlg.partitionFraction = 1/2;
feature_coreset_alg.bicriteriaAlg.robustAlg.costMethod = ClusterVector.maxDistanceCost;
feature_coreset_alg.bicriteriaAlg.robustAlg.nIterations = 2;
feature_coreset_alg.bicriteriaAlg.robustAlg.gamma = 1;
feature_coreset_alg.bicriteriaAlg.robustAlg.figure.sample = false;
feature_coreset_alg.bicriteriaAlg.robustAlg.figure.opt = false;
feature_coreset_alg.bicriteriaAlg.robustAlg.figure.iteration = false;
feature_coreset_save_tree = false;
feature_coreset_leaf_size = 100;

k = 200;
a = 20*k;
b = 2;
c = 0.5;
w = 0.99;
VERBOSE = false;
bow_coreset_alg = KSegmentCoresetAlg();
bow_coreset_alg.a = a;
bow_coreset_alg.b = b;
bow_coreset_alg.c = c;
bow_coreset_alg.w = w;
bow_coreset_alg.verbose = VERBOSE;
bow_coreset_save_tree = true;
bow_coreset_leaf_size = 10;

coreset_params.FeatureCoresetLeafSize = feature_coreset_leaf_size;
coreset_params.FeatureCoresetAlgorithm = feature_coreset_alg;
coreset_params.FeatureCoresetSaveTree = feature_coreset_save_tree;
coreset_params.BOWCoresetLeafSize = bow_coreset_leaf_size;
coreset_params.BOWCoresetAlgorithm = bow_coreset_alg;
coreset_params.BOWCoresetSaveTree = bow_coreset_save_tree;


coreset_params

%% init options

options.Verbose = false;
options.GatherDescriptors = true;
% options.GatherDescriptors = false;
options.EstimateBlur = false;
options.ComputeSuperpixels = false;
options.ComputeObjectHeatMap = false;
% options.GatherBagsOfWords = true;
% options.SaveRawBagsOfWords = false;
options.GatherBagsOfWords = false;
options.SaveRawBagsOfWords = true;

options.GatherSemanticCues = false;
options.ComputeCandidateBOWs = false;
options.UpdateCandidateBOWs = false;

options.Save = true;
options.SaveResults = false;
options.SaveCoresetTree = true;


% options.Plot = true;
%  options.DrawKeyframeCollage = true;
%  options.DrawTree = true;
%  options.DrawKeyframeSelectionData = true;
% options.ShowSemanticWords=false;
options.Plot = false;
options.DrawKeyframeCollage = false;
options.DrawTree = false;
options.DrawKeyframeSelectionData = false;
options.ShowSemanticWords=true;
options.SaveSemanticWords=true;
% options.SaveSemanticWordsInDatabase=[];
options.SaveSemanticWordsInDatabase=struct('cfg',cfg);
options.Processor = 'mex';
% options.Processor = 'tcp';
% options.Host = '127.0.0.1';
% options.Port = 5568 ;

options

%% process video

% video_filenames = read_files_list('localfiles.txt');
% video_filenames={'/scratch/rosman/20150206_150927r.mp4','/scratch/rosman/20150205_155823r.mp4'};
% video_filenames={'/scratch/rosman/20150205_155823.mp4'};
% video_filenames={'/scratch/rosman/loop/GOPR0013.MP4'};
VIDEO_INPUT_DIR=[cfg.VIDEO_ANALYSIS_LIB, cfg.VIDEO_UPLOAD_PATH];
while(1)
    pause(10)
    files=dir(VIDEO_INPUT_DIR);
    if (isempty(files))
        continue;
    end
    video_filenames={};
    for i = 1:numel(files)
        if (strcmp(files(i).name,'.') ||strcmp(files(i).name,'..'))
            continue;
        end
    video_filenames{end+1}=[VIDEO_INPUT_DIR,files(i).name];
    end
try
% video_filenames = {'/data/vision/fisher/data1/Wearable/boston_glass_merged_gaps_5x.mp4'};

start_time = tic;
for file_no = 1:numel(video_filenames)
    
    video_filename = video_filenames{file_no};
    if (strcmpi(options.Processor,'tcp'))
        v = VideoStream(video_filename);
        num_frames = v.NumFrames;
    else
        num_frames = mex_video_processing('getframecount',video_filename);
    end

    % handle boundary case where we end up with 1-element coresets
    num_frames = min(num_frames,params.MaxFrames);
    if mod(num_frames,bow_coreset_leaf_size)==1
        num_frames = num_frames-1;
    end
    params.NumFrames = num_frames;
    disp(['num frames = ' num2str(num_frames)])
    
    % process video
    disp('running process video fn:')
    [results,coreset_tree_data] = process_video_fn(video_filename,file_no,offline_data,params,coreset_params,options);
    
    if options.Save
        save_prefix = 'Boston3_';
        save_suffix = ['_' num2str(num_frames) '_L' num2str(coreset_params.BOWCoresetLeafSize)];
        
        if options.SaveResults
            coreset_results_filename = [save_prefix 'coreset_results' num2str(file_no) save_suffix];
            disp(['Saving ' coreset_results_filename])
            save('-v7.3',['data/' coreset_results_filename],'results');
            disp('Done!')
            unix(['cp data/' coreset_results_filename '.mat ' cfg.CORESET_DATA_SAVE_PATH 'coreset_results.mat']);
        end
        
        if options.SaveCoresetTree
            coreset_tree_data_filename = [save_prefix 'coreset_tree_data' num2str(file_no) save_suffix];
            disp(['Saving ' coreset_tree_data_filename])
            save('-v7.3',['data/' coreset_tree_data_filename],'coreset_tree_data');
            disp('Done!')
            unix(['cp data/' coreset_tree_data_filename '.mat ' cfg.CORESET_DATA_SAVE_PATH 'coreset_tree_data.mat']);
        end
        
    end
 try
    delete(video_filename)
 catch
end
   
end

%%

disp(repmat('-',1,80))
disp(['Done: ' num2str(toc(start_time)/60) ' minutes elapsed'])

catch
end
end
% ------------------------------------------------
% reformatted with stylefix.py on 2014/09/15 12:41


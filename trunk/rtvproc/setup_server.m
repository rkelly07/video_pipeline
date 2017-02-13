
rtvproc_default_setup


%% load file list
disp(repmat('-',1,80))

% Users can add files directly or read from a local filelist e.g. using:
%   video_filelist = read_filelist('my_filelist.txt')
% The files can be specified using absolute or relative paths.

video_filelist = {'demo_video.avi'}; %TODO

video_filelist

%% load persistent data


disp(repmat('-',1,80))

load VQs/d10000

persistent_data.VQ = VQ;
persistent_data.VW = VW;

persistent_data

%% init params
%params.Source = 'Synthetic';
params.SyntheticNumFrames = 500;
params.SyntheticNumImages = 5;
params.SyntheticHeight = 300;
params.SyntheticWidth = 400;
params.SyntheticP = 0.1; %parameter for geometric random distribution for segment length

params.MaxFrames = inf;
params.StartFrame = 1;
params.EndFrame = [];
params.SkipFrames = 0;

params.RescaleSize = [];  %TODO: What to put here?
params.CoresetLeafSize = 40; %TODO: What to put here?

params.DescriptorType = 'SURF'; % SURF | SEMANTIC
params.SemanticModel = 'RCNN'; % RCNN |FAST-RCNN | LSDA | Places

%params.MedianFilterSize = 5;

params.ComputeCoresetTree = true;
params.CoresetSaveTree = true;

params.KxMetricWeights = [0.05 0.05 0.05];

params

%% init options
disp(repmat('-',1,80))

options.AuxFilepaths = ini2struct('server_paths.ini');

options.Plot = true;

options.SaveDetectionsToDB = false;
options.SaveCoresetDetectionsToDB = false;
options.SaveTextDetectionsToDB=false;
options.SaveResults = true;
options.SaveCoresetTree = true;

options

%% set init flag
disp(repmat('.',1,80))
% -----------------------------------------------------------------------------
%
% Script with default rtvproc setup.
% - Each user should create their own setup files e.g. my_setup.m
% - The user paths can be added in the user startup files.
% - We can use this script as a template for creating custom setup scripts 
%   without changing any of the actual source code.
% - The following considerations should be kept in mind:
%   1. We should always be able to run a quick demo by simply running 
%       process_video with no additional setup. If this does not work then 
%       there is a bug somewhere else in the code.
%   2. New setup parameters added to the rtvproc system should be initialized
%       with a default value here. An svn update to rtvproc_default_setup lets 
%       other users know that new functionality has been added to the system.
%
% -----------------------------------------------------------------------------
%% load file list
disp(repmat('-',1,80))

% Users can add files directly or read from a local filelist e.g. using:
%   video_filelist = read_filelist('my_filelist.txt')
% The files can be specified using absolute or relative paths.

video_filelist = read_filelist('my_filelist.txt');
% video_filelist = {'demo/test.mp4'};

video_filelist

%% load persistent data
disp(repmat('-',1,80))

% TODO:
% should be replaced with "load filename" after we standarsize variables:
% clean_VQ(VQ_filename);
% load(VQ_filename);

load demo/VQ

persistent_data.VQ = VQ;
persistent_data.VW = VW;

persistent_data

%% init params
disp(repmat('-',1,80))

params.Source = 'Video'; % Video | Webcam | HogD (HOG Descriptor) | Synthetic
params.WebcamNo = 0;

params.MaxFrames = 999999;
params.StartFrame = 1;
params.EndFrame = 200000;
params.SkipFrames = 0;

% TODO: rescale format:
% [frame_width(int) frame_height(int)]
% [width_frac(float) height_frac(float)]
% [-1 .] or [. -1] to maintain aspect ratio
params.RescaleSize = [];

params.DescriptorType = 'SURF'; % SURF | HSV | Semantic | HOG

params.SemanticModel = 'RCNN'; % RCNN | LSDA | Places

params.DisplayBufferSize = 100; 
params.DisplayNumBestBOW = 50;

params.LinearTransform = [];
params.MedianFilterSize = 10;
params.IIR_Alpha = 0.05;
params.IIR_Length = 1;
params.UpdateDescriptors = true;

params.CoresetLeafSize = 100;
params.CoresetAlgorithm = KSegmentCoresetAlg();
params.CoresetAlgorithm.a = 100;
params.CoresetAlgorithm.b = 2;
params.CoresetAlgorithm.c = 0.5;
params.CoresetAlgorithm.w = 0.99;
params.CoresetAlgorithm.verbose = false;
params.CoresetSaveTree = true;

params.ComputeCoresetTree = true;
params.KxMetricEnums.QUALITY     = 1;
params.KxMetricEnums.SEG_VOTES   = 2;
params.KxMetricEnums.SEG_TFRAC   = 3;
params.KxMetricWeights = [0.4 0.05 0.05];
params.KxBrightnessThreshold = 0.1;
params.KxSimilarityThreshold = 0;

%params for synthetic video. Please put the SYNTHETIC_DIR_PATH in .ini file
params.SyntheticNumFrames = 100;
params.SyntheticNumImages = 10;
params.SyntheticHeight = 300;
params.SyntheticWidth = 400;
params.SyntheticFPS = 30;
params.SyntheticP = 0.1; %parameter p for geornd segment length
params.SyntheticNumObjects = 4;

%% init options
disp(repmat('-',1,80))

options.AuxFilepaths = ini2struct('my_paths.ini');

options.DB_Config.server = 'localhost';
options.DB_Config.instance = 'postgres';
options.DB_Config.username = 'postgres';
options.DB_Config.password = '?D8yr5^5';
options.DB_Config.db_name = 'postgres';
options.SaveDetectionsToDB = false;
options.SaveCoresetDetectionsToDB = false;

options.Plot = true;
options.FigureID = 100;
options.DefaultFigPos = [80 280 1480 800];

options.PlotFrames = true;
options.PlotBOW = true;
options.PlotKeyframes = true;
options.PlotTree = true;
options.PlotKeyframeMetrics = true;

options.SaveResults = true;
options.SaveCoresetTree = true;
options.SaveTextDetectionsToDB=false;

options.Verbose = true;

options

%% finished
disp(repmat('.',1,80))

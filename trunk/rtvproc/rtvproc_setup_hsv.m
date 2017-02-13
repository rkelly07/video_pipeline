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

% video_filelist = read_filelist('my_filelist.txt')
video_filelist = {'/home/rosman/dwhelper/OKGoTheWritingsOntheWallOfficialVideo.mp4'};

video_filelist

%% load persistent data
disp(repmat('-',1,80))

% this should be replaced with 'load filename'
% after we standarsize the variable names
% [VQ,VW] = load_VQ(VQ_filename);
% if necessary can use
% clean_VQ(VQ_filename);

load demo/VQ
VQ=[];
VW=[];
N_VQ=500;
persistent_data.VQ = [];%single(randn(N_VQ,2));
persistent_data.VW = [];%single(randn(N_VQ,1));

persistent_data

%% init params
disp(repmat('-',1,80))

params.MaxFrames = 999999;
params.StartFrame = 1;
params.SkipFrames = 0;
params.MaxKeyframes = 9;

params.DescriptorType = 'HSV';


params.ComputeCoresetTree = true;
params.KxMetricEnum.QUALITY     = 1;
params.KxMetricEnum.SEG_VOTES   = 2;
params.KxMetricEnum.SEG_TFRAC   = 3;
params.KxMetricWeights = [0.4 0.05 0.05];
params.KxSimilarityThreshold = 0;

params.ComputeSemanticWords = false;
params.SemanticWordsSkipFrames = 5;

params.RescaleSize = [];
params.LinearTransform = [];
params.MedianFilterSize = 10;
params.L2DeltaThreshold = 0;
params.IIR_Alpha = 0.05;
params.IIR_BufferLength = 1;
params.UpdateDescriptors = true;
params.WebcamNo = 0;

params.CoresetAlgorithm = KSegmentCoresetAlg();
params.CoresetAlgorithm.a = 2000;
params.CoresetAlgorithm.b = 2;
params.CoresetAlgorithm.c = 0.5;
params.CoresetAlgorithm.w = 0.99;
params.CoresetAlgorithm.verbose = false;
params.CoresetLeafSize = 20;
params.CoresetSaveTree = true;
params.color_desc_representatives=rand(N_VQ,2);

params.VQ_Dim = N_VQ;
params.DescriptorDim = 2;

params

%% init options
disp(repmat('-',1,80))

options.AuxFilepaths = ini2struct('my_paths.ini');

options.DB_Config.server = 'localhost';
options.DB_Config.instance = 'postgres';
options.DB_Config.username = 'serverdemo';
options.DB_Config.password = 'ajecag1k3';
options.DB_Config.db_name = 'postgres';

options.Plot = true;
options.PlotFrames = true;
options.PlotBOW = true;
options.PlotSemanticWords = false;
options.PlotKeyframes = true;
options.PlotTree = true;
options.PlotKeyframeMetrics = true;
options.FigureID = 100;

options.SaveSemanticWords = false;
options.SaveResults = true;
options.SaveCoresetTree = true;

options

%% set init flag
disp(repmat('.',1,80))

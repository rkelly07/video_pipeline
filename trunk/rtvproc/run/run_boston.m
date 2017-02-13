rtvproc_default_setup
clc

%% load file list
disp(repmat('-',1,80))

% Users can add files directly or read from a local filelist e.g. using:
%   video_filelist = read_filelist('my_filelist.txt')
% The files can be specified using absolute or relative paths.

% video_filelist = {'BostonTour3_720p.mp4'};
video_filelist = {'BostonTour3_30x_720p.mp4'};

video_filelist

%% load persistent data
disp(repmat('-',1,80))

% load boston/d10000
load VQ_BostonTour3_30x_720p_08201735.mat

persistent_data.VQ = VQ;
persistent_data.VW = VW;

persistent_data

%% init params
disp(repmat('-',1,80))

params.StartFrame = 1;
% params.SkipFrames = 5;
% params.EndFrame = 356491;
params.EndFrame = 11880

% params.RescaleSize = [480 -1];
params.CoresetLeafSize = 120;

params.KxMetricWeights = [0 0.05 0.05];

params

%% init options
disp(repmat('-',1,80))

options.Plot = true;
options.SaveResults = true;
options.Verbose = false;

options

%% run process video 
disp(repmat('.',1,80))

process_video


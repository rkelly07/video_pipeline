rtvproc_default_setup
clc

%% load file list
disp(repmat('-',1,80))

% Users can add files directly or read from a local filelist e.g. using:
%   video_filelist = read_filelist('my_filelist.txt')
% The files can be specified using absolute or relative paths.

video_filelist = {'Birdman.2014.1080p.BluRay.x264.YIFY.mp4'};
% video_filelist = {'Birdman_20x.mp4'};

video_filelist

%% load persistent data
disp(repmat('-',1,80))

load birdman/d10000

persistent_data.VQ = VQ;
persistent_data.VW = VW;

persistent_data

%% init params
disp(repmat('-',1,80))

params.StartFrame = 2620;
params.SkipFrames = 24;
params.EndFrame = 155000;
%162595;

% params.StartFrame = 274;
% params.EndFrame = 8000;
% params.SkipFrames = 23;

params.RescaleSize = [480 -1];
params.CoresetLeafSize = 100;

params.KxMetricWeights = [0 0.05 0.05];

params

%% init options
disp(repmat('-',1,80))

options.Plot = true;
options.SaveResults = false;
options.Verbose = false;

options

%% run process video 
disp(repmat('.',1,80))

process_video


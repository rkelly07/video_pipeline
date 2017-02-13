rtvproc_default_setup
clc

%% load file list
disp(repmat('-',1,80))

% Users can add files directly or read from a local filelist e.g. using:
%   video_filelist = read_filelist('my_filelist.txt')
% The files can be specified using absolute or relative paths.

video_filelist = {'ladybird_cropped.mp4'};

video_filelist

%% load persistent data
disp(repmat('-',1,80))

load stata/d5000

persistent_data.VQ = VQ;
persistent_data.VW = VW;

persistent_data

%% init params
disp(repmat('-',1,80))

params.StartFrame = 1;
params.EndFrame = 2800;
params.SkipFrames = 0;

params.RescaleSize = [];
params.CoresetLeafSize = 250;

params.KxMetricWeights = [0.4 0.05 0.05];

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


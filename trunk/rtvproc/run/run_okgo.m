rtvproc_default_setup
clc

%% load file list
disp(repmat('-',1,80))

% Users can add files directly or read from a local filelist e.g. using:
%   video_filelist = read_filelist('my_filelist.txt')
% The files can be specified using absolute or relative paths.

video_filelist = {'OK.Go.The.Writing.s.On.the.Wall.mp4'};

video_filelist

%% load persistent data
disp(repmat('-',1,80))

persistent_data.VQ = [];
persistent_data.VW = [];

persistent_data

%% init params
disp(repmat('-',1,80))

params.KxMetricWeights = [0 0.05 0.05];

params.DescriptorType = 'HSV';
params.ColorDescRepresentatives = rand(500,2);

params.CoresetLeafSize = 50;
params.SkipFrames = 9;
params.EndFrame = 6000;

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


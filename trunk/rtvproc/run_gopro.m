rtvproc_default_setup
clc

%% load file list
disp(repmat('-',1,80))

% Users can add files directly or read from a local filelist e.g. using:
%   video_filelist = read_filelist('my_filelist.txt')
% The files can be specified using absolute or relative paths.

video_filelist = {'videos/gopro_video.mp4'};

video_filelist

%% load persistent data
disp(repmat('-',1,80))

load VQs/d10000

persistent_data.VQ = VQ;
persistent_data.VW = VW;

persistent_data

%% init params
disp(repmat('-',1,80))

params.MaxFrames = inf;
params.StartFrame = 1;
params.EndFrame = [];
params.SkipFrames = 0;

params.CoresetLeafSize = 100;

params

%% init options
disp(repmat('-',1,80))

options.AuxFilepaths = ini2struct('server_paths.ini');

options.Plot = true;

options.SaveDetectionsToDB = false;
options.SaveResults = true;
options.SaveCoresetTree = true;
options

%% set init flag
disp(repmat('.',1,80))


process_video
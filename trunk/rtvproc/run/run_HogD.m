rtvproc_default_setup
clc

%% load file list
disp(repmat('-',1,80))

% Users can add files directly or read from a local filelist e.g. using:
%   video_filelist = read_filelist('my_filelist.txt')
% The files can be specified using absolute or relative paths.
params.Source = 'HOGD';
params.DescriptorType = 'HOG'; % SURF | HSV | Semantic | HOG
params.EndFrame = 200;
params.CoresetLeafSize = 100;
params.CoresetAlgorithm.a = 100;
params.CoresetAlgorithm.b = 2;
params.CoresetAlgorithm.c = 0.5;
params.CoresetAlgorithm.w = 0.99;
video_filelist = {'/scratch/relax/descriptor/Features.gz'};
options.PlotFrames = false;
options.PlotKeyframes = false;
options.PlotTree = true;
options.PlotKeyframeMetrics = false;

process_video

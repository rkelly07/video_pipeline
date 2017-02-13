rtvproc_default_setup
clc

%% load file list
disp(repmat('-',1,80))

% Users can add files directly or read from a local filelist e.g. using:
%   video_filelist = read_filelist('my_filelist.txt')
% The files can be specified using absolute or relative paths.

video_filelist = {'BostonTour3_5x.mp4'};

video_filelist

%% load persistent data
disp(repmat('-',1,80))

load boston/d10000

persistent_data.VQ = VQ;
persistent_data.VW = VW;

persistent_data

%% init params
disp(repmat('-',1,80))

params.RescaleSize = [640 346]; 
params.CoresetLeafSize = 100;

params

%% init options
disp(repmat('-',1,80))

options.Plot = true;

options

%% set init flag
disp(repmat('.',1,80))

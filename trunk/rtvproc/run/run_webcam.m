rtvproc_default_setup
clc

%% load file list
disp(repmat('-',1,80))

% Users can add files directly or read from a local filelist e.g. using:
%   video_filelist = read_filelist('my_filelist.txt')
% The files can be specified using absolute or relative paths.

% video_filelist = read_filelist('my_filelist.txt')
% video_filelist = {'demo/test.mp4'};
video_filelist = {''};

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

params.Source = 'Webcam'; % Video | Webcam
params.WebcamNo = 0;
params.CoresetLeafSize = 50;

params

%% init options
disp(repmat('-',1,80))

options

%% run process video 
disp(repmat('.',1,80))

process_video
myclear, close all, clc

%% run coreset tree GUI
coreset_tree_gui


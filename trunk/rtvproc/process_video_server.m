%%first load the default setup file
myclear
rtvproc_default_setup
clc

%save detections
options.SaveDetectionsToDB = true;
options.Plot = false;
params.ComputeCoresetTree = false;

%add server paths
options.AuxFilepaths = ini2struct('server_paths.ini');

%% run process video 
disp(repmat('.',1,80))

process_video
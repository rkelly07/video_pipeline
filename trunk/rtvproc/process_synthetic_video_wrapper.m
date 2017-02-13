function process_synthetic_video_wrapper()
%PROCESS_SYNTHETIC_VIDEO_WRAPPER Summary of this function goes here
%   Detailed explanation goes here

    % need a variable SYNTHETIC_DIR_PATH in my_paths.ini to create a
    % synthetic video in that directory

    setup_server
    
    params.Source = 'Synthetic';
    params.SyntheticNumFrames = 100;
    params.SyntheticNumImages = 5;
    params.SyntheticHeight = 300;
    params.SyntheticWidth = 400;
    params.SyntheticP = 0.1; %parameter for geometric random distribution for segment length
    params.CoresetLeafSize = 30;
    
    options.Plot = true;
    options.SaveResults = false;
    options.SaveCoresetTree = false;
    
    process_video
end


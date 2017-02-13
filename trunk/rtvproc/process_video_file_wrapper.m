function process_video_file_wrapper( video_file_paths )
%PROCESS_VIDEO_FILE_WRAPPER Runs the video process pipeline on this file
%   Runs the default video setup, and put given file into the setup 

    %log time for these video file_paths
    process_start = tic;
    filepath = '';
    just_filename = '';
    setup_server
    
    video_filelist = video_file_paths;
    if (length(video_filelist) == 1)
        filepath = video_filelist{1};
    end
    video_filelist
    
    process_video
    
    %now make simpler coreset and do detections
    process_video_after_coreset_creation(filepath, coreset_tree.Filepath, coreset_results.Filepath);
    
    
    %Log total process_video time
    process_time = toc(process_start);
    [pathstr,name,ext] = fileparts(filepath);
    just_filename = [name ext];
    line_to_log = ['\n' just_filename ', entire_process_n_detections, ' '' ', ' int2str(process_start) ', ' int2str(process_start+process_time) ', ' int2str(process_time)];
    log_to_file(options.AuxFilepaths.MATLAB_LOG_FILE, line_to_log); 
    
    %cleanups
    clearvars
end


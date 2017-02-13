function process_video_after_coreset_creation( video_filepath, coreset_tree_filepath, coreset_results_filepath )
%PROCESS_VIDEO_AFTER_CORESET_CREATION Summary of this function goes here
%   Detailed explanation goes here

    disp('Starting detections using coreset');
    simple_coreset_start = tic;
    [simple_coreset_path, coreset_tree, coreset_results] = create_simpler_coreset_tree(coreset_tree_filepath, coreset_results_filepath);
    coreset.coreset_tree_path = fullpath(coreset_tree_filepath);
    coreset.coreset_results_path = fullpath(coreset_results_filepath);
    coreset.simple_coreset_path = simple_coreset_path;
    simple_coreset_time = toc(simple_coreset_start);

    %first save the coreset paths to DB
    
    det_start = tic;
    

    
    save_coreset_detections( video_filepath, coreset, coreset_tree, coreset_results)
    
    
    det_time = toc(det_start);
    
    % Log the simpler coreset creation time and the entire coreset detections time taken
    
    [pathstr,name,ext] = fileparts(video_filepath);
    just_filename = [name ext];
    
    if ~exist('options', 'var')
        init_save_detections;
    end
    
    
    line_to_log = ['\n' just_filename ', simple_coreset_creation, ' '' ', ' int2str(simple_coreset_start) ', ' int2str(simple_coreset_start+simple_coreset_time) ', ' int2str(simple_coreset_time)];
    log_to_file(options.AuxFilepaths.MATLAB_LOG_FILE, line_to_log);  
    
    line_to_log = ['\n' just_filename ', coreset_detections, ' '' ', ' int2str(det_start) ', ' int2str(det_start+det_time) ', ' int2str(det_time)];
    log_to_file(options.AuxFilepaths.MATLAB_LOG_FILE, line_to_log); 
end


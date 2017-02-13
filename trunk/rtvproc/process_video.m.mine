% -----------------------------------------------------------------------------
% Main script to run the rtvproc system
%
% > [my_setup.m]:
%   - load file list            => cell:   video_filelist
%   - load persistent data      => struct: persistent_data
%   - init params               => struct: params
%   - init options              => struct: options
%
% > process_video.m:
%   - assert setup variables to check setup:
%     otherwise run default setup
%       > rtvproc_default_setup.m
%   - [coreset_results, coreset_tree] = process_video_fn(...)
% 	- save coreset_results
% 	- save coreset tree
%
% -----------------------------------------------------------------------------


echo off
diary off
profile off
disp(repmat('=',1,80))

% save breakpoints
S = dbstatus;
save dbstatus S

% clear everything except setup variables
% this ensures that we do not add any bloat that is outside of specifications
clearvars -except video_filelist persistent_data params options process_start

% restore breakpoints
load dbstatus S
dbstop(S)
delete dbstatus.mat
clear S

profile on

%% setup

% setup variables should be set in user setup script
try
    
    assert(exist('video_filelist','var')==true)
    assert(exist('persistent_data','var')==true)
    assert(exist('params','var')==true)
    assert(exist('options','var')==true)
    
catch e
    
    warning(e.identifier,'Setup variables not loaded. Running default setup')
    
    % if not initialized, we run the default setup script:
    % this is a standard setup that we know will work and
    % can always be run for a demo.
    % rtvproc_default_setup should not be modified normally
    rtvproc_default_setup
    
end

%% process video

switch upper(params.Source)
    case 'VIDEO'
        if isempty(video_filelist) || any(cellfun(@isempty,video_filelist))
            warning('No video files specified: reading from webcam')
            params.UseWebcam = true;
        end
    case 'WEBCAM'
        if not(isempty(video_filelist))
            warning('Webcam source specified: ignoring video files')
            video_filelist = {''};
        end 
    case 'HOGD'
        if isempty(video_filelist)
    		error('No HOG descriptors found here!');
        end
    case 'SYNTHETIC'
              
    otherwise
        error('Invalid source type!')   
end

start_time = tic;
for file_no = 1:numel(video_filelist)  
    
    % get video info
    if strcmp(params.Source , 'HOGD')
        filepath = fullpath(video_filelist{file_no});
        gunzip(filepath);
        filepath = [filepath(1:end-3)];
        filename = filepath(max(strfind(filepath,filesep))+1:end);
        video_info.Filename = filename;
        [f,message]=fopen(filepath, 'rb')
        if f==-1
            error('No HOG descriptors found here!')  
        end
        A = fread(f, 4, 'uint32');
        video_info.NumFrames = A(1);
        video_info.Width = A(2);
        video_info.Height = A(3);
        video_info.Duration = A(4)/1000;
        video_info.FPS = A(1)/video_info.Duration;
    %	fseek(f, 12, 'bof');
    %	A = fread(f, 1, 'float');
    %	video_info.FPS = A(1);
    %	video_info.Duration = video_info.NumFrames / video_info.FPS;
        fclose(f)
        
    elseif strcmp(params.Source , 'Synthetic')
        dirpath = options.AuxFilepaths.SYNTHETIC_DIR_PATH;
        filename = ['synthetic_video_' int2str(params.SyntheticNumFrames) '_' datestr(now,'dd-mm-yyyy_HH:MM:SS.avi')];
        filepath = fullfile(dirpath, filename);
        synthetic_info = create_images_and_descriptors( params.SyntheticNumImages, params.SyntheticHeight, params.SyntheticWidth );
        video_info.Filename = filename;
	    video_info.Duration = NaN;
	    video_info.NumFrames = params.SyntheticNumFrames;
	    video_info.Width = params.SyntheticWidth;
	    video_info.Height = params.SyntheticHeight;
	    video_info.FPS = params.SyntheticFPS;
        video_info.SyntheticInfo = synthetic_info;
    else
        filepath = fullpath(video_filelist{file_no});
   	    filename = filepath(max(strfind(filepath,filesep))+1:end);
	    mex_video_info = mex_video_processing('getinfo',filepath,params.WebcamNo);
	    video_info.Filename = filename;
	    video_info.Duration = mex_video_info(1)/ mex_video_info(4);
	    video_info.NumFrames = mex_video_info(1);
	    video_info.Width = mex_video_info(2);
	    video_info.Height = mex_video_info(3);
	    video_info.FPS = mex_video_info(4);
    end	    
    	video_info
    % update file specific params
    params.SourceNo = file_no;
    params.VideoInfo = video_info;
    
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    % main process video function
    
    [coreset_results,coreset_tree] = process_video_fn(filepath,persistent_data,params,options);
    
    %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    save_dir = 'results';
    save_prefix = [filename(1:min(strfind(filename,'.'))-1) '_'];
    save_suffix = [...
        '_' num2str(coreset_results.NumSpannedFrames) ...
        '_' num2str(params.CoresetLeafSize) ...
        '_' datestr(now,'mmddHHMMSS')];
    
    disp(repmat('-',1,80))
    coreset_results
    
    if options.SaveResults || options.SaveCoresetDetectionsToDB
        coreset_results_filename = [save_prefix 'coreset_results' save_suffix '.mat'];
        disp(['Saving ' coreset_results_filename])
        coreset_results_filepath = [save_dir,filesep,coreset_results_filename];
        save('-v7.3',coreset_results_filepath,'coreset_results');
        if exist('coreset_results.mat','file')
            delete('coreset_results.mat')
        end
        coreset_results.Filepath = coreset_results_filepath;
        %had to add try for copy because for some weird reason, copyfile
        %isn't working when RTVideoProcessing library is preloaded
        try
            copyfile(fullpath(coreset_results_filepath),'coreset_results.mat')
        catch e
            warning(e.identifier, 'Error copying coreset_results.mat');
        end
        disp('Done!')
    end
    
    disp(repmat('-',1,80))
    coreset_tree
    
    if options.SaveCoresetTree || options.SaveCoresetDetectionsToDB
        coreset_tree_filename = [save_prefix 'coreset_tree' save_suffix '.mat'];
        disp(['Saving ' coreset_tree_filename])
        coreset_tree_filepath = [save_dir,filesep,coreset_tree_filename];
        save('-v7.3',coreset_tree_filepath,'coreset_tree');
        if exist('coreset_tree.mat','file')
            delete('coreset_tree.mat')
        end
        coreset_tree.Filepath = coreset_tree_filepath;
        try
            copyfile(fullpath(coreset_tree_filepath),'coreset_tree.mat')
        catch e
            warning(e.identifier, 'Error copying coreset_tree.mat');
        end
        disp('Done!')
    end
    
    
    [pathstr,name,ext] = fileparts(filepath);
    just_filename = [name ext];
    
    
    process_vid_time = toc(start_time);
    disp(repmat('.',1,80))
    disp(['Done with coreset creation for file ' just_filename ' : ' num2str(process_vid_time/60) ' minutes elapsed']);

    %log the time for processing before detection
    line_to_log = ['\n' just_filename ', vid_process_before_detec, ' '' ', ' int2str(start_time) ', ' int2str(start_time+process_vid_time) ', ' int2str(process_vid_time)];
    log_to_file(options.AuxFilepaths.MATLAB_LOG_FILE, line_to_log);
    

end

%%
disp(repmat('.',1,80))
disp(['Done: ' num2str(toc(start_time)/60) ' minutes elapsed'])

% clean up
clearvars -except coreset_results coreset_tree video_filelist persistent_data params options process_start filepath

% ------------------------------------------------
% reformatted with stylefix.py on 2015/03/11 22:32

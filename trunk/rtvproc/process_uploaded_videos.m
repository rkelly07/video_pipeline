paths = ini2struct('server_paths.ini');

VIDEO_UPLOAD_DIR=[paths.VIDEO_ANALYSIS_LIB paths.VIDEO_UPLOAD_PATH];
%PROCESSED_VIDEOS_DIR=[cfg.VIDEO_ANALYSIS_LIB cfg.PROCESSED_VIDEOS_PATH];
detector = 'rcnn'; %could be 'rcnn' or 'lsda'

processed_files = {};
 
while (1)
    disp('Scanning upload directory for uploaded files...');
    cd([paths.VIDEO_ANALYSIS_LIB 'rtvproc/']);
    pause(5);

    files=dir(VIDEO_UPLOAD_DIR);

    for i = 1:numel(files)
        if (strcmp(files(i).name,'.') ||strcmp(files(i).name,'..') ||strcmp(files(i).name,'.svn'))
            continue;
        end
        filepath = [VIDEO_UPLOAD_DIR files(i).name];
        
        %discard files that are already processed
        if any(ismember(processed_files, filepath))
            continue;
        end
        
        try
            disp(['Processing the file ' filepath '...']);
            process_video_file_wrapper({filepath});
        catch e
            warning(e.identifier, ['Could not process file ' files(i).name '. Trying to redo..']);
            continue;
        end

        %delete the file if process completed successfully
        %delete(filepath);
        
        %because currently copyfile isn't working, we don't delete the file
        %but note that it has been processed
        processed_files{end+1} = filepath;
    end
        
end
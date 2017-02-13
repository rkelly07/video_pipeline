function save_coreset_detections( video_filepath, coreset, coreset_tree, coreset_results, options, params )
%RUN_DETECTION Runs object detection on the leaves' keyframes given tree
%   First step for objects retrieval -- detection of the selected frames
%   from the coreset tree. Usually, we run detections on all the leaves of
%   the tree

    
    %% unpack persistent data
    if ~exist('descriptor_dim', 'var') || ~exist('rescale_size', 'var') || ~exist('options', 'var') || ~exist('params', 'var')
        init_save_detections;
    end
    
    if strcmp(params.Source, 'Synthetic')
        save_synthetic_detections(video_filepath, coreset, options, params);
        return;
    end
    
    coreset_tree_path = coreset.coreset_tree_path;
    
    if ~exist('coreset_tree', 'var')
        disp('loading coreset tree');
        load(coreset_tree_path);
    end
    
    video_filepath = fullpath(video_filepath);
    
    [pathstr,name,ext] = fileparts(video_filepath);
    filename = [name ext];
    %% get video info
    video_info = get_video_info(video_filepath, params);
    params.VideoInfo = video_info;
    
    
    %% first add scene and coresets to database
    db = observations_db(options.DB_Config);
    db.open_db();
    db_stream_id = save_scene(db, video_filepath, params);
    db.add_coreset(db_stream_id, coreset)
    
    %% save text detections for coreset
    if options.SaveTextDetectionsToDB
        disp('Starting text detections and saving to DB..');
        py.updateTextInfo2DB.updateTextInfo2DB(video_filepath, coreset.simple_coreset_path);
        disp('Text detections done.');
    end
    %% Save detections for coresets
    %TODO: Log time to get semantic model
    semantic_model = get_semantic_model(params.SemanticModel,options.AuxFilepaths);
    semantic_state = [];

    
    
    if ~isempty(semantic_model)   
        
        % init mex video processing
        h = mex_video_processing('init',video_filepath,params.DescriptorType,VQ,descriptor_dim,params.WebcamNo,rescale_size);
        for i_node=1:coreset_tree.NumNodes
            node = coreset_tree.Data{i_node};
            node_type = node.NodeType;

            if (strcmpi(node_type, 'LEAF'))
                %Log total detection time for this leaf
                leaf_det_start = tic;
                frame_id_array = node.KeyframeAbsIdx;
                disp(['Saving detections from the leaf node ' int2str(i_node)]);
                disp(['Keyframes are ' mat2str(frame_id_array)]);
                for i_frame = 1:numel(frame_id_array)
                    %Log total detection time for this frame
                    frame_det_start = tic;
                    frame_id = frame_id_array(i_frame);
                    disp(['Keyframes for the node ' int2str(i_node) ' are ' mat2str(frame_id_array)]);
                    disp(['Doing detection on the keyframe ' int2str(frame_id)]); 
                    mex_video_processing('setframe',h,frame_id);
                    [B,I,~] = mex_video_processing('newframe',h);

                    [B_sem,semantic_state,semantic_detections] = get_semantic_words_vector(I,semantic_model,semantic_state);
                    
                    frame_det_time = toc(frame_det_start);
                    line_to_log = ['\n' filename ', frame_detections, ' 'keyframe_num ' int2str(frame_id) ', ' int2str(frame_det_start) ', ' int2str(frame_det_start+frame_det_time) ', ' int2str(frame_det_time)];
                    log_to_file(options.AuxFilepaths.MATLAB_LOG_FILE, line_to_log); 
                    if ~isempty(semantic_detections)
                        %Log the time needed to add a frame's
                        %detections to db
                        db_frame_start = tic;
                        disp('Adding detections to the database');
                        db.add_detections_from_frame(semantic_detections,db_stream_id,frame_id);
                        db_frame_time = toc(db_frame_start);
                        line_to_log = ['\n' filename ', frame_db_insert, keyframe_num ' int2str(frame_id) ', ' int2str(db_frame_start) ', ' int2str(db_frame_start+db_frame_time) ', ' int2str(db_frame_time)];
                        log_to_file(options.AuxFilepaths.MATLAB_LOG_FILE, line_to_log); 
                    end

                end
                leaf_det_time = toc(leaf_det_start);
                line_to_log = ['\n' filename ', leaf_detect_n_db, ' 'node_num ' int2str(i_node) ', ' int2str(leaf_det_start) ', ' int2str(leaf_det_start+leaf_det_time) ', ' int2str(leaf_det_time)];
                log_to_file(options.AuxFilepaths.MATLAB_LOG_FILE, line_to_log); 
            end


        end
    else
        error('Error in getting the semantic model!');
    end


end

function im = resize_image(im)
  imsz = size(im);
  % resize so that the image is 300 pixels per inch
  % and 1.2 inches tall
  scale = 1.2 / (imsz(1)/300);
  im = imresize(im, scale, 'method', 'cubic');
end

function [db_stream_id] = save_scene(db, filepath, params)
    db_stream.path = filepath;
    db_stream.timestamp = datestr(now);
    db_stream.width = params.VideoInfo.Width;
    db_stream.height = params.VideoInfo.Height;
    db_stream.frame_rate = params.VideoInfo.FPS;

    db_stream_id = {filepath, db_stream.timestamp};
    db_stream.frames = params.VideoInfo.NumFrames;
    db.add_scene(db_stream);
end


function video_info = get_video_info(video_file_path, params)
    filepath = fullpath(video_file_path);
    filename = filepath(max(strfind(filepath,filesep))+1:end);
    
    %get the coreset tree info (later on from the database)
    
    % get video info
    mex_video_info = mex_video_processing('getinfo',filepath,params.WebcamNo);
    video_info.Filename = filename;
    video_info.Duration = mex_video_info(1)/ mex_video_info(4);
    video_info.NumFrames = mex_video_info(1);
    video_info.Width = mex_video_info(2);
    video_info.Height = mex_video_info(3);
    video_info.FPS = mex_video_info(4);
    video_info
    
    
end
            

        
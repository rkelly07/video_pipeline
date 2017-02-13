function [ output_args ] = save_synthetic_detections( video_filepath, coreset, options, params )
%SAVE_SYNTHETIC_DETECTIONS Summary of this function goes here
%   Detailed explanation goes here

    
    %% unpack persistent data
    if ~exist('descriptor_dim', 'var') || ~exist('rescale_size', 'var') || ~exist('options', 'var') || ~exist('params', 'var')
        init_save_detections;
    end
    
    disp('Saving detections for synthetic');
    simple_path = coreset.simple_coreset_path;
    
    if ~exist('simple_coreset', 'var')
        load(simple_path);
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
    

    %% Save detections for coresets

    for i_node=1:simple_coreset.NumNodes
        node = simple_coreset.Nodes(i_node);
        node_type = node.NodeType;

        if (strcmpi(node_type, 'LEAF'))
            %Log total detection time for this leaf
            leaf_det_start = tic;
            disp(['Saving detections from the leaf node ' int2str(i_node)]);
            %create synthetic detections
            synthetic_detections = create_synthetic_detections(node, params);
            db.add_synthetic_detections(synthetic_detections,db_stream_id);
        end

    end
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

    video_info.Filename = filename;
    video_info.Duration = NaN;
    video_info.NumFrames = params.SyntheticNumFrames;
    video_info.Width = params.SyntheticWidth;
    video_info.Height = params.SyntheticHeight;
    video_info.FPS = params.SyntheticFPS;
    video_info

end


function [detections] = create_synthetic_detections(node, params)
    keyFrames = node.KeyFrames;
    importance_array = node.Importance;
    det_per_frame = 2;
    detections = cell(length(keyFrames)*det_per_frame, 8);
    for i_frame=1:length(keyFrames)
        frame_num = keyFrames(i_frame);
        %disp(['Frame num is' int2str(frame_num)]);
        importance = importance_array(i_frame);
        for jj=1:det_per_frame
            class_id = randi([1, params.SyntheticNumObjects]);
            %detections should be in range width/4, height/4
            x1 = randi([uint8(params.SyntheticWidth/4), uint8((3*params.SyntheticWidth)/4)]);
            x2 = randi([uint8(params.SyntheticWidth/4), uint8((3*params.SyntheticWidth)/4)]);
            y1 = randi([uint8(params.SyntheticHeight/4), uint8((3*params.SyntheticHeight)/4)]);
            y2 = randi([uint8(params.SyntheticHeight/4), uint8((3*params.SyntheticHeight)/4)]);

            %generate confidence; higher confidence for more important
            %frames
            if importance < 0.5
                a = -3;
                b = 0;
            else
                a = 0; 
                b = 3;
            end

            confidence = (b-a).*rand() + a;
            row = {frame_num, x1, x2, y1, y2, class_id, confidence, importance};
            detections(((i_frame-1) * det_per_frame + jj),:) = row; 
        end
    end
end

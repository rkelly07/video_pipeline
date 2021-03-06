% -----------------------------------------------------------------------------
% Main rtvproc function.
% Input:  filepath            full        path of the video file (for mex)
% Input:  persistent_data     struct:     VQ and other pre-processed data
% Input:  params              struct:     algorithmic params
% Input:  video_filename      struct:     system options
% Output: coreset_results     struct:     coresets and processing results
% Output: coreset_tree        struct:     coreset tree data
% Output: status              int:        1 if success, 0 if failure
% -----------------------------------------------------------------------------
function [coreset_results,coreset_tree] = process_video_fn(filepath,persistent_data,params,options)

disp(repmat('-',1,80))

global VERBOSE
VERBOSE = options.Verbose;

%% unpack persistent data

% each field in persisten_data will be unpacked
% to a variable with the same name
fields = fieldnames(persistent_data);
for i = 1:length(fields)
    s = fields{i};
    fprintf('Unpacking persistent data: %s\n',s)
    cmd = [s ' = persistent_data.' s ';'];
    eval(cmd);
end

clear persistent_data

%% init variables
disp('Initializing variables ...')

% seed rng
% this is preferred syntax to rand/randn seed
rng(0,'twister')

% buffers
VQ_dim = size(VQ,1);
descriptor_dim = size(VQ,2);
frame_buffer_idx = [];
frame_buffer = cell(1,params.CoresetLeafSize);
desc_buffer = zeros(0,VQ_dim);
BOW_buffer = zeros(0,VQ_dim);
frame_buffer_size = 0;
processed_frame_idx = [];

% init coreset stream
bow_coreset = Stream;
bow_coreset.leafSize = params.CoresetLeafSize;
bow_coreset.coresetAlg = params.CoresetAlgorithm;
bow_coreset.saveTree = params.CoresetSaveTree;

is_last_node = false;

% clean temp files
temp_files = dir(['temp',filesep,'*.mat']);
for i = 1:length(temp_files)
    temp_filename = ['temp',filesep,temp_files(i).name];
    delete(temp_filename);
end

% descriptor variables
switch upper(params.DescriptorType)
    
    case {'SURF','HOG'} % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        bags_of_words = [];
        IIR_buffer = [];
        B_med = [];
        median_filter_count = 0;

    case 'HSV' % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        bags_of_words = [];
        IIR_buffer = [];
        B_med = [];
        median_filter_count = 0;
        kdtree_desc = KDTreeSearcher(params.ColorDescRepresentatives);
        
    case 'SEMANTIC' % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        semantic_ws = [];
        semantic_ds = [];
        
        db_stream_id = [];

        semantic_model = get_semantic_model(params.SemanticModel,options.AuxFilepaths);
        semantic_state = [];
        
    otherwise % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        error('Invalid descriptor specified!');
        
end

% initializing db if the option is saving semantic detections
if options.SaveDetectionsToDB
    % same variables as 'SEMANTIC' case above
    if ~exist('semantic_ws', 'var')
        semantic_ws = [];
    end
    if ~exist('semantic_ds', 'var')
        semantic_ds = [];
    end
    
    if ~exist('db_stream_id', 'var')
        db_stream_id = [];
    end
    
    if ~exist('semantic_model', 'var') || isempty(semantic_model)
        semantic_model = get_semantic_model(params.SemanticModel,options.AuxFilepaths);
    end
    
    if ~exist('semantic_state', 'var')
        semantic_state = [];
    end
    
    % detections
    semantic_detections = [];
    
    % open the database and add a row of scene path
    db = observations_db(options.DB_Config);
    db.open_db();

    db_stream.path = filepath;
    db_stream.timestamp = datestr(now);
    db_stream.width = params.VideoInfo.Width;
    db_stream.height = params.VideoInfo.Height;
    db_stream.frame_rate = params.VideoInfo.FPS;

    db_stream_id = {filepath, db_stream.timestamp};
    db_stream.frames = params.VideoInfo.NumFrames;
    db.add_scene(db_stream);

end

% coreset tree struct
curr_node = 1;
coreset_tree = struct;
tree_T12 = [];
tree_nodes = [];
tree_data = cell(0);
num_tree_segments = 0;

% results struct
coreset_results = [];

% init figure
if options.Plot
    figure(options.FigureID)
    clf
    set(gcf,'Position',options.DefaultFigPos)
end

%% init stream
disp('Initializing video stream ...');

% process rescale size
rescale_size = params.RescaleSize;
if isempty(params.RescaleSize)
    rescale_size = [0 0];
end
if any(rescale_size == -1)
    if all(rescale_size == -1)
        rescale_size = [0 0];
    elseif rescale_size(1) == -1
        rescale_size(1) = round(params.VideoInfo.Width*(rescale_size(2)/params.VideoInfo.Height));
    elseif rescale_size(2) == -1
        rescale_size(2) = round(params.VideoInfo.Height*(rescale_size(1)/params.VideoInfo.Width));
    end
end

switch upper(params.Source)
    
    case {'VIDEO','HOGD', 'SYNTHETIC'} % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        if isempty(params.StartFrame)
            params.StartFrame = 1;
        end
        
        if isempty(params.EndFrame) || params.EndFrame == inf
            params.EndFrame = params.VideoInfo.NumFrames;
        end
        
        if isempty(params.MaxFrames)
            params.MaxFrames = inf;
        end
        
        % num_spanned_frames is the absolute start and end frame indices of the video
        % num_processed_frames is the actual number of frames processed (not including skipped frames)
        num_spanned_frames = min(params.EndFrame,params.MaxFrames-params.StartFrame+1);
        num_processed_frames = 0;
        
        % adjust num spanned frames to match skipped frame idx
        skipped_frame_idx = params.StartFrame:params.SkipFrames+1:num_spanned_frames+params.SkipFrames;
        if skipped_frame_idx(end) > num_spanned_frames
            num_spanned_frames = skipped_frame_idx(end-1);
        end
        
        % TODO:
        % handle boundary case where we end up with 1-element coresets
        if mod(num_spanned_frames,params.CoresetLeafSize)==1
            num_spanned_frames = num_spanned_frames-1;
        end
        
        % set starting frame
        curr_frame = params.StartFrame;
        
    case 'WEBCAM' % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        num_spanned_frames = inf;
        num_processed_frames = 0;
        curr_frame = 1;
        
    otherwise % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        error('Invalid source specified!');
        
end

if strcmp(params.Source , 'HOGD') % directly get Hog descriptor if HOG 

 	[f,message]=fopen(filepath, 'rb')
	if f==-1
		error('No HOG descriptors found here!')  
	end
	fseek(f, 16, 'bof');
	A = fread(f, 2835 * params.VideoInfo.NumFrames, 'short');
	fclose(f);
    A = A/32768;
elseif strcmp(params.Source , 'Synthetic')
    %find first segment length for synthetic video, open the videowriter
    %object
    outputSyntheticVideo = VideoWriter(filepath);
    outputSyntheticVideo.FrameRate = params.VideoInfo.FPS;
    open(outputSyntheticVideo)
    
    %length of first segment
    seg_len = geornd(params.SyntheticP)+1; %to avoid seg_len of zero
    %seg_len = 5;
    seg_num = 0;
    image_num = randi([1, params.SyntheticNumImages]);
    next_seg_start = 1;
    %image_num = 1;
    %disp(['Creating segment number ' int2str(seg_num) ' with seg length ' int2str(seg_len)]);
else
	% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	% init mex video processing
	h = mex_video_processing('init',filepath,params.DescriptorType,VQ,descriptor_dim,params.WebcamNo,rescale_size);

    
    %todo
    error_caught = 1; %initializing as error caught for the algorithm
    while error_caught
        try
            mex_video_processing('setframe',h,num_spanned_frames);
            [B,I,~] = mex_video_processing('newframe',h);
            error_caught = 0;
        catch
            fprintf('Could not get final frame.');
            num_spanned_frames = num_spanned_frames-1;
            fprintf('Trying to set num spanned frames = %d\n', num_spanned_frames);
        end
    end
    


	% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	% set start frame
	mex_video_processing('setframe',h,params.StartFrame);

end	
    %% process video
	disp(sprintf('Streaming frames [%d--%d] ...',curr_frame,num_spanned_frames))
	start_time = tic;

	fprintf([repmat('- ',1,30) '\n'])


% dbstop if error

% ==================================================================================================================== = 
% main loop
while curr_frame <= num_spanned_frames

    if strcmp(params.Source , 'HOGD')
        B = A(1+(curr_frame-1)*2835 : curr_frame*2835);
    
    elseif strcmp(params.Source , 'Synthetic')  
        
        if (curr_frame >= next_seg_start)
            %seg_len = 40;
            seg_len = geornd(params.SyntheticP)+1;
            next_seg_start = next_seg_start + seg_len;
            seg_num = seg_num + 1;
            image_num = randi([1, params.SyntheticNumImages]);
            %image_num = mod(seg_num, params.SyntheticNumImages);
            %if image_num == 0
                %image_num = params.SyntheticNumImages;
            %end   
        end
        I = params.VideoInfo.SyntheticInfo.Images{image_num};
        B = params.VideoInfo.SyntheticInfo.Descriptors{image_num};
        writeVideo(outputSyntheticVideo,I)
        
    else
	    % get new frame
	    try
	        
	        % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	        [B,I,~] = mex_video_processing('newframe',h);
	   
	    catch
	        
	        error('Failed to get new frame!');
	        
	    end
    end
    
    %% process frame
    % fprintf('processing frame: %d\n',curr_frame)
    
    % store frames in buffer
    frame_buffer_size = frame_buffer_size+1;
    frame_buffer_idx = [frame_buffer_idx curr_frame];
    if ~(strcmp(params.Source , 'HOGD'))
        frame_buffer{frame_buffer_size} = I;
    end
    
    switch upper(params.DescriptorType)
        
        case {'SURF','HOG'} % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            if ~strcmp(params.Source , 'Synthetic')
                % BOW linear transform
                B = B/10;
                if not(isempty(params.LinearTransform))
                    B = params.LinearTransform*B(:);
                end

                % BOW median filter
                if params.MedianFilterSize > 1
                    if (sum(abs(B))>0)
                        median_filter_count = mod(median_filter_count,params.MedianFilterSize)+1;
                        B_med(:,median_filter_count) = B(:);
                    end
                    if (exist('B_med','var') && ~isempty(B_med))
                        B = median(B_med,2);
                    else
                        B = zeros(size(B));
                    end
                end
            end
                % BOW IIR weights
                IIR_buffer = cat(1,IIR_buffer,B(:)');

                if size(IIR_buffer,1) > params.IIR_Length
                    IIR_buffer = IIR_buffer(2:end,:);
                end

                IIR_weights = (1-params.IIR_Alpha).^[-1:-1:-size(IIR_buffer,1)];
                B = sum(bsxfun(@times,IIR_buffer,IIR_weights(:)),1)/sum(IIR_weights);
            
            % save bag of words in buffer
            if (strcmpi(params.DescriptorType,'HOG')) && isempty(BOW_buffer)
                BOW_buffer=[];
                desc_buffer=[];
            end
            BOW_buffer = cat(1,BOW_buffer,B(:)');
            
            
        case 'SEMANTIC' % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            [B,semantic_state,semantic_detections] = get_semantic_words_vector(I,semantic_model,semantic_state);
            
        case 'HSV' % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            IHSV = rgb2hsv(I);
            vHSV = [];
            for channel = 1:2
                vtmp = IHSV(1:2:end,1:2:end,channel);
                vHSV = cat(2,vHSV,vtmp(:));
            end
            cidx = kdtree_desc.knnsearch(vHSV,'K',1);
            % cidx = knnsearch(params.ColorDescRepresentatives,vHSV);
            B = hist(cidx,1:size(params.ColorDescRepresentatives,1));
            B = B(:)';
            BOW_buffer = cat(1,BOW_buffer,B(:)');
            % B = randn(1,size(params.ColorDescRepresentatives,1))*100;
            
        otherwise % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            error('Invalid descriptor specified!');
            
    end
    
    desc_buffer(frame_buffer_size,:) = B(:)';
    
    % save semantic detections if option specified
    if options.SaveDetectionsToDB
        
        % if the descriptor type is SEMANTIC, get_semantic_words_vector has already been done
        % before. So, do it only if it's not semantic
        if ~strcmp(params.DescriptorType, 'SEMANTIC')
            [B_sem,semantic_state,semantic_detections] = get_semantic_words_vector(I,semantic_model,semantic_state);    
        end
        
        db.add_detections_from_frame(semantic_detections,db_stream_id,curr_frame);
        
        semantic_ws = cat(1,semantic_ws,semantic_detections(:,1));
        semantic_ds = cat(1,semantic_ds,ones(size(semantic_detections(:,1)))*curr_frame);
        save('temp/tmp_semantic_words.mat','semantic_ws','semantic_ds','bags_of_words');
                
    end 
    
    %% compute coresets
    
    if frame_buffer_size >= params.CoresetLeafSize || curr_frame >= num_spanned_frames
        
        % ------------------------------------------------
        % add leaf to BOW coreset:
        add_leaf

    else
        
        c = 0;
        if options.Plot
            c = get(options.FigureID,'CurrentCharacter');
        end
        
        % check user interrupt key
        if c == 13 % return

            disp('Interrupt character detected: terminating stream')

            num_spanned_frames = curr_frame;

            % ------------------------------------------------
            % add leaf to BOW coreset:
            add_leaf

            % end main loop
            break

        end

    end

    %% plot
    if options.Plot && options.PlotFrames
        
        % % set if mex incorrectly transposed image for some reason
        % if options.TransposeImage
            % I = flipud(permute(I,[2 1 3]));
        % end
        
        sfigure(options.FigureID); subplot(231);
        image(I)
        axis image, axis off
        title_str = ['source ' num2str(params.SourceNo) ': frame ' num2str(curr_frame)];
        % title_str = strcat(titlestr,[', left: ',num2str(mins_rem),':',num2str(secs_rem)]);
        title(title_str,'FontSize',16)
        drawnow
        
    end
    
    if options.Plot && options.PlotBOW
        
        sfigure(options.FigureID); subplot(232);
        
        switch upper(params.DescriptorType)
            
            case {'SURF','HSV','HOG'} % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
                bags_of_words = cat(1,bags_of_words,B);
                plot_bow = bags_of_words(max(1,end-params.DisplayBufferSize):end,:);
                
                if (~exist('sorted_idx','var')) || mod(curr_frame,10)==0
                    [~,sorted_idx] = sort(sum(plot_bow,1));
                    best_idx = sorted_idx(end:-1:max(1,end-params.DisplayNumBestBOW+1));
                end
                
                lastn_bows = plot_bow(:,best_idx).*255;
                if size(lastn_bows,1) <= params.DisplayBufferSize
                    lastn_bows = cat(1,lastn_bows,zeros(params.DisplayBufferSize-size(lastn_bows,1),size(lastn_bows,2)));
                else
                    lastn_bows = lastn_bows(end-params.DisplayBufferSize+1:end,:);
                end
                
                % boost color display
                % lastn_bows = lastn_bows/median(abs(lastn_bows(:))+)/100;
                
                % TODO: magic number
                [~,xbows] = hist(lastn_bows(:),20);
                if not(isempty(lastn_bows))
                    imshow(lastn_bows',[xbows(1),xbows(end)]);
                    colormap jet
                end
                
                title('BOW coefficients','FontSize',16)
                
            case 'SEMANTIC' % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                
                title('Semantic Words','FontSize',16)
                display_semantic_state(semantic_state);
                
                
            otherwise % - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
                error('Invalid descriptor specified!');
                
        end
        
        drawnow
        
    end
    
    %% update
    
    % update frame indexing
    curr_frame = curr_frame+1;
    num_processed_frames = num_processed_frames+1;
    
    if ~(strcmp(params.Source , 'HOGD') || strcmp(params.Source , 'Synthetic'))
        % skip frames if needed
        if curr_frame < num_spanned_frames

            curr_frame = curr_frame+params.SkipFrames;
            mex_video_processing('setframe',h,curr_frame);

            % always need to process the last frame
            % to build coreset tree
            if curr_frame > num_spanned_frames
                curr_frame = num_spanned_frames;
            end
        end
    end
    t = toc(start_time);
    t_rem = (t/curr_frame*num_spanned_frames)-t;
    % fprintf('%.2f minutes elapsed\n',t/60);
    % fprintf('%.2f minutes remaining',t_rem/60);
    
    % last node already computed because of skipped frames
    % check flag (set in process_coreset_tree)
    if is_last_node
        break
    end
    
end % main loop

% ==================================================================================================================== = 

disp('Done!')
running_time = toc(start_time);
fprintf('%.2f minutes elapsed\n',running_time/60);

%% save results
coreset_results.StartFrame = params.StartFrame;
coreset_results.EndFrame = params.EndFrame;
coreset_results.SkipFrames = params.SkipFrames;
coreset_results.NumSpannedFrames = num_spanned_frames;
coreset_results.NumProcessedFrames = num_processed_frames;
coreset_results.ProcessedFrameIdx = processed_frame_idx;
coreset_results.BOW = bags_of_words;
coreset_results.BOW_Coreset = bow_coreset;
% coreset_results.SemanticDs = semantic_ds;
% coreset_results.SemanticWs = semantic_ws;

% restore saved coreset tree data
temp_files = dir('temp/node_*.mat');
for i = 1:length(temp_files)
    if isempty(tree_data{i})
        temp_filename = sprintf('temp/node_%d.mat',i);
        load(temp_filename,'tree_data_i')
        tree_data{i} = tree_data_i;
        delete(temp_filename);
    end
end

coreset_tree.NumSpannedFrames = num_spanned_frames;
coreset_tree.NumProcessedFrames = num_processed_frames;
coreset_tree.LeafSize = params.CoresetLeafSize;
coreset_tree.NumSegments = num_tree_segments;
coreset_tree.NumNodes = length(tree_nodes); % had num_tree_nodes
coreset_tree.T12 = tree_T12;
coreset_tree.Nodes = tree_nodes;
coreset_tree.Data = tree_data';

if strcmp(params.Source, 'Synthetic')
    close(outputSyntheticVideo);
end

end

%%
function fprintf(varargin)
global VERBOSE
if isempty(VERBOSE)
    VERBOSE = 1;
end
if VERBOSE
    builtin('fprintf',varargin{:});
end
end

% ------------------------------------------------
% reformatted with stylefix.py on 2015/03/13 03:06


% ------------------------------------------------
% reformatted with stylefix.py on 2015/05/04 10:14

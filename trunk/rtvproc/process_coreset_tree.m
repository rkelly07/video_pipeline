% process coreset tree
% calling stack prereq: add_leaf
%#ok<*SUSENS>
%#ok<*SNASGU>
s = dbstack;
assert(boolean(strcmp(s(2).name,'add_leaf')))

%%

% TODO:
% fix the logic to handle the root node at the end,
% instead of iterating to length of coreset +1
for this_node = curr_node:length(bow_coreset.coresetsList)+1
     
    % if this is last node in stream
    make_root_node = false;
    
    % check if last node in the coreset
    if this_node == length(bow_coreset.coresetsList)+1
        
        % check if last overall node
        is_last_node = (bow_coreset.coresetsList{this_node-1}.t2+params.SkipFrames >= num_spanned_frames);    
        if is_last_node
            
            fprintf('Reached last node: ')
            
            % check if this node is already a root node:
            % true iff it is curretly the only node with no parents 
            is_root_node = length(find(tree_nodes==0))==1;
            if is_root_node
                
                fprintf('Root node already exists!\n')
                break
                
            else
                
                fprintf('Root node not detected. Computing unified coreset ...\n')
                
                % get unified coreset
                bow_coreset.coresetsList{this_node} = bow_coreset.getUnifiedCoreset();
                make_root_node = true;
                
                % join all orphan nodes to root node
                tree_nodes(tree_nodes==0) = this_node;
                
            end
            
        else
            
            % not the last overall node
            % so there is no data for this_node_idx
            break
            
        end
        
    end
    
    %%
    fprintf('Node %d ',this_node)
    
    tree_T12(this_node,:) = [bow_coreset.coresetsList{this_node}.t1, bow_coreset.coresetsList{this_node}.t2];
    
    % nodes are orphaned by default
    % parent nodes will be overwritten automatically
    tree_nodes(this_node) = 0;
    this_children_nodes = [];
    
    if not(make_root_node)
        ch1_idx = find(tree_T12(:,1)==bow_coreset.coresetsList{this_node}.t1)';
        ch2_idx = find(tree_T12(:,2)==bow_coreset.coresetsList{this_node}.t2)';
        for ii = ch1_idx
            for jj = ch2_idx
                
                % check if ch1.t2 and ch2.t1 are adjacent
                % if skipping frames, then there is a SkipFrames+1 difference
                frame_diff = bow_coreset.coresetsList{jj}.t1 - bow_coreset.coresetsList{ii}.t2;
                if frame_diff == params.SkipFrames+1
                    ch1 = ii;
                    ch2 = jj;
                    this_children_nodes = [ch1 ch2];
                    fprintf('(%d %d)',ch1,ch2)
                    tree_nodes(ch1) = this_node;
                    tree_nodes(ch2) = this_node;
                end
                
            end
        end
    else
        this_children_nodes = find(tree_nodes==this_node);
    end
    fprintf(':\n')
    
    %% select keyframes
        
    if isempty(this_children_nodes)
        %% case: LEAF
        % use frames from buffer
        
        % compute the median frame index from the coreset segments
        this_node_num_segments = bow_coreset.coresetsList{this_node}.m;
        this_node_T12 = bow_coreset.coresetsList{this_node}.T12;
        seg_median_frame_idx = zeros(1,this_node_num_segments);
        for i = 1:this_node_num_segments
            kx = floor(median(this_node_T12(i,1):this_node_T12(i,2)));
            seg_median_frame_idx(i) = kx;
        end
        if options.PlotKeyframes
            % find the relative candidate frames frame indices
            Kx_candidate_idx = zeros(1,length(seg_median_frame_idx));
            for i = 1:length(Kx_candidate_idx)
                Kx_candidate_idx(i) = find(frame_buffer_idx >= seg_median_frame_idx(i),1,'first');
            end
            candidate_frames = frame_buffer(Kx_candidate_idx);
            candidate_desc = desc_buffer(Kx_candidate_idx,:);
            % compute segment votes and time fractions from coreset
            Kx_seg_votes = ones(size(seg_median_frame_idx))';
            Kx_seg_tspan = (this_node_T12(:,2)-this_node_T12(:,1)+1);
            Kx_seg_tfrac = Kx_seg_tspan./sum(Kx_seg_tspan);

            % -------------------------------------------------------------
            % select keyframes: leaf
            this_node_type = 'Leaf';
            if (strcmp(params.Source, 'Synthetic'))
                [Kx_sel_idx, new_Kx_metrics] = select_keyframes_synthetic( ...
                    this_node_type, ...
                    candidate_frames, ...
                    candidate_desc, ...
                    Kx_seg_votes, ...
                    Kx_seg_tfrac, ...
                    params.KxMetricWeights, ...
                    params.KxSimilarityThreshold);                
            else
                [Kx_sel_idx, new_Kx_metrics] = select_keyframes( ...
                    this_node_type, ...
                    candidate_frames, ...
                    candidate_desc, ...
                    Kx_seg_votes, ...
                    Kx_seg_tfrac, ...
                    params.KxMetricEnums, ...
                    params.KxMetricWeights, ...
                    params.KxBrightnessThreshold, ...
                    params.KxSimilarityThreshold);
            end
            % -------------------------------------------------------------

            % find absolute keyframe idx by indexing back into candidate idx
            Kx_abs_idx = paren(frame_buffer_idx(Kx_candidate_idx),Kx_sel_idx);
        else
            this_node_type = 'Leaf';
        end
    else
        %% case: MERGE
        % use frames from children nodes
        
        candidate_frames = [];
        candidate_desc = [];
        this_node_num_segments = 0;
        children_sel_idx = [];
        children_abs_idx = [];
        
        % aggregate votes and time fraction from children nodes
        Kx_seg_votes = [];
        Kx_seg_tfrac = [];

        % aggregate fields for all children nodes
        for i = 1:length(this_children_nodes)
            ci = this_children_nodes(i);
            this_node_num_segments = this_node_num_segments + tree_data{ci}.NumSegments;
            if options.PlotKeyframes
                candidate_frames = [candidate_frames tree_data{ci}.Keyframes];
                candidate_desc = [candidate_desc; tree_data{ci}.Descriptors]; 
                children_sel_idx = [children_sel_idx tree_data{ci}.KeyframeSelIdx];
                children_abs_idx = [children_abs_idx tree_data{ci}.KeyframeAbsIdx];
                Kx_seg_votes = [Kx_seg_votes tree_data{ci}.Metrics.votes];
                Kx_seg_tfrac = [Kx_seg_tfrac tree_data{ci}.Metrics.tfrac];
            end
        end
        if options.PlotKeyframes
            Kx_seg_tfrac = Kx_seg_tfrac/sum(Kx_seg_tfrac);
            Kx_candidate_idx = 1:length(candidate_frames);
            % -------------------------------------------------------------
            % select keyframes: merge
            this_node_type = 'Merge';
            if (strcmp(params.Source, 'Synthetic'))
                [Kx_sel_idx, new_Kx_metrics] = select_keyframes_synthetic(...
                    this_node_type,...
                    candidate_frames, ...
                    candidate_desc, ...
                    Kx_seg_votes, ...
                    Kx_seg_tfrac, ...
                    params.KxMetricWeights, ...
                    params.KxSimilarityThreshold);                
            else
                [Kx_sel_idx, new_Kx_metrics] = select_keyframes(...
                    this_node_type,...
                    candidate_frames, ...
                    candidate_desc, ...
                    Kx_seg_votes, ...
                    Kx_seg_tfrac, ...
                    params.KxMetricEnums, ...
                    params.KxMetricWeights, ...
                    params.KxBrightnessThreshold, ...
                    params.KxSimilarityThreshold);               
            end
            % -------------------------------------------------------------

            % find absolute keyframe idx by indexing back into candidate idx
            Kx_abs_idx = paren(children_abs_idx(Kx_candidate_idx),Kx_sel_idx);
        else
            this_node_type = 'Merge';
        end
    end
    if options.PlotKeyframes

        % update selected keyframes and descriptors
        selected_keyframes = candidate_frames(Kx_sel_idx);
        selected_descriptors = candidate_desc(Kx_sel_idx,:);


        % save coreset tree data data
        tree_data{this_node}.FrameSpan = tree_T12(this_node,:);
        tree_data{this_node}.NumCandidateKeyframes = length(Kx_candidate_idx);
        tree_data{this_node}.NumKeyframes = length(Kx_sel_idx);
        tree_data{this_node}.Keyframes = selected_keyframes;
        tree_data{this_node}.Descriptors = selected_descriptors;
        tree_data{this_node}.KeyframeSelIdx = Kx_sel_idx;
        tree_data{this_node}.KeyframeAbsIdx = Kx_abs_idx;
        tree_data{this_node}.Metrics = new_Kx_metrics;
    end
    tree_data{this_node}.NodeType = this_node_type;
    tree_data{this_node}.NumSegments = this_node_num_segments;
    % find children of curr node
    this_children_idx = find(tree_nodes==this_node);
    children_T12 = tree_T12(this_children_idx,:);
    
    if options.PlotKeyframes
        fprintf('Keyframes = %s\n',mat2str(Kx_sel_idx))
    else
        children_colors = hsv(max(length(this_children_idx),3));
        children_colors(2,:) = [0 0.8 0];
    end
    %% Plot Keyframe Collage
    if options.Plot && options.PlotKeyframes
        
        children_colors = hsv(max(length(this_children_idx),3));
        children_colors(2,:) = [0 0.8 0];
        
        border_colors = cell(1,tree_data{this_node}.NumKeyframes);
        if not(isempty(this_children_idx))
            for i = 1:tree_data{this_node}.NumKeyframes
                axi = tree_data{this_node}.KeyframeAbsIdx(i);
                xx1 = find(axi>=children_T12(:,1));
                xx2 = find(axi<=children_T12(:,2));
                ixx = intersect(xx1,xx2);
                border_colors{i} = children_colors(ixx,:);
            end
        else
            for i = 1:length(tree_data{this_node}.KeyframeSelIdx)
                border_colors{i} = [1 0.8 0.2];
            end
        end
        
        figure(options.FigureID), subplot(234)
        node_span_str = [num2str(bow_coreset.coresetsList{this_node}.t1) '--' num2str(bow_coreset.coresetsList{this_node}.t2)];

        % -------------------------------------------------------------
        draw_keyframe_collage(tree_data{this_node}.Keyframes,border_colors);
        
        % -------------------------------------------------------------
        
        title(['Keyframes ' node_span_str],'FontSize',16)
        
    end 
    
    %% Plot Tree
    if options.Plot && options.PlotTree
        
        figure(options.FigureID), subplot(235)
        treeplot(tree_nodes,'ko','k-');
        title(['Coreset Tree: Leaf Size = ' num2str(params.CoresetLeafSize)],'FontSize',16)
        axis off

        axes_hnd = subplot(235);
        lines_hnd = findobj(axes_hnd,'type','line');
        nodes_xy = get(lines_hnd(end));
        nodes_x = nodes_xy.XData;
        nodes_y = nodes_xy.YData;
        
        % draw selected node
        nx = nodes_x(this_node);
        ny = nodes_y(this_node);
        sel_node_radius = 0.05;
        try
            rectangle('Position',[nx-sel_node_radius/2 ny-sel_node_radius/2 sel_node_radius sel_node_radius], ...
                'Curvature',[1 1],'LineWidth',3,'EdgeColor','black');
        catch e
            warning(e.identifier,e.message)
        end
        
        % draw children nodes
        ch_node_radius = 0.05;
        for i = 1:length(this_children_idx)
            nxi = nodes_x(this_children_idx(i));
            nyi = nodes_y(this_children_idx(i));
            try
                rectangle('Position',[nxi-ch_node_radius/2 nyi-ch_node_radius/2 ch_node_radius ch_node_radius], ...
                    'Curvature',[0 0],'LineWidth',2,'EdgeColor',children_colors(i,:));
            catch e
                warning(e.identifier,e.message)
            end
        end
        
    end
    
    %% Plot Keyframe Selection Data
    if options.Plot && options.PlotKeyframeMetrics
        
        D = tree_data{this_node}.Metrics.D;
        w = tree_data{this_node}.Metrics.w;
        M = tree_data{this_node}.Metrics.M;
        f = tree_data{this_node}.Metrics.f;
                
        figure(options.FigureID)
        subplot_idx1 = 233;
        subplot_idx2 = 236;
        
        % -------------------------------------------------------------
        draw_keyframe_metrics(Kx_sel_idx,D,w,M,f,subplot_idx1,subplot_idx2)
        
        % -------------------------------------------------------------

    end
    
    %%
    drawnow
    
end % for loop

%% save coreset data to disk
children_nodes = find(tree_nodes > 0);
if not(isempty(children_nodes))
    fprintf('Clearing tree cache: ')
    for i = children_nodes
        if not(isempty(tree_data{i}))
            %fprintf('clearing tree cache: node %d\n',i)
            fprintf('.')
            temp_filename = sprintf('temp/node_%d.mat',i);
            tree_data_i = tree_data{i};
            save(temp_filename,'tree_data_i','i')
            tree_data{i} = [];
            clear tree_data_i
        end
    end
    fprintf('\n')
end


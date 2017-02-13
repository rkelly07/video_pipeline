function [ save_filepath coreset_tree coreset_results ] = create_simpler_coreset_tree( coreset_tree_path, coreset_results_path )
%CREATE_SIMPLER_CORESET_TREE Creates a simple/smaller coreset tree given the
%larger one created with video process pipeline. It is useful if only a
%subset of information from the coreset tree is needed for some
%application. 

    disp('Starting creation of simpler coreset');
    if ~exist('coreset_tree', 'var')
        disp('Loading coreset tree..');
        if exist(coreset_tree_path, 'file')
            %must load with the variable name "coreset_tree"
            load(coreset_tree_path);
            coreset_tree
        else
            error('Coreset tree path not found');
        end      
    end


    if ~exist('coreset_results', 'var')
        disp('Loading coreset results..');
        if exist(coreset_results_path, 'file')
            %must load with the variable name "coreset_results"
            load(coreset_results_path);
            coreset_results
        else
            error('Coreset results path not found');
        end
    end


    %% Initialization
    %initialize tree coreset
    %the fields of struct
    tree_fields = {'NumNodes', 'T12', 'TreeStructure', 'Nodes'};
    simple_coreset = struct;
    for tree_field=tree_fields
        str_tree_field = char(tree_field);
        simple_coreset.(str_tree_field) = {};
    end

    % initialize the node struct, which goes into the 'Nodes' field of the tree
    % struct
    node_fields = {'NodeType', 'FrameSpan', 'NumSegs', 'SegT12', 'KeyFrames', 'tFrac', 'Importance'};
    node_struct = struct;
    for node_field = node_fields
        str_node_field = char(node_field);
        node_struct.(str_node_field) = {};
    end


    %% Fill the structs with needed info

    num_nodes = coreset_tree.NumNodes;
    node_range = coreset_tree.T12;
    tree_structure = coreset_tree.Nodes;
    nodes = repmat(node_struct, 1, num_nodes );

    nodes_data = coreset_tree.Data;


    for node_num = 1:length(nodes_data) 
        node_data = nodes_data{node_num};
        node_type = node_data.NodeType;
        frame_span = node_data.FrameSpan;
        num_segs = node_data.NumSegments;
        key_frames = node_data.KeyframeAbsIdx;
        t_frac = node_data.Metrics.tfrac;
        importance = node_data.Metrics.imp;
        %make segment range matrix from coreset_results.BOWCoreset
        node_coreset = coreset_results.BOW_Coreset.coresetsList{node_num};
        seg_t12 = zeros(length(node_coreset.segments), 2);
        for i=1:length(node_coreset.segments)
            segment = node_coreset.segments{i};
            seg_t12(i,1) = segment.t1;
            seg_t12(i,2) = segment.t2;
        end

        %now fill the struct for this node
        this_node_struct = nodes(node_num);
        this_node_struct.NodeType = node_type;
        this_node_struct.FrameSpan = frame_span;
        this_node_struct.NumSegs = num_segs;
        this_node_struct.SegT12 = seg_t12;
        this_node_struct.KeyFrames = key_frames;
        this_node_struct.tFrac = t_frac;
        this_node_struct.Importance = importance;
        nodes(node_num) = this_node_struct;
    end

    %fill the tree structure
    simple_coreset.NumNodes = num_nodes;
    simple_coreset.T12 = node_range;
    simple_coreset.TreeStructure = tree_structure;
    simple_coreset.Nodes = nodes;

    simple_coreset

    [pathstr,name,ext] = fileparts(coreset_tree_path);

    save_dir = 'simpler_coreset_results';
    tree_filename = ['simple_' name '.mat'];
    save_filepath = [save_dir,filesep, tree_filename];
    save(save_filepath, 'simple_coreset');
    save_filepath = fullpath(save_filepath);
end


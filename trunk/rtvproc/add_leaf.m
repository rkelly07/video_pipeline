% add leaf to BOW coreset
% calling stack prereq: process_video_fn
%#ok<*SUSENS>
%#ok<*SNASGU>
s = dbstack;
assert(boolean(strcmp(s(2).name,'process_video_fn')))

%%
fprintf('Adding leaf: frames %d--%d\n',frame_buffer_idx(1),frame_buffer_idx(end)) 
P = SignalPointSet(BOW_buffer,frame_buffer_idx);
bow_coreset.addPointSet(P);

if params.ComputeCoresetTree
    
    % ------------------------------------------------
    % process coreset tree and save to disk:
    process_coreset_tree
    
    % update node
    % TODO:
    % fix the logic to handle the root node at the end,
    % instead of iterating to length of coreset +1
    curr_node = length(bow_coreset.coresetsList)+1;
    
    % reached last node, update tree values
    num_tree_segments = tree_data{end}.NumSegments;
    num_tree_nodes = length(tree_nodes);
    
end

% record processed frames
processed_frame_idx = [processed_frame_idx frame_buffer_idx]; 

% empty buffers
frame_buffer_size = 0;
frame_buffer_idx = [];
frame_buffer = cell(1,params.CoresetLeafSize);
BOW_buffer = zeros(0,VQ_dim);

disp(sprintf('Processed %d/%d frames: %.2f minutes elapsed',curr_frame,num_spanned_frames,toc(start_time)/60))
%freemem = mymemory();
%fprintf('memory usage: %d MB\n',ceil(freemem/1e6))

t = toc(start_time);
fprintf('%.2f minutes elapsed\n',t/60);

fprintf([repmat('- ',1,30) '\n'])
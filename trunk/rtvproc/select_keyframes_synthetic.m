function [Kx_sel_idx, new_Kx_metrics] = select_keyframes_synthetic(...
    node_type, ...
    candidate_frames, ...
    candidate_desc, ...
    Kx_seg_votes, ...
    Kx_seg_tfrac, ...
    Kx_metric_weights, ...
    Kx_similarity_threshold)

% this is now hard-coded and non-optional
MAX_KEYFRAMES = 9;

num_candidate_frames = length(candidate_frames);
Kx_candidate_idx = 1:num_candidate_frames;
num_required_keyframes = min(num_candidate_frames,MAX_KEYFRAMES);

% initialize metrics
num_metrics = length(Kx_metric_weights);
w = Kx_metric_weights;
M = zeros(num_metrics,num_candidate_frames);
D = zeros(num_candidate_frames);
f = zeros(1,num_candidate_frames);

dropped_frames = zeros(1,num_candidate_frames);

%%
fprintf('Analyzing candidate keyframes: ');
switch upper(node_type)
    
    case 'LEAF'
        %% use frames from buffer
        
        bstr = '';
        for i = 1:num_candidate_frames
            msg = sprintf('%d/%d',i,num_candidate_frames);
            fprintf([bstr msg]);
            bstr = repmat(sprintf('\b'),1,length(msg));
            %fprintf('.')
            frame_cell = candidate_frames(i);
            frame = frame_cell{1};
            f(i) = frame(1,1,1); %importance value is encoded in the first red pixel
        end
        fprintf('\n');
        
        
        %select the frames in order of their fs
        %[sorted_f, indices] = sort(f);
        %selected_idx = indices((length(indices) - num_required_keyframes+1):length(indices));
        %Kx_sel_idx = sort(selected_idx);
        
        % select the frames uniformly spaced
        Kx_sel_idx = [1 ceil((1:num_required_keyframes-1)*num_candidate_frames/(num_required_keyframes-1))];
        selected_f = f(Kx_sel_idx);
        new_Kx_metrics.imp = selected_f;
        
    case 'MERGE'
        %% use frames from children nodes
        
        for i = 1:num_candidate_frames
            for j = i+1:num_candidate_frames
                D(i,j) = sum((candidate_desc(i,:)-candidate_desc(j,:)).^2);
                D(j,i) = D(i,j);
            end
        end
        
        
        for i = 1:num_candidate_frames
            frame_cell = candidate_frames(i);
            frame = frame_cell{1};
            f(i) = frame(1,1,1); %importance value is encoded in the first red pixel
        end
        
        f = f./10; %doing this scaling. TODO - Ask Mi
        
        % drop control frames
        f(dropped_frames==1) = -inf;
        
        % drop similar frames
        for i = 1:num_candidate_frames
            for j = i+1:num_candidate_frames
                % check similarity threshold from
                % non-normalized D matrix
                if D(i,j) < Kx_similarity_threshold
                    f(j) = -inf;
                end
            end
        end
        
        % normalize
        if not(sum(D(:))==0)
            D = D./sum(D(:));
        end
        
        % -------------------------------------------------------------
        % farthest point search using quality score
        [ranking_idx,~] = fps(D,num_required_keyframes,[],f);
        
        % -------------------------------------------------------------
        
        % exclude dropped frames
        ranking_idx = setdiff(ranking_idx,find(isinf(f)));
        
        % we must keep at least one keyframe
        if isempty(ranking_idx)
            ranking_idx = Kx_candidate_idx(1);
        end
        
        % select the required num of frames from FPS
        Kx_sel_idx = sort(Kx_candidate_idx(ranking_idx));
        
        selected_f = f(Kx_sel_idx);
        new_Kx_metrics.imp = selected_f;
    otherwise
        %%
        error([],'Invalid node type');
        
end

%% update keyframe metrics

num_keyframes = length(Kx_sel_idx);

new_Kx_metrics.D = D;
new_Kx_metrics.f = f;
new_Kx_metrics.w = w;
new_Kx_metrics.M = M;

% update votes and tfrac using nearest neighbor hist
vote_hist = zeros(1,num_candidate_frames);
for i = 1:num_candidate_frames
    vote_hist(i) = find(abs(Kx_sel_idx-Kx_candidate_idx(i))==min(abs(Kx_sel_idx-Kx_candidate_idx(i))),1,'first');
end
for i = 1:num_keyframes
    new_Kx_metrics.votes(i) = sum(Kx_seg_votes(vote_hist==i));
    new_Kx_metrics.tfrac(i) = sum(Kx_seg_tfrac(vote_hist==i));
    
end

end % function

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


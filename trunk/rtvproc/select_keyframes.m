function [Kx_sel_idx, new_Kx_metrics] = select_keyframes(...
    node_type, ...
    candidate_frames, ...
    candidate_desc, ...
    Kx_seg_votes, ...
    Kx_seg_tfrac, ...
    Kx_metric_enums, ...
    Kx_metric_weights, ...
    Kx_brightness_threshold, ...
    Kx_similarity_threshold)

% this is now hard-coded and non-optional
MAX_KEYFRAMES = 9;

num_candidate_frames = length(candidate_frames);
Kx_candidate_idx = 1:num_candidate_frames;
num_required_keyframes = min(num_candidate_frames,MAX_KEYFRAMES);

% initialize metrics
num_metrics = length(Kx_metric_weights);
w = Kx_metric_weights;
D = zeros(num_candidate_frames);
M = zeros(num_metrics,num_candidate_frames);
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
        end
        fprintf('\n');
        
        
        for i = 1:num_candidate_frames
            for j = i+1:num_candidate_frames
                D(i,j) = sum((candidate_desc(i,:)-candidate_desc(j,:)).^2);
                D(j,i) = D(i,j);
            end
        end

        % normalize
        if not(sum(D(:))==0)
            D = D./sum(D(:));
        end

        % compute votes and tfrac from leaf metrics
        M(Kx_metric_enums.SEG_VOTES,:) = Kx_seg_votes; % votes
        M(Kx_metric_enums.SEG_TFRAC,:) = Kx_seg_tfrac; % tfrac
        %M(Kx_metric_enum.SEG_CFRAC,:) = cumsum(Kx_seg_tfrac);

        % compute relevance score
        for i = 1:size(M,1)
            if not(sum(M(i,:))==0)
                M(i,:) = M(i,:)./abs(sum(M(i,:)));
            end
            f = f + w(i)*M(i,:);
        end
        
        % select the frames uniformly spaced
        Kx_sel_idx = [1 ceil((1:num_required_keyframes-1)*num_candidate_frames/(num_required_keyframes-1))];
        
    case 'MERGE'
        %% use frames from children nodes
        
        R{Kx_metric_enums.QUALITY} = zeros(1,num_candidate_frames);
        
        %waitbar_h = waitbar(0,'Analyzing image content: ','Position',[480 200 288 60]);
        bstr = '';
        for i = 1:num_candidate_frames
            
            %waitbar(i/num_candidate_frames,waitbar_h,sprintf('Analyzing image content: %d/%d',i,num_candidate_frames))
            msg = sprintf('%d/%d',i,num_candidate_frames);
            fprintf([bstr msg]);
            bstr = repmat(sprintf('\b'),1,length(msg));
            %fprintf('.')
            
            I = candidate_frames{i};
            HSV = rgb2hsv(I);
            V = HSV(:,:,3);
            
            brightness = sum(V(:))/numel(V);
            
            % check control frames
            if brightness < Kx_brightness_threshold
                dropped_frames(i) = 1;
                continue
            end
            
            if w(Kx_metric_enums.QUALITY) > 0
                
                % -------------------------------------------------------------
                % compute blur index
                blur_score = analyze_blur(V);
                R{Kx_metric_enums.QUALITY}(i) = blur_score;
                
                % TODO: fix positive/negative blur score
                if blur_score > 0.75
                    dropped_frames(i) = 1;
                end
                
                % -------------------------------------------------------------
                
                % TODO: add other quality metrics here
                
            end
            
        end
        %delete(waitbar_h)
        fprintf('\n');
        
        for i = 1:num_candidate_frames
            for j = i+1:num_candidate_frames
                D(i,j) = sum((candidate_desc(i,:)-candidate_desc(j,:)).^2);
                D(j,i) = D(i,j);
            end
        end
        
        % keyframe new metrics
        M(Kx_metric_enums.QUALITY,:) = R{Kx_metric_enums.QUALITY};
        M(Kx_metric_enums.SEG_VOTES,:) = Kx_seg_votes;
        M(Kx_metric_enums.SEG_TFRAC,:) = Kx_seg_tfrac;
        %M(Kx_metric_enum.SEG_CFRAC,:) = cumsum(Kx_seg_tfrac);
        
        % compute relevance score
        for i = 1:size(M,1)
            if not(sum(M(i,:))==0)
                M(i,:) = M(i,:)./abs(sum(M(i,:)));
            end
            f = f + w(i)*M(i,:);
        end
        
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
        
    otherwise
        %%
        error([],'Invalid node type');
        
end

%% update keyframe metrics

num_keyframes = length(Kx_sel_idx);

new_Kx_metrics.D = D;
new_Kx_metrics.w = w;
new_Kx_metrics.M = M;
new_Kx_metrics.f = f;

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


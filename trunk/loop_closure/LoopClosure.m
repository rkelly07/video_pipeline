classdef LoopClosure <handle
    % Class help goes here
    properties
        keyframes
        pages_stack
        working_memory
        timer
    end
    
    properties (Dependent)
        num_pages
        internal_dim
    end
    
    properties (Transient)
    end
    
    properties (SetAccess = protected, GetAccess = private)
    end
    
    events
    end
    
    methods
        function obj = LoopClosure()
            obj.pages_stack = {};
            obj.working_memory.pages_ids = [];
            obj.working_memory.pages = {};
            obj.timer = 1;
            obj.keyframes = [];
            obj.working_memory.pages_bdate = [];
        end
        function [page] = create_new_page(obj)
            new_page = {};
            obj.pages_stack{end+1} = new_page;
            [page] = obj.swap_page_in(numel(obj.pages_stack));
        end
        function res = is_page_in(obj,page_id)
            res = false;
            if (sum(obj.working_memory.pages_ids==page_id)>0)
                res = true;
            end
        end
        function [page] = swap_page_in(obj,page_id)
            if (sum(obj.working_memory.pages_ids==page_id)>0)
                error('page already in');
            end
            obj.working_memory.pages{end+1} = obj.pages_stack{page_id};
            obj.working_memory.pages_ids(end+1) = page_id;
            pg_idx = numel(obj.working_memory.pages_ids);
            obj.working_memory.pages_bdate(end+1) = obj.timer;
            page = obj.working_memory.pages{pg_idx};
        end
        function [page] = get_cached_page(obj,page_id)
            if (sum(obj.working_memory.pages_ids==page_id)==0)
                error('page not cached');
            end
            pg_idx = numel(obj.working_memory.pages_ids);
            page = obj.working_memory.pages{pg_idx};
        end
        function clear_page(obj,idx)
            % if numel(obj.working_memory.pages_bdate)>0
            % ranking = obj.timer-obj.working_memory.pages_bdate;
            % [~,idx] = sort(ranking,'descend');
            
            idx_new = 1:numel(obj.working_memory.pages);
            idx_new(obj.working_memory.pages_ids==idx) = [];
            % idx_new(1) = [];
            if (isempty(idx_new))
                obj.working_memory.pages = {};
                obj.working_memory.pages_ids = [];
                obj.working_memory.pages_bdate = [];
            else
                obj.working_memory.pages = {obj.working_memory.pages{idx_new}};
                obj.working_memory.pages_ids = obj.working_memory.pages_ids(idx_new);
                obj.working_memory.pages_bdate = obj.working_memory.pages_bdate(idx_new);
            end
            % end
        end
        function clear_old_page(obj)
            if numel(obj.working_memory.pages_bdate)>0
                ranking = obj.timer-obj.working_memory.pages_bdate;
                [~,idx] = sort(ranking,'descend');
                idx_new = idx;
                idx_new(1) = [];
                if (isempty(idx_new))
                    obj.working_memory.pages = {};
                    obj.working_memory.pages_ids = [];
                    obj.working_memory.pages_bdate = [];
                else
                    obj.working_memory.pages = {obj.working_memory.pages{idx_new}};
                    obj.working_memory.pages_ids = obj.working_memory.pages_ids(idx_new);
                    obj.working_memory.pages_bdate = obj.working_memory.pages_bdate(idx_new);
                end
            end
        end
        function [page,idx] = swap_random_page(obj,method,additional_data)
            switch lower(method)
                case 'random'
                    idxs = setdiff(1:numel(obj.pages_stack),obj.working_memory.pages_ids);
                    if (~isempty(idxs))
                        num_pages = numel(idxs);
                        idx = ceil(rand(1)*num_pages);
                        idx = idxs(idx);
                        [page] = obj.swap_page_in(idx);
                    else
                    end
                case 'tree'
                    idx = sample_tree(additional_data.tree_nodes,additional_data.init_node,0.5,obj.keyframes);
                    if (~obj.is_page_in(idx))
                        [page] = obj.swap_page_in(idx);
                    else
                        try
                            [page] = obj.swap_page_in(idx);
                        catch
                            [page] = obj.get_cached_page(idx);
                        end
                    end
            end
            
        end
        function obj = advance_timer(obj)
            obj.timer = obj.timer+1;
        end
        % mikhail: replaced img with img
        function obj = populate_tree_data(obj,nodes,keyframes,desc,img)
            for i = 1:numel(keyframes)
                for j = 1:numel(keyframes{i})
                    keyframe = [];
                    keyframe.num = keyframes{i}(j);
                    if (exist('img','var')&&~isempty(img))
                        keyframe.img = img{i}{j};
                    end
                    keyframe.desc = desc{i}(j,:);
                    obj.setFrame(i,j,keyframe);
                end
                obj.clear_page(i);
            end
        end
        function frame = getFrame(obj,page_id,frame_id)
            if ismember(obj.working_memory.pages_ids,page_id)
                wm_page_id = (obj.working_memory.pages_ids==page_id);
                if (numel(obj.working_memory.pages{wm_page_id})<frame_id)
                    frame = [];
                else
                    frame = obj.working_memory.pages{wm_page_id}{frame_id};
                end
            else
                frame = [];
            end
        end
        function obj = setFrame(obj,page_id,frame_id,frame)
            if (numel(obj.pages_stack)<page_id)
                new_page = {};
                obj.pages_stack{page_id} = new_page;
                obj.swap_page_in(numel(obj.pages_stack));
            end
            if ~ismember(obj.working_memory.pages_ids,page_id)
                obj.swap_page_in(page_id);
            end
            
            wm_page_id = find(obj.working_memory.pages_ids==page_id);
            obj.working_memory.pages{wm_page_id}{frame_id} = frame;
            obj.pages_stack{page_id} = obj.working_memory.pages{wm_page_id};
        end
    end
    
end

% ------------------------------------------------
% reformatted with stylefix.py on 2015/07/29 10:03

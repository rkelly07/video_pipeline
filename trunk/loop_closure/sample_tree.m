% nodes - a tree structure in matlab parent node vector notation
% initial_node the node from which to start, usually the last leaf in the
% tree
% alpha - the parent/children ratio
function [res,vpath]=sample_tree(nodes,initial_node,alpha,keyframes)
v=initial_node;
% alpha=0.1;
previous=inf;
vpath=[v];

if (~exist('keyframes','var'))
    keyframes=[];
end
node_idx=1:numel(nodes);
while(1)
    parent=nodes(v);
    vpath(end+1)=parent;
%     brothers=nodes(brothers);
    %draw=rand(1);
    draw = 0.4;
    if (draw<=alpha) && parent>0 && previous~=-inf
        % go to parent
        previous=v;
        v=parent;
    else
        % go to a time-previous child
        children=(nodes==v);
        children_idx=find(children);
        weights=ones(size(children_idx));
        if (~isempty(keyframes) && ~isempty(weights))
            parent_keyframes=keyframes{v};
            for c=1:numel(children_idx)
                child_keyframes=keyframes{children_idx(c)};
                membership=ismember(child_keyframes,parent_keyframes);
                weights(c)=sum(membership);
            end
            weights=weights+1;
            weights=weights/sum(weights);

        end
        time_previous_children=children;
        if (previous>0) 
            time_previous_children=time_previous_children&node_idx<previous;
        end
        if (sum(time_previous_children)==0)
            res=v;
            vpath(end+1)=v;
            return;
        else
            time_previous_children=find(time_previous_children);
            tpc_idx=ismember(children_idx,time_previous_children);
            nweights=weights(tpc_idx);
            nweights=nweights/sum(nweights);
            p=rand(1);
            cweights=cumsum(nweights);
            idx=sum(p<cweights);
            
%             idx=randperm(numel(time_previous_children),1);
            previous=-inf;
            v=time_previous_children(idx);
        end
    end
end
end
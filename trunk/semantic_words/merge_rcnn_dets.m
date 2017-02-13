function new_dets=merge_rcnn_dets(dets,old_dets,semantic_model,I)
if isempty(old_dets)
    new_dets=dets;
    return;
end
C1=30;
W=diag([1,C1/size(I,2),C1/size(I,1),C1/size(I,2),C1/size(I,1)]);
old_dets2=old_dets(:,1:(end-1))*W;
if (~isempty(dets))
dets2=dets(:,1:(end-1))*W;
else
    dets2=dets;
end

D=pdist2(dets2,old_dets2);
if (~isempty(D))
    % TODO replace with non-fixed threshold
    non_repeating_dets=(min(D,[],1)>semantic_model.new_obj_thresh);
    new_dets=cat(1,dets,old_dets(non_repeating_dets,:));
else
    new_dets=dets;
end
end
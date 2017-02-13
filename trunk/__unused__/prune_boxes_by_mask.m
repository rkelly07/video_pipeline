function boxes=prune_boxes_by_mask(boxes,interference_mask,sampling_rate)
num_boxes=size(boxes,1);
idxs=false(num_boxes,1);
interference_mask=imresize(interference_mask,1/sampling_rate,'bilinear');
for i = 1:num_boxes
    idx1=unique(max(1,min(size(interference_mask,1),round(boxes(i,3)/sampling_rate):round(boxes(i,4)/sampling_rate))));
    idx2=unique(max(1,min(size(interference_mask,2),round(boxes(i,1)/sampling_rate):round(boxes(i,2)/sampling_rate))));
    sample=interference_mask(idx1,idx2);
    if (~any(sample(:)))
    idxs(i)=true;
    end
end
boxes=boxes(idxs,:);
end
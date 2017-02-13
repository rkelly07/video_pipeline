function display_semantic_state(semantic_state,thresh)
if (isfield(semantic_state,'previous_valid_det'))
    dets=semantic_state.previous_valid_det;
else
    dets=semantic_state;
end
for i = 1:size(dets,1);
    if (size(dets,2)>5) && dets(i,6)<0
        continue;
    end
    x1=dets(i,2);y1=dets(i,3);x2=dets(i,4);y2=dets(i,5);rectangle('Position',[x1 y1 x2-x1,y2-y1],'EdgeColor','r');end

end
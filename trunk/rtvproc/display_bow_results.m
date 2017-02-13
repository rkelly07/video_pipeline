load coreset_results
load coreset_tree

%%

num_best_bow = 50;

BOW = coreset_results.BOW;
[~,sorted_idx] = sort(sum(BOW,1),'descend');
best_idx = sorted_idx(1:num_best_bow);

best_bow = BOW(:,best_idx).*255;
[~,xbows] = hist(best_bow(:),50);
figure(2), imshow(best_bow',[xbows(1),xbows(end)])
colormap jet

vq_size = size(BOW,2);

segs = [];
for i = 1:coreset_tree.NumNodes
   
    is_leaf = strcmp(coreset_tree.Data{i}.NodeType,'Leaf');
    
    if is_leaf
       
        for j = 1:length(coreset_results.BOW_Coreset.coresetsList{i}.segments)
            
            segs = [segs coreset_results.BOW_Coreset.coresetsList{i}.segments{j}.t1];
            
        end
        
    end
    
end

skip_frames = 10;
segx = cumsum((segs(2:end)-segs(1:end-1))/skip_frames);

for i = 1:length(segx)
    
    overflow_length = 5;
    line([segx(i) segx(i)],[-overflow_length vq_size+overflow_length],'color','green','LineWidth',2)
    
end

if (~exist('keyframes','var'))
if (false)
    load /media/UNTITLED/onboard_3/flight_results results
nodes=results.coreset_tree_data.nodes;
keyframes=results.coreset_tree_data.key_idx;
desc=coreset_tree_data.desc_coeff;
init_node=55;
else
load /home/rosman/Downloads/coreset_tree_data_75486.mat
nodes=coreset_tree_data.nodes;
keyframes=coreset_tree_data.key_idx;
desc=coreset_tree_data.desc_coeff;
init_node=415;
end
end
res=sample_tree(nodes,init_node,0.9);
votes=zeros(size(nodes));for i=1:1e4;res=sample_tree(nodes,init_node,0.5,keyframes);votes(res)=votes(res)+1;end
figure
semilogy(1+votes);xlabel('node number');ylabel('samples')
figure
treeplot(nodes)
lc=LoopClosure;
lc.populate_tree_data(nodes,keyframes,desc);
additional_data=[];additional_data.tree_nodes=nodes;additional_data.init_node=init_node;
comparison_measure='l2';
example=[];example.desc=coreset_tree_data.desc_coeff{init_node}(:,end);
example.num=keyframes{init_node}(end);
%%
mincost=inf;
idxs=[];
for t=1:2000
lc.advance_timer();
[page,idx]=lc.swap_random_page('tree',additional_data);
idxs(t)=idx;
res=compare_page_closure(page,example,comparison_measure);
[yy,ii]=min(res.costs);
if (yy<mincost)
    minidx=ii;
    minpage=idx;
    mincost=yy;
end
% res=lc.getFrame(idx,1);
end
if (false)
    load /media/UNTITLED/onboard_3/flight_results results
nodes=results.coreset_tree_data.nodes;
keyframes=results.coreset_tree_data.key_idx;
init_node=55;
else
load /home/rosman/Downloads/coreset_tree_data_75486.mat
nodes=coreset_tree_data.nodes;
keyframes=coreset_tree_data.key_idx;
init_node=415;
end
res=sample_tree(nodes,init_node,0.9);
votes=zeros(size(nodes));for i=1:1e5;res=sample_tree(nodes,init_node,0.5);votes(res)=votes(res)+1;end
figure
semilogy(1+votes);xlabel('node number');ylabel('samples')
figure
treeplot(nodes)

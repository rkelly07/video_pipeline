
nodes= [3 3 0];
init_node=3;
keyframes = cell(1, 3);
keyframes{1} = [15,  32,  41,  50,  57,  72,  88,  95, 100]; 
keyframes{2} = [108, 118, 130, 143, 150];
keyframes{3} =[ 15,  41,  50,  57,  72,  88, 108, 130, 150];

%keyframes = 
[res, vpath]=sample_tree(nodes,init_node,0.5, keyframes);
votes=zeros(size(nodes));for i=1:1e5;res=sample_tree(nodes,init_node,0.5);votes(res)=votes(res)+1;end
figure
semilogy(1+votes);xlabel('node number');ylabel('samples')
figure
treeplot(nodes)
function last_node = find_last_node(coreset_tree)

last_node = 1;
for i = 1:coreset_tree.NumNodes
   
    if strcmp(coreset_tree.Data{i}.NodeType,'Leaf')
        last_node = i;
    end
    
end

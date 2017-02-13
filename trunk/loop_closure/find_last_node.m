function idx=find_last_node(coreset_tree)
% avg=-inf;
% for i=1:numel(coreset_tree.Data)
    [~,idx]=max(mean(coreset_tree.T12,2))
% end
end
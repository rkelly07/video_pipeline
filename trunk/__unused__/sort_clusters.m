%% sort clusters
function [new_idx,new_ctrs] = sort_clusters(X,k,idx,ctrs)

% sort by cluster mean
cluster_means = zeros(k,2);
for j = 1:k
  cluster_means(j,:) = mean(X(idx==j,:),1);
end
[~,cluster_order] = sort(cluster_means);

% reorder ids and centers
swap_idx = zeros(size(idx));
swap_ctrs = zeros(size(ctrs));
for j = 1:k
%   idx(idx==j) = cluster_order(j)+k;
  swap_idx(idx==j) = cluster_order(j);
  swap_ctrs(j,:) = ctrs(cluster_order(j),:);
end

% new_idx = idx-k;
new_idx = swap_idx;
new_ctrs = swap_ctrs;


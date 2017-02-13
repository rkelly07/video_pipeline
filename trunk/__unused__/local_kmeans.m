% local kmeans
function output = local_kmeans(X,k)

tic
[idx,ctrs] = kmeans(X,k);
local_runtime = toc

% sort clusters
% [idx,ctrs] = sort_clusters(X,k,idx,ctrs);

% plot local kmeans
% figure(401)
% plot_kmeans(X,k,idx,ctrs,'local k-means')

output.Idx = idx;
output.Ctrs = ctrs;
output.Runtime = local_runtime;


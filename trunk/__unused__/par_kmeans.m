% parallel kmeans
function output = par_kmeans(X,k,n)

m = length(X);
Xc = chunk_input(X,m,n);

par_idx = cell(1,n);
par_ctrs = cell(1,n);

tic
parfor i = 1:n
  Xi = Xc(:,:,i);
  [par_idx{i},par_ctrs{i}] = kmeans(Xi,k);
end
par_runtime = toc

% sort clusters
% for i = 1:n
%   [par_idx{i},par_ctrs{i}] = sort_clusters(Xc(:,:,i),k,par_idx{i},par_ctrs{i});
% end

% plot distributed kmeans
% figure(402)
% for i = 1:n
%   subplot(2,2,i)
%   plot_kmeans(Xc(:,:,i),k,par_idx{i},par_ctrs{i},['cluster ' num2str(i)])
% end

% merge clusters
% disp('Merging clusters ...')
% par_idx_cat = [];
% par_ctrs_cat = [];
% for i = 1:n
%   par_idx_cat = cat(1,par_idx_cat,par_idx{i});
%   par_ctrs_cat = cat(1,par_ctrs_cat,par_ctrs{i});
% end
% disp('Done!')
% 
% % plot recomposed distributed kmeans
% figure(403)
% plot_kmeans(X,k,par_idx_cat,par_ctrs_cat,'merged distributed k-means')

output.Idx = par_idx;
output.Ctrs = par_ctrs;
output.Runtime = par_runtime;


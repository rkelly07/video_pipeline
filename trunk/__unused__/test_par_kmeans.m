% test par kmeans

% cluster = parcluster('local')
% cluster = parcluster('mikhail_cc2x16')
% cluster = parcluster('mikhail_cc2x256')

params.NumWorkers = 12;
params.NumPoints = 12e6;
params.NumKMeans = 2;
params

%%
n = params.NumWorkers;
m = params.NumPoints;
k = params.NumKMeans;

% create data
X = [randn(m/2,2)+2*ones(m/2,2); randn(m/2,2)-2*ones(m/2,2)];
X = X(randperm(m),:);

%% local kmeans
disp(repmat('-',1,80))

disp('Computing local kmeans ...')
% [idx,ctrs,local_runtime] = local_kmeans(X,k);
job1 = batch(cluster,'local_kmeans',1,{X,k},'Matlabpool',n-1)
wait(job1)
job1.diary
local_output = fetchOutputs(job1);
disp('Done!')

idx = local_output{1}.Idx;
ctrs = local_output{1}.Ctrs;

%% parallel kmeans
disp(repmat('-',1,80))

disp('Computing parallel kmeans ...')
% [par_idx,par_ctrs,par_runtime] = par_kmeans(X,k,n);
job2 = batch(cluster,'par_kmeans',1,{X,k,n},'Matlabpool',n-1, ...
  'AttachedFiles','chunk_input')
wait(job2)
job2.diary
par_output = fetchOutputs(job2);
disp('Done!')

par_idx = par_output{1}.Idx;
par_ctrs = par_output{1}.Ctrs;

Xc = chunk_input(X,m,n);

%% plot results

figure(401)
plot_kmeans(X,k,idx,ctrs,'title','local kmeans');

figure(402)
for i = 1:n
  subplot(n/ceil(sqrt(n)),n*ceil(sqrt(n))/n,i)
  plot_kmeans(Xc(:,:,i),k,par_idx{i},par_ctrs{i},'legend','off')
end


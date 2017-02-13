profile off;profile on;
N=40000;
dim=64;
randn('seed',0);
rand('seed',0);
X=randn(N,dim);
weights=ones(N,1);
k=5000;
randn('seed',0);
rand('seed',0);
tic
features_vec=weighted_kmeans(X,weights,k,true);
toc
randn('seed',0);
rand('seed',0);
tic
features_vec=weighted_kmeans(X,weights,k,false);
toc

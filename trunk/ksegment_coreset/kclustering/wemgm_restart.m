function [label, model, llh, nIterations] = wemgm_restart(X, weights, init, n)
% wemgm_restart - Wrapper for wemgm, that performs multiple runs of wemgm
% and selects the best model.
%
% Input:
%   X - d x n data matrix
%   weights - 1 x n vector of nonnegative weights
%   init - k (1 x 1) or label (1 x n, 1<=label(i)<=k) or center (d x k)
%   n - number of runs of wemgm
%
% Outputs:
%   label - 
%   model -
%   llh - 
%   nIterations - number of iterations used by emgm before the return model
%       converged (or wemgm gave up).

labels = cell(1,n);
models = cell(1,n);
llhs = zeros(1,n);
nItersToConverge = zeros(1,n);

for iter = 1:n
    [labels{iter},models{iter},llhtmp, t]=wemgm(X, weights, init);
    llhs(iter)=llhtmp(end);
    nItersToConverge(iter) = t;
end

[~,best]=max(llhs);
label = labels{best};
model = models{best};

%llhs
llh = llhs(best);
nIterations = nItersToConverge(best);

function [label, model, llh, nIterations] = wemgm(X, weights, init, vis)
% Perform EM algorithm for fitting the Gaussian mixture model on a weighted data set.
% 
% Input:
%   X - d x n data matrix
%   weights - 1 x n vector of nonnegative weights
%   init - k (1 x 1) or label (1 x n, 1<=label(i)<=k) or center (d x k)
%   vis - true to visualize
%
% Outputs:
%   label - 
%   model -
%   llh - 
%
% Written by Michael Chen (sth4nth@gmail.com).
%% initialization

if ~exist('vis','var')
    vis = false;
end

fprintf('EM for Gaussian mixture: running ... \n');
R = initialization(X, weights, init);
[~,label(1,:)] = max(R,[],2);
R = R(:,unique(label));

tol = 1e-6;
maxiter = 500;
llh = -inf(1,maxiter);
converged = false;
t = 1;
while ~converged && t < maxiter
    if vis
        hold off
        nw = max(weights,1e-6)/max(weights);
        scatter(X(1,:),X(2,:),nw*20);
        hold on    
    end
    
    t = t+1;
    model = maximization(X,weights,R);    
    [R, llh(t)] = expectation(X,weights,model);
    if vis
        for i = 1:size(model.Sigma,3)
            h=PlotEllipse(model.Sigma(:,:,i),model.mu(:,i));
            set(h,'color','k');
        end
    end

    
    [~,label(1,:)] = max(R,[],2);
    idx = unique(label);   % non-empty components
    if size(R,2) ~= size(idx,2)
        R = R(:,idx);   % remove empty components
    else
        converged = llh(t)-llh(t-1) < tol*abs(llh(t));
    end
    
    if vis
        pause
    end

end
llh = llh(2:t);
if converged
    fprintf('Converged in %d steps.\n',t-1);
else
    fprintf('Not converged in %d steps.\n',maxiter);
end
nIterations = t-1;

function R = initialization(X, weights, init)
[d,n] = size(X);
if isstruct(init)  % initialize with a model
    R  = expectation(X,init);
elseif length(init) == 1  % random initialization
    k = init;
%    idx = randsample(n,k);
    idx = randsample(n,k, true, 1./weights);
    m = X(:,idx);
    [~,label] = max(bsxfun(@minus,m'*X,sum(m.^2,1)'/2),[],1);
    while k ~= unique(label)
        idx = randsample(n,k);
        m = X(:,idx);
        [~,label] = max(bsxfun(@minus,m'*X,sum(m.^2,1)'/2),[],1);
    end
    R = full(sparse(1:n,label,1,n,k,n));
elseif size(init,1) == 1 && size(init,2) == n  % initialize with labels
    label = init;
    k = max(label);
    R = full(sparse(1:n,label,1,n,k,n));
elseif size(init,1) == d  %initialize with only centers
    k = size(init,2);
    m = init;
    [~,label] = max(bsxfun(@minus,m'*X,sum(m.^2,1)'/2),[],1);
    R = full(sparse(1:n,label,1,n,k,n));
else
    error('ERROR: init is not valid.');
end

function [R, llh] = expectation(X, weights, model)
mu = model.mu;
Sigma = model.Sigma;
w = model.weight;

n = size(X,2);
k = size(mu,2);
logR = zeros(n,k);

for i = 1:k
    logR(:,i) = loggausspdf(X,mu(:,i),Sigma(:,:,i));
end
logR = bsxfun(@plus,logR,log(w));
T = logsumexp(logR,2);
llh = (weights*T)/sum(weights); % loglikelihood
logR = bsxfun(@minus,logR,T);
R = exp(logR);


function model = maximization(X, weights,parR)
if (weights(1)~=1)
    1;
end
[d] = size(X,1);
n = sum(weights);
k = size(parR,2);
R = (max(weights,1e-6)'*ones(1,k)).*parR;
Rrt = (sqrt(max(weights,1e-6))'*ones(1,k)).*parR;

s = sum(R,1);
srt = sum(Rrt,1);
w = s/n;
mu = bsxfun(@times, X*R, 1./s);
Sigma = zeros(d,d,k);
for i = 1:k
    Xo = bsxfun(@minus,X,mu(:,i));
    Xo = bsxfun(@times,Xo,sqrt(R(:,i)'));
    Sigma(:,:,i) = Xo*Xo'/s(i);
    Sigma(:,:,i) = Sigma(:,:,i)+eye(d)*(1e-3); % add a prior for numerical stability
end

model.mu = mu;
model.Sigma = Sigma;
model.weight = w;

function y = loggausspdf(X, mu, Sigma)
d = size(X,1);
X = bsxfun(@minus,X,mu);
[R,p]= chol(Sigma);
if p ~= 0
    error('ERROR: Sigma is not PD.');
end
q = sum((R'\X).^2,1);  % quadratic term (M distance)
c = d*log(2*pi)+2*sum(log(diag(R)));   % normalization constant
y = -(c+q)/2;

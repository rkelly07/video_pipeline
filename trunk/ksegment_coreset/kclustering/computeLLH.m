function [llh,R,label] = computeLLH(X, model)
% computeLLH - Perform EM algorithm for fitting the Gaussian mixture model 
% on a weighted data set.
%
% Inputs:
%   X - (d x n) matrix. Each column is a data point.
%   model - GMM struct, with the following fields:
%       mu - (d x k) matrix
%       Sigma - (d x d x k) matrix
%       weight - (1 x k)
%
% Outputs:
%   llh - scalar. Log likelihood of all data points under model
%   R - (n x k) matrix
%   label - 
%
% Based on code by Michael Chen (sth4nth@gmail.com).

weights = ones(1,size(X,2));
[R, llh] = expectation(X,weights,model);

[~,label] = max(R,[],2);
idx = unique(label);   % non-empty components


function [R, llh] = expectation(X, weights, model)
% Inputs:
%   X - (d x n) matrix. Each column is a data point.
%   weights - (1 x n) vector of data point weights.
%   model - GMM, with the following fields:
%       mu - (d x k) matrix
%       Sigma - (d x d x k) matrix
%       weight - (1 x k)
%
% Outputs:
%   R
%   llh
%
mu = model.mu; 
Sigma = model.Sigma; 
w = model.weight; 

n = size(X,2);
k = size(mu,2);
logR = zeros(n,k);

for i = 1:k
    logR(:,i) = loggausspdf(X,mu(:,i),Sigma(:,:,i));
end
% disp('size of logR:')
% size(logR)
% disp('size of log(w):')
% size(log(w))
logR = bsxfun(@plus,logR,log(w));
T = logsumexp(logR,2);
llh = (weights*T)/sum(weights); % loglikelihood
logR = bsxfun(@minus,logR,T);
R = exp(logR);


function model = maximization(X, weights,R)
[d] = size(X,1);
n = sum(weights);
k = size(R,2);
R = (max(weights,1e-6)'*ones(1,k)).*R;

s = sum(R,1);
w = s/n;
mu = bsxfun(@times, X*R, 1./s);
Sigma = zeros(d,d,k);
for i = 1:k
    Xo = bsxfun(@minus,X,mu(:,i));
    Xo = bsxfun(@times,Xo,sqrt(R(:,i)'));
    Sigma(:,:,i) = Xo*Xo'/s(i);
    Sigma(:,:,i) = Sigma(:,:,i)+eye(d)*(1e-6); % add a prior for numerical stability
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

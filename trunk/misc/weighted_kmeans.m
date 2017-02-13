% X is  num_examples x dim
% weights is num_examples x 1
function [descriptor_representatives,descriptor_weights,stats]=weighted_kmeans(descriptors_i,weights,k,use_gpu,descriptor_representatives)
dim=size(descriptors_i,2);
N=size(descriptors_i,1);
if (~exist('descriptor_representatives','var'))
descriptor_representatives=randn(k,dim)*diag(std(descriptors_i));
end
descriptor_weights=ones(k,1);
if (~exist('use_gpu','var'))
    use_gpu=false;
end
stats=[];
% use_gpu=true;
old_residual=inf;
MAX_ITER=60;
MIN_CHANGE=1e-5;
for iter=1:MAX_ITER
    if (use_gpu)
        knn_idx=find_NN_CPUGPU(descriptors_i',descriptor_representatives');
    else
        knn_idx=find_NN_CPU2(descriptors_i',descriptor_representatives');
    end
    residual=0;
   parfor i=1:k
%     for i=1:k
        idx=knn_idx==i;
        if (sum(idx)==0)
            new_i=randperm(N,1);
            newrep=descriptors_i(new_i,:);
            newweight=1;
        else
            newrep=weights(idx)'*descriptors_i(idx,:)/sum(weights(idx));
            newweight=sum(weights(idx));
        end
        residual=residual+sum((newrep-descriptor_representatives(i,:)).^2);
        descriptor_representatives(i,:)=newrep;
        descriptor_weights(i)=newweight;
   end
%     dresidual=old_residual-residual;
%     old_residual=residual;
%     disp(residual)
    if (residual<MIN_CHANGE)
        break;
    end
end
if (nargin>2)
    err=0;
    
    for i=1:k
        idx=knn_idx==i;
        rep=descriptor_representatives(i,:);
        w=weights(idx);
        e=sum((bsxfun(@minus,descriptors_i(idx,:),rep)).^2,2);
        err=err+sum(w(:).*e(:));
    end  
    stats.err=err/sum(weights);
    stats.knn_idx=knn_idx;
end

stats.residual=residual;
end
function knn_idx=find_NN_CPUGPU(descriptors_i,descriptor_representatives)
descriptors_i=gpuArray(single(descriptors_i));
descriptor_representatives=gpuArray(single(descriptor_representatives));
aa=sum(descriptors_i.*descriptors_i); bb=sum(descriptor_representatives.*descriptor_representatives); ab=descriptors_i'*descriptor_representatives; 

pdists = (repmat(aa',[1 size(bb,2)]) + repmat(bb,[size(aa,2) 1]) - 2*ab);

% pdists=bsxfun(@minus,s1s2,2*descriptors_i*descriptor_representatives');
%       pdists = pdist2(single(descriptors_i),single(descriptor_representatives));
[~,knn_idx] = (min(pdists,[],2));
%       features_vec = hist(knn_idx,NumFeatureClusters);
%       features_vec=features_vec/max(1,sum(features_vec));
end
function knn_idx=find_NN_CPU2(descriptors_i,descriptor_representatives)
descriptors_i=(single(descriptors_i));
descriptor_representatives=(single(descriptor_representatives));

dmin=1e20*ones(size(descriptors_i,2),1);
knn_idx=-1*ones(size(dmin));
STEPSIZE=100;

for i=1:STEPSIZE:size(descriptor_representatives,2)
    rep_idx=unique(min(i-1+(1:STEPSIZE),size(descriptor_representatives,2)));
    descriptor_representatives2=descriptor_representatives(:,rep_idx);
aa=sum(descriptors_i.*descriptors_i); bb=sum(descriptor_representatives2.*descriptor_representatives2); ab=descriptors_i'*descriptor_representatives2; 
pdists = (repmat(aa',[1 size(bb,2)]) + repmat(bb,[size(aa,2) 1]) - 2*ab);

[dmin2,knn_idx2] = (min(pdists,[],2));
changed=dmin2<dmin;
dmin(changed)=dmin2(changed);
knn_idx(changed)=knn_idx2(changed)+i-1;
end
end
function knn_idx=find_NN_CPU(descriptors_i,descriptor_representatives)
NumFeatureClusters=size(descriptor_representatives,1);

pdists = pdist2(single(descriptors_i),single(descriptor_representatives));
[~,knn_idx] = (min(pdists,[],2));
%       features_vec = hist(knn_idx,NumFeatureClusters);
%       features_vec=features_vec/max(1,sum(features_vec));
end
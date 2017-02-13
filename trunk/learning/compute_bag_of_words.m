function [bow,stats]=compute_bag_of_words(Ds,descriptor_representatives)
% Ds=[];
stats=[];
% parfor i=1:numel(object_Ds)
%     Ds(:,i)=object_Ds{i}.Descriptor;
% end
if (numel(Ds)==0)
    bow=zeros(size(descriptor_representatives,1),1);
    stats.sum=0;
else
dists=pdist2(double(Ds'),double(descriptor_representatives));[~,ii]=min(dists,[],2);bow=hist(ii,1:size(descriptor_representatives,1));
stats.sum=sum(bow);
bow=bow/sum(bow);
end
end
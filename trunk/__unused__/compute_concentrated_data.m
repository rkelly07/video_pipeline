function data2=compute_concentrated_data(bags_of_words,initial_length,num_channels,clusters)
[~,midx]=sort(sum(bags_of_words(1:initial_length,:)'.^2,2),'descend');
data=imfilter(medfilt1(bags_of_words(:,midx(1:num_channels)),15)',ones(1,15)/15,'replicate');
% clusters={activity1,activity2,activity3};
if (exist('clusters','var') && ~isempty(clusters))
res=construct_reweighting_matrix(data,clusters);
data2=res*data*100;
else
    data2=bags_of_words*100;
end

% data3=data2(:,1:end);
end
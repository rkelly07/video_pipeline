% load('/media/My Passport/Data/VOCdevkit_processed/VOC_descriptors_1_6000.mat')
% load('/media/My Passport/Data/VOCdevkit_processed/VOC_descriptors_1_400.mat')
%load('/media/My Passport/Data/VOCdevkit_processed/VOC_descriptors_401_3000.mat')
% data_mat=zeros(numel(D_saved),size(D_saved{1}.Descriptor,2));
% labels=zeros(numel(D_saved),1);
% object_id=zeros(numel(D_saved),1);
% tic
% for i = 1:numel(D_saved)
%     data_mat(i,:)=D_saved{i}.Descriptor;
%     object_id(i)=D_saved{i}.UniqueID;
%     % labels(i)=D_saved{i}.Class;
% end
% toc
% %%
% load ../process_video/streamOut_1000.mat descriptor_representatives
% %%
% bags_of_words=zeros(size(descriptor_representatives,1),max(object_id));
% labels=zeros(max(object_id),1);
% tic
% for i = 1:max(object_id)
%     obj_descriptors=data_mat(object_id==i,:);
%     
%     labels(i)=D_saved{find(object_id==i,1,'first')}.Class;
%     D=pdist2(double(obj_descriptors),double(descriptor_representatives));
%     [yy,ii]=(min(D,[],2));
%     %         bow_vec=false(size(descriptor_representatives,1),1);
%     bow_vec=hist(ii,1:size(descriptor_representatives,1));
%     % todo: handle multiple repetitions of words/descriptors in the same frame
%     %         bow_vec(ii)=true;
%     bags_of_words(:,i)=bow_vec;
%     
% end
% toc
% clear D_saved;

% classifiers={};
regressors={};
tic;
% STEP=2;
% idx=false(size(bags_of_words,2),1);
% idx(ceil(1:STEP:end))=true;
thresh=min(0.7,2000/size(bags_of_words,2));
idx=rand(size(bags_of_words,2),1)<thresh;

for i=1:max(labels)
%     regressors{i} = classregtree(bags_of_words(:,idx)',double(labels(idx)==i),'method','regression');
%     labels3=regressors{i}.eval((bags_of_words(:,:)'))';
    classifiers{i} = svmtrain(bags_of_words(:,idx),labels(idx)==i,'showplot',false,'kernel_function','linear','options',struct('Display','off','MaxIter',500000));
    labels2=svmclassify(classifiers{i},bags_of_words')';
    err(i)=mean(abs(double(labels2(~idx))-double(labels(~idx)==i)));
%     err2(i)=mean(abs(double(labels3(~idx))-double(labels(~idx)==i)));
disp([err(i)])
%     disp([err(i),err2(i)])
end

toc


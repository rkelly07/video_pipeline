function semantic_bow=generate_semantic_cues(I,boxes,features,points,classifiers,descriptor_representatives)
if (isempty(boxes))
boxes=generate_boxes(I);
else
    boxes2=boxes;
    boxes={};
    for i =1:size(boxes2,1)
        boxes{i}=boxes2(i,1:4);
    end
end
semantic_bow=[];
labels=get_cluster_labels(features,descriptor_representatives);
% bag_of_words=construct_bag_of_words(features,descriptor_representatives);
for b=1:numel(boxes)
    [labels2,points2]=extract_features_in_box(labels,points,I,boxes{b});
    bag_of_words=construct_bag_of_words(labels2,descriptor_representatives);
    for i = 1:length(classifiers)
        if (isa(classifiers{i},'classregtree')) %&& isfield(classifiers{i},'SupportVectors'))
            semantic_bow(b,i)=classifiers{i}.eval((bag_of_words(:)'));
        else
        semantic_bow(b,i)=svmclassify(classifiers{i},bag_of_words);
        end
    end
end
semantic_bow=sum(semantic_bow,1);
end

function boxes=generate_boxes(I)
boxes={};
boxes{end+1}=[0 0 size(I,2) size(I,1)];
boxes{end+1}=[0 0 size(I,2)/2 size(I,1)/2];
boxes{end+1}=[size(I,2)/2 0 size(I,2) size(I,1)/2];
boxes{end+1}=[0 size(I,1)/2 size(I,2)/2 size(I,1)/2];
boxes{end+1}=[size(I,2)/2 size(I,1)/2 size(I,2) size(I,1)];
boxes{end+1}=[size(I,2)/4 size(I,1)/4 size(I,2)*3/4 size(I,1)*3/4];
end

function [features2,points2]=extract_features_in_box(features,points,I,box)
idx=points.Location(:,1)>=box(1)&points.Location(:,2)>=box(2)&points.Location(:,1)<box(3)&points.Location(:,2)<box(4);
features2=features(idx,:);
points2=points(idx);
end

function ii=get_cluster_labels(features,descriptor_representatives)
D=pdist2(features,descriptor_representatives);
[~,ii]=(min(D,[],2));
end

function bow_vec=construct_bag_of_words(cluster_labels,descriptor_representatives)
%         bow_vec=false(size(descriptor_representatives,1),1);
bow_vec=hist(cluster_labels,1:size(descriptor_representatives,1));
bow_vec=bow_vec/(sum(bow_vec)+1);
end
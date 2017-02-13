function data1=compute_processed_bow(data1,INITIAL_VIDEO,DIM,clusters)
[~,midx]=sort(sum(data1.bags_of_words(1:INITIAL_VIDEO,:)'.^2,2),'descend');
data1.data2=imfilter(medfilt1(data1.bags_of_words(:,midx(1:DIM)),15)',ones(1,15)/15,'replicate');
K=100;
a = 100;
b=2;
c = 0.5;

ksegment_corest_alg = KSegmentCoresetAlg();
ksegment_corest_alg.a=a;
ksegment_corest_alg.b=b;
ksegment_corest_alg.c=c;
ksegment_corest_alg.w=0.999;
if (exist('clusters','var'))
%     clusters={activity1,activity2,activity3};
res=construct_reweighting_matrix(data1.data2,clusters);
data1.data2=res*data1.data2;
end
P = SignalPointSet(data1.data2',1:size(data1.data2,2));
data1.ksegment_coreset = ksegment_corest_alg.computeCoreset(P);
data1.ts=[];
for i=1:numel(data1.ksegment_coreset.segments)
    data1.ts(end+1)=data1.ksegment_coreset.segments{i}.t1;
end
end
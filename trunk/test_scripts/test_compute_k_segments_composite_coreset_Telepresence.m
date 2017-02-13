profile off;profile on
load data/TelepresenceRobot_Video_results.mat
profile off;profile on
activity1 =[  243   289   335];
activity2 =[ 540   561   582   614];
activity3 =[   706   724   773];
[~,midx]=sort(sum(bags_of_words(1:400,:)'.^2,2),'descend');
data=imfilter(medfilt1(bags_of_words(:,midx(1:300)),15)',ones(1,15)/15,'replicate');
clusters={activity1,activity2,activity3};
res=construct_reweighting_matrix(data,clusters);
data2=res*data*100;
data3=data2(:,1:end);
A=LinearSegmentComputation(data3');
K=100;
a = 200;
b=2;
c = 0.05;

ksegment_corest_alg = KSegmentCoresetAlg();
ksegment_corest_alg.a=a;
ksegment_corest_alg.b=b;
ksegment_corest_alg.c=c;
P = SignalPointSet(data3',1:size(data3,2));
D = ksegment_corest_alg.computeCoreset(P);

res=compute_k_segments_composite_coresets(D,K);
%%

xshift=15;
ts=[];
close all;image(data3)
labs=zeros(size(data3(1,:)));
%% For k-segment:
f=res.fs{30}{end};
for i = 1:numel(f);try;x=f{i}.t2;labs(round(x))=1;hold on;h=plot(x*[1 1],[1 size(data2,1)],'k-');set(h,'LineWidth',3);hold off;ts(end+1)=x;catch;end;end
%% For bicriteria over-segmentation:
% f=D.segments;
% for i = 1:numel(f);try;x=f{i}.t2;labs(round(x))=1;hold on;h=plot(x*[1 1],[1 size(data2,1)],'k-');set(h,'LineWidth',3);hold off;catch;end;end
labs=cumsum(labs);




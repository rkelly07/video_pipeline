profile off;profile on
load data/video1_results.mat
profile off;profile on
[~,midx]=sort(sum(bags_of_words(1:400,:)'.^2,2),'descend');
data=imfilter(medfilt1(bags_of_words(:,midx(1:300)),15)',ones(1,15)/15,'replicate');
% clusters={activity1,activity2,activity3};
res=construct_reweighting_matrix(data,clusters);
data2=res*data*100;
data3=data2(:,1:end);
A=LinearSegmentComputation(data3');
K=30;
a = 100;
b=2;
c = 0.2;

ksegment_corest_alg = KSegmentCoresetAlg();
ksegment_corest_alg.a=a;
ksegment_corest_alg.b=b;
ksegment_corest_alg.c=c;
P = SignalPointSet(data3',1:size(data3,2));
D = ksegment_corest_alg.computeCoreset(P);

res=compute_k_segments_composite_coresets(D,K);
% s=1;plot3(res.f{end-1}{s}.boundaries,res.f{end-1}{s}.opt_param(1)*ones(2,1),res.f{end-1}{s}.opt_param(2)*ones(2,1),'-')
% for s=2:K;hold on;plot3(res.f{end-1}{s}.boundaries,res.f{end-1}{s}.opt_param(1)*ones(2,1),res.f{end-1}{s}.opt_param(2)*ones(2,1),'-');hold off
% end
% axis image
% hold on;plot3(1:size(X,1),X(:,1),X(:,2),'.');hold off
%%
close all;image(data3)
labs=zeros(size(data3(1,:)));
f=res.fs{end}{end};
for i = 1:numel(f);x=f{i}.t2;labs(round(x))=1;hold on;h=plot(x*[1 1],[1 size(data2,1)],'k-');set(h,'LineWidth',3);hold off;end
labs=cumsum(labs);
% processed_frame_idx2=processed_frame_idx(1:4:1800);


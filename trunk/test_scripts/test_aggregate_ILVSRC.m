profile off;profile on
data_dir='/media/My Passport/Data/ILVSRC2012/';
% update_classifiers=@(res,descriptors,labels,unique_id)online_classifier_update(res,descriptors,labels,unique_id,descriptor_representatives);

% update_kmeans_coreset=@(F)update_kmeans_coreset(res,F);
% res=collect_ILVSRC_BOWs(data_dir,1,1,20000,{update_classifiers,update_kmeans_coreset});
N_workers=200;
res=cell(N_workers,1);
%%
do_over=[];
for i=1:N_workers;do_over(i)=~(isfield(res{i},'spmd_feature_coreset'));end
parfor i=1:N_workers
    disp(i)
    res{i}.VERBOSE_IMAGE=false;
    if (do_over(i))
res{i}=collect_ILVSRC_BOWs(res{i},data_dir,N_workers,i,1200,{@update_kmeans_coreset});
    end
end
save tmp_test_aggregate_ILVSRC
wpts=[];pts=[];num_points=0;
for i=1:numel(res);
    if (~isempty(res{i}) && isfield(res{i},'spmd_feature_coreset'))
    cs=res{i}.spmd_feature_coreset.getUnifiedCoreset();
    num_points=num_points+res{i}.spmd_feature_coreset.numPointsStreamed;
    pts=[pts;cs.M.getRawMatrix()];wpts=[wpts;cs.W.getRawMatrix()];
    end
end;
save tmp_test_aggregate_ILVSRC_final

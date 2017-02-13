profile off;profile on
data_dir='/media/My Passport/Data/ILVSRC2012/';
% res2=[];
load descriptor_representatives_66 descriptor_representatives
update_classifiers=@(res,descriptors,labels,unique_id)online_classifier_update(res,descriptors,labels,unique_id,descriptor_representatives);
res=struct('train_params',struct('learning_rate',5e-2,'net_topology',[ 30 10],'epochs',50));
% update_kmeans_coreset=@(F)update_kmeans_coreset(res,F);
avg_perfs=[];performances=[];
res.VERBOSE_IMAGE=false;
res.cache_files_dir='/media/My Passport/Data/ILVSRC2012/cache2';
%%
BATCH_SIZE=1000;
N=5;
topology_name=[];
for i = 1:numel(res.train_params.net_topology)
    topology_name=[topology_name,num2str(res.train_params.net_topology(i))];
    if (i<numel(res.train_params.net_topology))
        topology_name=[topology_name,'_'];
    end
end
repetitions=200;
for i=1:(N*repetitions)
    disp(i)
%     res=collect_ILVSRC_BOWs(res,data_dir,N,mod(N-i+ceil(N/4),N)+1,1000,{update_classifiers});
    res=collect_ILVSRC_BOWs(res,data_dir,N,mod(i-1,N)+1,BATCH_SIZE,{update_classifiers});
    performances=[performances,mean(res.performances)];
    disp(['Average performance over all classifiers: ',num2str(mean(res.performances))])
    wnd_start=max(1,numel(performances)-N);
    avg_perfs(end+1)=(mean(performances(wnd_start:end)));
    plot(avg_perfs);drawnow;
    title(sprintf('%s',['N=',num2str(N),', ',num2str(numel(res.labels_map.keys)),' labels, BATCH_SIZE = ',num2str(BATCH_SIZE),' topology= ',topology_name]),'Interpreter', 'none');
    if(mod(i-1,N)==0)
        save(['res_test_aggregate_ILVSRC2_',num2str(N),'_',num2str(BATCH_SIZE),'_',num2str(res.train_params.learning_rate),'_',topology_name,'.mat']);
    end
end
% res={};
% parfor i=1:8
% res{i}=collect_ILVSRC_BOWs(data_dir,60,i,20000000,{@update_kmeans_coreset});
% end

% wpts=[];pts=[];
% for i=1:numel(res);
%     cs=res{i}.spmd_feature_coreset.getUnifiedCoreset();
%     pts=[pts;cs.M.getRawMatrix()];wpts=[wpts;cs.W.getRawMatrix()];
% end;
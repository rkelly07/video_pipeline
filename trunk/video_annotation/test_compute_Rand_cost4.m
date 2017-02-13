user_files_list={'20130711110654.AVI_annotation_guy.mat','20130711110654.AVI_annotation_guy2.mat'};
coreset_files_list={'../../data/KANE0302_20130711110654_results.mat','../../data/KANE0302_20130805093412_results.mat'};
labs={};
for i = 1:numel(user_files_list)
    load(user_files_list{i})
    labs{i}=userdata.labels;
end
for i = 1:numel(coreset_files_list)
    load(coreset_files_list{i});
    segments=spmd_semantic_coreset.getUnifiedCoreset().T12;segments=[segments(:,1);segments(end,2)];
    sstep=(max(segments)-min(segments))/(max(1,numel(segments)-1));
    uniform_segments=min(segments):sstep:max(segments);
%     labs={labs{1}};
    res=compute_Rand_cost(segments,labs,video_filename);
    ures=compute_Rand_cost(uniform_segments,labs,video_filename);
    disp([video_filename,': ',num2str(res.score),'/',num2str(res.cnt),' vs. ',num2str(ures.score),'/',num2str(ures.cnt)]);
    
end
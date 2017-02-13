function res=collect_labels_data(userdata)
% max_frames=100;
fprintf('Loading images..');
load descriptor_representatives_66;
VQs=single(descriptor_representatives(:,1:66));
h=mex_video_processing('init',userdata.filename,VQs);
% vs=[];
% for j=1:start_frame
%     mex_video_processing('skipframe',h);
% end
res.images=[];
res.frame_idxs=[];res.labels=[];
res.vs=[];
prime_number=5000011;

for i=1:numel(userdata.labels)
    res.frame_idxs(end+1)=userdata.labels{i}.frame;
    res.labels(end+1)=simple_hash(userdata.labels{i}.label{1},prime_number);
end
max_frame=max(res.frame_idxs);
cnt=1;
for i=1:max_frame;
    if (ismember(i,res.frame_idxs))
    try
        [v,img,~]=mex_video_processing('newframe',h);
        if (isempty(res.images))
            res.images=zeros(size(img,1),size(img,2),3,numel(res.frame_idxs));
        end
        res.images(:,:,:,cnt)=double(img)/255;
        res.vs(:,cnt)=v;
        cnt=cnt+1;
    catch
        break
    end
    else
        mex_video_processing('skipframe',h);
    end
end
mex_video_processing('deinit',h);
fprintf(' Done\n');
end
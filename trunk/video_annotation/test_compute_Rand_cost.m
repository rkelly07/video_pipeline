load saved_userdata
load coreset_example D
val=saved_userdata.labels.values;
key=saved_userdata.labels.keys;
key=key{1};
segments=[];prev=0;prev_label='';
for i=1:numel(val{1})
    if strcmp(prev_label,val{1}{i}.label)
        continue;
    end
% segments(i)=(val{1}{i}.frame+prev)/2;
segments(end+1)=(val{1}{i}.frame)/2;
prev=val{1}{i}.frame;
prev_label=val{1}{i}.label;   
end
score=[];
res=compute_Rand_cost(segments,{saved_userdata.labels},key);

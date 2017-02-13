% load saved_userdata
load coreset_example D
% val=saved_userdata.labels.values;
% key=saved_userdata.labels.keys;
% key=key{1};
% segments=[];prev=0;prev_label='';
t12=D.T12;
segments=t12(:,1);
labels={};
for i=1:numel(segments)
    labels{1}{i}.frame=segments(i);
    i2=i;
% if (rand(1)<0.1) i2=1;end
    
    labels{1}{i}.label={num2str(i2)};
%     if strcmp(prev_label,val{1}{i}.label)
%         continue;
%     end
% % segments(i)=(val{1}{i}.frame+prev)/2;
% prev=val{1}{i}.frame;
% prev_label=val{1}{i}.label;   
end
score=[];
res=compute_Rand_cost(segments,labels);

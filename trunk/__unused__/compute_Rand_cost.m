function res=compute_Rand_cost(segment_endpoint,user_labels,key,MAX_SHIFT)
% keys=labels1.keys;

score=0;cnt=0;
if (~exist('MAX_SHIFT','var'))
    MAX_SHIFT=5;
end
negative=0;
positive=0;
false_neg=0; % coreset label is the same, but manual label is different
false_pos=0; %coreset label is different, but manual label is the same
for i = 1:numel(user_labels)
%     for k=1:numel(keys)
        r_j1_j2=[];
        
        try
%         labs1=labels1(keys{k});
        if (exist('key','var'))
        labs=user_labels{i}(key);
        else
            labs=user_labels{i};
        end
        for ii=1:numel(labs);lbs(ii)=str2num(labs{ii}.label{1});xlbs(ii)=labs{ii}.frame;end        
        
        for j1=1:numel(labs)
            for j2=1:numel(labs)

                if (max(labs{j1}.frame,labs{j2}.frame)>max(segment_endpoint)) || j1==j2
                    continue;
                end
                s1=sum(labs{j1}.frame>segment_endpoint)+1;
                s2=sum(labs{j2}.frame>segment_endpoint)+1;
                if (abs(j1-j2)>MAX_SHIFT)
                    continue;
                end
%                 if (abs(s1-s2)>MAX_SHIFT)
%                     continue;
%                 end
                r_j1_j2(1)=~strcmp(labs{j1}.label{1},labs{j2}.label{1});
                r_j1_j2(2)=labs{j1}.frame;
                r_j1_j2(3)=labs{j2}.frame;
                r_j1_j2(4)=s1~=s2;
                if r_j1_j2(1) 
                    % positive if the two points are of different segments
                    positive=positive+1;
                else
                    negative=negative+1;
                end
                if (s1~=s2) && r_j1_j2(1)==0
                    false_pos=false_pos+1;
                end
                if (s1==s2) && r_j1_j2(1)~=0
                    false_neg=false_neg+1;
                end
                score=score+abs(r_j1_j2(1)-r_j1_j2(4));
                 cnt=cnt+1;
            end
        end
        
        catch
        end
%     end
        
end
res.positive=positive;
res.negative=negative;
res.false_neg=false_neg;
res.false_pos=false_pos;
res.score=score;
res.cnt=cnt;
res.nscore=score/cnt;
end
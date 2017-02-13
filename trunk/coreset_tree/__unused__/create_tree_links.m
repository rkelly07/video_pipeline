function res=create_tree_links(nodes,keyframes,filename,fileformat,sliding_window_radius)
if (exist('fileformat','var')==0)
    fileformat=[];
    filename=[];
end
active_set=0;
res.traversed=[];
res.pairlist=[];
if (~isempty(filename))
    fid=fopen(filename,'w');
end
res.images_file='';
while ~isempty(active_set)
    new_active_set=[];
    for i= 1:numel(active_set)
        p=active_set(i);
        res.traversed(end+1)=p;
        children=find(nodes==p);
        if (isempty(children))
            c1=keyframes{p};
                    for j1b=1:numel(c1);
                        for j2b=1:numel(c1);
                            res.pairlist(end+1,:)=[c1(j1b) c2(j2b)];
                            if (~isempty(fileformat))
                            fprintf(fid,[sprintf(fileformat,c1(j1b)),' ',sprintf(fileformat,c2(j2b)),'\n']);
                            end
                        end
                    end
        end            
        if (p==0)
            % connect all root nodes
            for j1=1:numel(children)
                c1=keyframes{children(j1)};
                for j2=1:numel(children)
                    c2=keyframes{children(j2)};
                    for j1b=1:numel(c1);
                        for j2b=1:numel(c2);
                            res.pairlist(end+1,:)=[c1(j1b) c2(j2b)];
                            if (~isempty(fileformat))
                            fprintf(fid,[sprintf(fileformat,c1(j1b)),' ',sprintf(fileformat,c2(j2b)),'\n']);
                            end
                        end
                    end
                end
            end
            for j1=1:numel(children)
                new_active_set(end+1)=children(j1);
            end
        else
            % connect each node just to the parent
            for j1=1:numel(children)
                c1=keyframes{children(j1)};
                    c2=keyframes{p};
                    for j1b=1:numel(c1);
                        for j2b=1:numel(c2);
                            res.pairlist(end+1,:)=[c1(j1b) c2(j2b)];
                            if (~isempty(fileformat))
%                             res.images_file=cat(2,res.images_file,[sprintf(fileformat,c1(j1b)),' ',sprintf(fileformat,c2(j2b)),'\n']);
                            fprintf(fid,[sprintf(fileformat,c1(j1b)),' ',sprintf(fileformat,c2(j2b)),'\n']);
                            end
                        end
                    end
            end
            for j1=1:numel(children)
                new_active_set(end+1)=children(j1);
            end
        end
    end
    active_set=new_active_set;
end
for i = min(res.pairlist(:)):max(res.pairlist(:))
    wnd=unique(max(min(res.pairlist(:)),min(max(res.pairlist(:)),i+[-sliding_window_radius:sliding_window_radius])));
    for j = wnd
                            res.pairlist(end+1,:)=[i j];
                            if (~isempty(fileformat))
%                             res.images_file=cat(2,res.images_file,[sprintf(fileformat,c1(j1b)),' ',sprintf(fileformat,c2(j2b)),'\n']);
                            fprintf(fid,[sprintf(fileformat,i),' ',sprintf(fileformat,j),'\n']);
                            end
    end
    
end
if (~isempty(filename))
    fclose(fid);
end

end
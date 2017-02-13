function write_match_file(matches_path,list_path,out_path)
% function write_match_file(matches_path,list_path,out_path)
%
% Write a match file for VisualSFM, from the outputs of Scott's grid
% processing (matches.txt and list.txt).  Output is .mat format (not 
% Matlab .mat!) described in:
%
% http://www.cs.washington.edu/homes/ccwu/vsfm/doc.html#customize
% (see "Use your own feature matches")

% get filenames from list.txt
fid=fopen(list_path);
L=textscan(fid,'%s %f %f');
fclose(fid);
files=L{1};
filenames={};
for k=1:length(files) % can you do this with cellfun?
    [~,fname,ext]=fileparts(files{k});
    filenames{k}=[fname,ext];
end

% get sequence of numbers from matches.txt
fid=fopen(matches_path);
M=textscan(fid,'%f');
fclose(fid);
M=M{1};

% make output string
str='';
k=0;
done=false;
while ~done
    ind1=M(k+1);
    ind2=M(k+2);
    n_key=M(k+3);
    
    last=k+3+2*n_key;
    key1=M((k+4):2:last);
    key2=M((k+5):2:last);
    
    new_str=[
        filenames{1+ind1},' ',filenames{1+ind2},' ',sprintf('%d',n_key),'\n', ...
        sprintf('%d ',key1(:)'),sprintf('\n'), ...
        sprintf('%d ',key2(:)'),sprintf('\n')
        ];
    
    str((end+1):(end+length(new_str)))=new_str;
    
    k=last;
    done=(k>=length(M));
end

% write string to output file
fid=fopen(out_path,'w');
fprintf(fid,str);
fclose(fid);
return

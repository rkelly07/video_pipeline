function file_list = read_filelist(filename)
file_list = {};
fid = fopen(filename,'r');
line = fgetl(fid);
while ischar(line)
    if not(isempty(line)) && not(strcmp(line(1),'#'))
        file_list = cat(1,file_list,line);
    end
    line = fgetl(fid);
end
fclose(fid);

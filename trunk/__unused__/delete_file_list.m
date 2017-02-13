function delete_file_list(file_list,extension)
for file_i=1:length(file_list)

FILENAME=file_list{file_i};
    FILENAME2=[FILENAME,extension];
    delete(FILENAME2);
end
end

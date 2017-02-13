function log_to_file( filepath, log_line )
%LOG_TO_FILE appends the log_line at the end of the file given by filepath

    fileID = fopen(filepath, 'at+');
    fprintf(fileID, log_line);
    fclose(fileID);

end


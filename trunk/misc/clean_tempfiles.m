temp_files = dir('temp/*.mat');
for i = 1:length(temp_files)
    temp_filename = ['temp/' temp_files(i).name];
    delete(temp_filename);
end
% FILE_LIST='video_files_list.txt';
% load image_descriptors_surf_example.mat descriptor_representatives 
% BORDER_WIDTH=20;
% verbose=false;
% file_list=read_files_list(FILE_LIST);
% total_descriptors=[];
% total_bags_of_words=[];
% for file_i=1:length(file_list)
%     FILENAME=file_list{file_i};
%     IN_FILENAME=[FILENAME,'.mat'];
%     disp(IN_FILENAME);
%     try
%     load(IN_FILENAME);
% total_descriptors=[total_descriptors;descriptors];
% total_bags_of_words=[total_bags_of_words;bags_of_words'];
%     disp([size(total_bags_of_words,1),size(total_descriptors,1)]);
%     catch
%     end
% end
% 
%%
% P=PointFunctionSet(double(total_descriptors));
tic
KmeansTester2.main(total_descriptors,1000);
toc

% online video processing pipeline
pdisp(repmat('=',1,80))

%% load persistent data
curr_mfile = which(mfilename());
mfile_dir = fileparts(curr_mfile);
data_dir=[mfile_dir,filesep,'..',filesep,'data'];

scales=[1  4 8];
load invalid_pixels_mask mask
% video_filenames = read_files_list([mfile_dir,filesep,'video_files_list.txt']);
video_filenames = read_files_list([data_dir,filesep,'vids_tmp.txt']);
% res=struct('vs',[],'l',[]);
for i = 1:numel(video_filenames)
      video_filename = video_filenames{i};
      disp(video_filename);
      temp_res=annotate_video_classification(video_filename,mask,5,@(x,mask)estimate_blur_indicators3(x,scales,mask));
      res.vs=[res.vs;temp_res.vs];
      res.l=[res.l(:);temp_res.l(:)];
      
end

data=res.vs;
labels=(res.l>0);

nprtool; % seems that a network with 4-5 hidden units gives reasonable results, as an initial network structure, need to experiment
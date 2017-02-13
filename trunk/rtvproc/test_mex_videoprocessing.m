video_filename = '/scratch/rosman/boston_glass_merged_gaps_5x.mp4';

num_frames = mex_video_processing('getframecount',video_filename);
VQs=single(randn(500,66));
params=[];
params.DescriptorType='SURF';
params.DescriptorDim=66;
params.WebcamNo=0;
h = mex_video_processing('init',video_filename,params.DescriptorType,VQs,params.DescriptorDim,params.WebcamNo);
mex_video_processing('skipframe',h);
[B,I,curr_frame] = mex_video_processing('newframe',h);
mex_video_processing('deinit',h);

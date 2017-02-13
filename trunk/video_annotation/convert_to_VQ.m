function [vs] = convert_to_vector( pair, video_file_name )

load d5000;
VQs=single(descriptor_representatives{:}(:, 1:66));
WebcamNo=1;
h = mex_video_processing('init',video_file_name,'SURF',VQs,66,WebcamNo);
mex_video_processing('setframe',h,pair(1)-1);
for i=1:2
    mex_video_processing('setframe',h,pair(i)-1);
    [v,~,~] = mex_video_processing('newframe',h);
    vs(:, i)=v;
end

end


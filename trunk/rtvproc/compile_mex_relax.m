%% compile video processing mex files

mex_files = {'mex_video_processing.cpp'};

% options
options = '';

% dependencies 

src_paths = '-I/scratch/relax/opencv-2.4.10.1-install/include/ ';
lnk_paths = '-L/scratch/relax/opencv-2.4.10.1-install/lib/ ';

% if opencv and RTVideoProcessing.so is installed in the user space
src_paths= cat(2,'-I/scratch/relax/opencv-2.4.10.1-install/include/ ',src_paths);
lnk_paths = cat(2,lnk_paths, '-L/scratch/relax/rtvproc_install/lib -L/scratch/relax/opencv-2.4.10.1-install/lib ');

% opencv libraries 
lnk_lib = []; 
lnk_lib = strcat(lnk_lib,' -lopencv_core');
lnk_lib = strcat(lnk_lib,' -lopencv_highgui');
lnk_lib = strcat(lnk_lib,' -lopencv_video');
lnk_lib = strcat(lnk_lib,' -lopencv_imgproc');
lnk_lib = strcat(lnk_lib,' -lopencv_features2d');
lnk_lib = strcat(lnk_lib,' -lopencv_calib3d');
lnk_lib = strcat(lnk_lib,' -lopencv_flann');
lnk_lib = strcat(lnk_lib,' -lopencv_contrib');
lnk_lib = strcat(lnk_lib,' -lopencv_nonfree');

% video processing libraries
lnk_lib = strcat(lnk_lib,' -lRTVideoProcessing'); 

%% compile 
for i = 1:length(mex_files)
    disp(['> Compiling ' mex_files{i}])
    cmd = sprintf('mex %s %s %s %s %s',options,src_paths,lnk_paths,lnk_lib,mex_files{i});
    eval(cmd);
end

myclear

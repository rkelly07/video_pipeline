%% compile video processing mex files

mex_files = {'mex_video_processing.cpp'};

% options
options = [];

% source paths
src_paths = [];
src_paths = cat(2,src_paths,'-I/usr/local/include/ ');
src_paths = cat(2,src_paths,'-I/afs/csail.mit.edu/u/m/mikhail/MIT/opencv-2.4.10.1-install/include/ ');

% lib paths
lnk_paths = [];
lnk_paths = cat(2,lnk_paths,'-L/usr/local/lib/ ');
lnk_paths = cat(2,lnk_paths,'-L/afs/csail.mit.edu/u/m/mikhail/MIT/opencv-2.4.10.1-install/lib/ ');
lnk_paths = cat(2,lnk_paths,'-L/afs/csail.mit.edu/u/m/mikhail/MIT/rtvproc-install/lib ');

% opencv libraries 
lnk_lib = []; 
lnk_lib = cat(2,lnk_lib,' -lopencv_core');
lnk_lib = cat(2,lnk_lib,' -lopencv_highgui');
lnk_lib = cat(2,lnk_lib,' -lopencv_video');
lnk_lib = cat(2,lnk_lib,' -lopencv_imgproc');
lnk_lib = cat(2,lnk_lib,' -lopencv_features2d');
lnk_lib = cat(2,lnk_lib,' -lopencv_calib3d');
lnk_lib = cat(2,lnk_lib,' -lopencv_flann');
lnk_lib = cat(2,lnk_lib,' -lopencv_contrib');
lnk_lib = cat(2,lnk_lib,' -lopencv_nonfree');

% video processing libraries
lnk_lib = cat(2,lnk_lib,' -lRTVideoProcessing'); 

%% compile 
for i = 1:length(mex_files)
    disp(['> Compiling ' mex_files{i}])
    cmd = sprintf('mex %s %s %s %s %s',options,src_paths,lnk_paths,lnk_lib,mex_files{i});
    eval(cmd);
end

myclear

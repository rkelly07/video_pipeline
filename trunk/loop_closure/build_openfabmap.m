cd loop_closure

%% build rtvproc
disp(repmat('-',1,80))

!rm -r build
!mkdir build
cd build
!cmake ..
!make
!make install
cd ..

%% compile mex
disp(repmat('-',1,80))

mex_file = 'mex_openfabmap.cpp';

% options
options = '';

% dependencies 
src_paths = '-I/usr/local/include/ ';
lnk_paths = '-L/usr/local/lib/ ';

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

disp(['> Compiling ' mex_file])
cmd = sprintf('mex %s %s %s %s %s',options,src_paths,lnk_paths,lnk_lib,mex_file);
eval(cmd);

myclear

%%

disp(repmat('.',1,80))
cd ..


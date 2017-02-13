
if(ispc)
    DEBUG = 1; 
else 
    DEBUG = 1; 
end

filesToCompile = {'mex_video_processing.cpp', ...
%                    'mex_compute_sparse_coefficients.cpp',...
%                   'mex_openfabmap.cpp'...
                  }; 

%% options

options = []; 
if ispc
   options = cat(2,options, '-DWIN32 ');  
end
if DEBUG
    options = cat(2,options,'-g '); 
end

%% source dependencies 

% srcDep = '-I../common  -I../mi_adaptive_camera/ '; 
srcDep = ''; 
if ispc
    srcDep = cat(2,srcDep,'-I"C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v5.5\include" ');
else 
    srcDep = cat(2,'-I/home/drl-leopard/OpenCV/opencv-2.4.9_install/include/ -I/usr/include/eigen3 ',srcDep); 
end

%% linker path 

lnkDepPath = [];
if ispc
    lnkDepPath = cat(2,lnkDepPath, '-L"C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v5.5\lib\x64" '); 
    lnkDepPath = cat(2,lnkDepPath, '-L"C:\opencv\build\x64\vc11\lib" '); 
    
    if DEBUG
        lnkDepPath = cat(2,lnkDepPath, '-L../common/build/Debug/ -L../mi_adaptive_camera/build/Debug/ '); 
    else 
        lnkDepPath = cat(2,lnkDepPath, '-L../common/build/Release/ -L../mi_adaptive_camera/build/Release/ '); 
    end
    
else 
    lnkDepPath = cat(2,lnkDepPath, '-L/home/drl-leopard/rtvproc_install/lib -L/usr/local/cuda/lib64 -L/home/drl-leopard/OpenCV/opencv-2.4.9_install/lib ');
end

%% link libraries 

lnkLib = []; 
lnkLib = cat(2,lnkLib,'-lopencv_core -lopencv_highgui ');
lnkLib = cat(2,lnkLib,'-lopencv_video -lopencv_imgproc -lopencv_features2d -lopencv_calib3d -lopencv_flann -lopencv_contrib -lopencv_nonfree'); %no space

if ispc 
    % need to add the suffix
    v = '248';
    if DEBUG
        v = cat(2,v,'d');  
    end
    temp = regexp(lnkLib,' ','split'); 
    temp = cellfun(@(x) cat(2,x,v,' '),temp,'uniformoutput',0);
    
    lnkLib = cell2mat(temp);     
end

lnkLib = strcat(lnkLib,' -lRTVideoProcessing'); 

%% compile 
for i = 1:length(filesToCompile)
    disp(['> Compiling ' filesToCompile{i}])
    cmd = sprintf('mex %s %s %s %s %s',options,srcDep,lnkDepPath,lnkLib,filesToCompile{i});
    eval(cmd);
end

clear all

% mex -L/usr/local/cuda/lib64 -L/usr/local/opencv-2.4.3/lib -lcudart -lcuda -lopencv_imgproc -lopencv_core -lopencv_calib3d -lopencv_flann -lopencv_features2d -lopencv_contrib -lopencv_highgui mex_adaptive_camera_awgnmodel.cpp build/libadaptive_camera.so 
% mex -I../common -L/usr/local/lib -L/usr/local/cuda/lib64 -lcudart -lcuda -lopencv_imgproc -lopencv_core -ladaptive_camera -lsli_common mex_photoconsistency_error.cpp 
% mex -I../common -L/usr/local/lib -L/usr/local/cuda/lib64 -lsli_common -lcudart -lcuda -lopencv_imgproc -lopencv_core mex_render_range_image.cpp build/libadaptive_camera.so 
% mex -I../common -L/usr/local/lib -L/usr/local/cuda/lib64 -lcudart -lcuda -lopencv_imgproc -lopencv_core -lsli_common -ladaptive_camera mex_reconstruct_sweep.cpp 
% mex -I../common -L/usr/local/lib -L/usr/local/cuda/lib64 -lcudart -lcuda -lopencv_imgproc -lopencv_core -lsli_common -ladaptive_camera mex_compute_photoconsistency_histogram.cpp
% mex -I../common -L/usr/local/lib -L/usr/local/cuda/lib64 -lcudart -lcuda -lopencv_imgproc -lopencv_core -lsli_common -ladaptive_camera mex_compute_photoconsistency_range_MI.cpp
% mex -I../common -L/usr/local/lib -L/usr/local/cuda/lib64 -lcudart -lcuda -lopencv_imgproc -lopencv_core -lsli_common -ladaptive_camera mex_compute_photoconsistency_range_MI_Gaussian.cpp
% mex -L/usr/local/cuda/lib64 -L/usr/local/opencv-2.4.3/lib -lcudart -lcuda -lopencv_imgproc -lopencv_core -lopencv_calib3d -lopencv_flann -lopencv_features2d -lopencv_contrib -lopencv_highgui  mex_backproject.cpp build/libadaptive_camera.so 
% mex -L/usr/local/cuda/lib64 -L/usr/local/opencv-2.4.3/lib -lcudart -lcuda -lopencv_imgproc -lopencv_core -lopencv_calib3d -lopencv_flann -lopencv_features2d -lopencv_contrib -lopencv_highgui mex_adaptive_camera_singlemodel.cpp build/libadaptive_camera.so 
% mex -L/usr/local/cuda/lib64 -lcudart -lcuda  mex_normal_denoising.cpp build/libgpu_image_processing.so
% mex -L/usr/local/cuda/lib64  -L/usr/local/opencv-2.4.3/lib -lcudart -lcuda -lopencv_imgproc -lopencv_core -lopencv_calib3d -lopencv_flann -lopencv_features2d -lopencv_contrib -lopencv_highgui -lopencv_core mex_add_noise.cpp build/libadaptive_camera.so
% mex -L/usr/local/cuda/lib64 -lcudart -lcuda  mex_uniform_noise.cpp build/libadaptive_camera.so
% mex -L/usr/local/cuda/lib64 -lcudart -lcuda  mex_tv_denoising.cpp build/libgpu_image_processing.so

% ------------------------------------------------
% reformatted with stylefix.py on 2014/09/21 18:53

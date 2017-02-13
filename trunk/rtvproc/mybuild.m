cd rtvproc

%% build rtvproc
disp(repmat('-',1,80))

!rm -r build
!mkdir build
cd build

if ismac

    !cmake ..
    
elseif isunix && not(ismac)
    
    !cmake -D OpenCV_DIR=~/MIT/opencv-2.4.10.1-install/share/OpenCV/ -D CMAKE_INSTALL_PREFIX=~/MIT/rtvproc-install/ ..
    
else
    
    error('Platform not supported.')
    
end

!make
!make install
cd ..

% compile mex
disp(repmat('-',1,80))

if ismac
    
    compile_mex_mac
    
elseif isunix && not(ismac)
    
    compile_mex_linux
    
else
    
    error('Platform not supported.')
    
end

disp(repmat('.',1,80))
cd ..

%% build openfabmap

build_openfabmap


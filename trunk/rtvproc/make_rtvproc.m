cd rtvproc
!rm -r build
!mkdir build
cd build
!cmake ..
!make
!make install
cd ..
if ispc
    error(1)
elseif ismac
    compile_mex_mac
elseif not(ismac) && isunix
    compile_mex_new_server
end
cd ..
rm -r build
mkdir build
cd build
cmake -D OpenCV_DIR=~/MIT/opencv-2.4.10.1-install/share/OpenCV/ -D CMAKE_INSTALL_PREFIX=~/MIT/rtvproc-install/ ..
make
make install

# CMakeLists.txt 
project(text)

# required cmake                                 
cmake_minimum_required(VERSION 2.8)

# packages                                                                                                                                                                                                 
#set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/CMake/cuda" ${CMAKE_MODULE_PATH})

#find_package(CUDA QUIET REQUIRED)
#find_package( OpenCV REQUIRED  calib3d flann features2d core highgui contrib imgproc nonfree  )
#Relax:opencv 3.0 devides contrib into libs, and put nonfree into xfeatures2d
find_package( OpenCV REQUIRED  core highgui imgproc text )

#add opencv 3.0.0 include path
include_directories( "/scratch/relax/opencv3-install/include" )

set(CUDA_ATTACH_VS_BUILD_RULE_TO_CUDA_FILE OFF)

set(BUILD_SHARED_LIBS OFF)

#list(APPEND CUDA_NVCC_FLAGS)

#INCLUDE(FindMatlab)
ADD_DEFINITIONS(-fPIC)
set(BUILD_SHARED_LIBS ON) 

# nvcc flags                                                                                                                                                                                               
#set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS}; -Xcompiler -fPIC)
#set(CUDA_SEPARABLE_COMPILATION ON)
#set(CUDA_ATTACH_VS_BUILD_RULE_TO_CUDA_FILE ON)
#set(CUDA_64_BIT_DEVICE_CODE ON)

SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

#SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -DUSE_LINUX_PROFILER" )
SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS}" )

add_library(text SHARED textDetectionRecognition.cpp )
target_link_libraries(text ${OpenCV_LIBS})
set_target_properties(text PROPERTIES PREFIX "")

set_property(TARGET text PROPERTY INSTALL_RPATH_USE_LINK_PATH TRUE) 
set_property(TARGET text PROPERTY MACOSX_RPATH TRUE) 

install (TARGETS text DESTINATION lib RENAME text.so)

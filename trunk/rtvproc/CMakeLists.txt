# CMakeLists.txt 
project(rtvproc)

# required cmake                                 
cmake_minimum_required(VERSION 2.8)

# packages                                                                                                                                                                                                 
#set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/CMake/cuda" ${CMAKE_MODULE_PATH})

#find_package(CUDA QUIET REQUIRED)
find_package( OpenCV REQUIRED  calib3d flann features2d core highgui contrib imgproc nonfree  )

set(CUDA_ATTACH_VS_BUILD_RULE_TO_CUDA_FILE OFF)

set(BUILD_SHARED_LIBS OFF)

#list(APPEND CUDA_NVCC_FLAGS)

INCLUDE(FindMatlab)
ADD_DEFINITIONS(-fPIC)
set(BUILD_SHARED_LIBS ON) 

# nvcc flags                                                                                                                                                                                               
#set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS}; -Xcompiler -fPIC)
#set(CUDA_SEPARABLE_COMPILATION ON)
#set(CUDA_ATTACH_VS_BUILD_RULE_TO_CUDA_FILE ON)
#set(CUDA_64_BIT_DEVICE_CODE ON)

SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

SET( PROFILER_CPP "SimpleProfiler.cpp")
#SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -DUSE_LINUX_PROFILER" )
SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS}" )

add_library(RTVideoProcessing SHARED RTVideoProcessing.cpp ${PROFILER_CPP})
target_link_libraries(RTVideoProcessing ${OpenCV_LIBS})

#add_executable (RTVideoProcessingServer rtvproc_server.cpp vqreader.cpp RTVideoProcessing.cpp ${PROFILER_CPP})
#target_link_libraries(RTVideoProcessingServer ${OpenCV_LIBS})

#add_executable (RTVideoProcessingClient rtvproc_client.cpp vqreader.cpp RTVideoProcessing.cpp SimpleProfiler.cpp)
#target_link_libraries(RTVideoProcessingClient ${OpenCV_LIBS})

set_property(TARGET RTVideoProcessing PROPERTY INSTALL_RPATH_USE_LINK_PATH TRUE) 
set_property(TARGET RTVideoProcessing PROPERTY MACOSX_RPATH TRUE) 

install (TARGETS RTVideoProcessing DESTINATION lib )

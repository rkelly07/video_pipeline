# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 2.8

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list

# Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The program to use to edit the cache.
CMAKE_EDIT_COMMAND = /usr/bin/ccmake

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/serverdemo/video_analysis/trunk/rtvproc

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/serverdemo/video_analysis/trunk/rtvproc/build

# Include any dependencies generated for this target.
include CMakeFiles/RTVideoProcessing.dir/depend.make

# Include the progress variables for this target.
include CMakeFiles/RTVideoProcessing.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/RTVideoProcessing.dir/flags.make

CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.o: CMakeFiles/RTVideoProcessing.dir/flags.make
CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.o: ../RTVideoProcessing.cpp
	$(CMAKE_COMMAND) -E cmake_progress_report /home/serverdemo/video_analysis/trunk/rtvproc/build/CMakeFiles $(CMAKE_PROGRESS_1)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Building CXX object CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.o"
	/usr/bin/c++   $(CXX_DEFINES) $(CXX_FLAGS) -o CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.o -c /home/serverdemo/video_analysis/trunk/rtvproc/RTVideoProcessing.cpp

CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.i"
	/usr/bin/c++  $(CXX_DEFINES) $(CXX_FLAGS) -E /home/serverdemo/video_analysis/trunk/rtvproc/RTVideoProcessing.cpp > CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.i

CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.s"
	/usr/bin/c++  $(CXX_DEFINES) $(CXX_FLAGS) -S /home/serverdemo/video_analysis/trunk/rtvproc/RTVideoProcessing.cpp -o CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.s

CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.o.requires:
.PHONY : CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.o.requires

CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.o.provides: CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.o.requires
	$(MAKE) -f CMakeFiles/RTVideoProcessing.dir/build.make CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.o.provides.build
.PHONY : CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.o.provides

CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.o.provides.build: CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.o

CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.o: CMakeFiles/RTVideoProcessing.dir/flags.make
CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.o: ../SimpleProfiler.cpp
	$(CMAKE_COMMAND) -E cmake_progress_report /home/serverdemo/video_analysis/trunk/rtvproc/build/CMakeFiles $(CMAKE_PROGRESS_2)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Building CXX object CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.o"
	/usr/bin/c++   $(CXX_DEFINES) $(CXX_FLAGS) -o CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.o -c /home/serverdemo/video_analysis/trunk/rtvproc/SimpleProfiler.cpp

CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.i"
	/usr/bin/c++  $(CXX_DEFINES) $(CXX_FLAGS) -E /home/serverdemo/video_analysis/trunk/rtvproc/SimpleProfiler.cpp > CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.i

CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.s"
	/usr/bin/c++  $(CXX_DEFINES) $(CXX_FLAGS) -S /home/serverdemo/video_analysis/trunk/rtvproc/SimpleProfiler.cpp -o CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.s

CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.o.requires:
.PHONY : CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.o.requires

CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.o.provides: CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.o.requires
	$(MAKE) -f CMakeFiles/RTVideoProcessing.dir/build.make CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.o.provides.build
.PHONY : CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.o.provides

CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.o.provides.build: CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.o

# Object files for target RTVideoProcessing
RTVideoProcessing_OBJECTS = \
"CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.o" \
"CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.o"

# External object files for target RTVideoProcessing
RTVideoProcessing_EXTERNAL_OBJECTS =

libRTVideoProcessing.so: CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.o
libRTVideoProcessing.so: CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.o
libRTVideoProcessing.so: CMakeFiles/RTVideoProcessing.dir/build.make
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_calib3d.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_flann.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_features2d.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_core.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_highgui.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_contrib.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_imgproc.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_nonfree.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_gpu.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_legacy.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_photo.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_ocl.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_calib3d.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_features2d.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_flann.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_ml.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_video.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_objdetect.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_highgui.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_imgproc.so.2.4.10
libRTVideoProcessing.so: /home/serverdemo/OpenCV/opencv-2.4.10.1-install/lib/libopencv_core.so.2.4.10
libRTVideoProcessing.so: CMakeFiles/RTVideoProcessing.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --red --bold "Linking CXX shared library libRTVideoProcessing.so"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/RTVideoProcessing.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/RTVideoProcessing.dir/build: libRTVideoProcessing.so
.PHONY : CMakeFiles/RTVideoProcessing.dir/build

CMakeFiles/RTVideoProcessing.dir/requires: CMakeFiles/RTVideoProcessing.dir/RTVideoProcessing.cpp.o.requires
CMakeFiles/RTVideoProcessing.dir/requires: CMakeFiles/RTVideoProcessing.dir/SimpleProfiler.cpp.o.requires
.PHONY : CMakeFiles/RTVideoProcessing.dir/requires

CMakeFiles/RTVideoProcessing.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/RTVideoProcessing.dir/cmake_clean.cmake
.PHONY : CMakeFiles/RTVideoProcessing.dir/clean

CMakeFiles/RTVideoProcessing.dir/depend:
	cd /home/serverdemo/video_analysis/trunk/rtvproc/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/serverdemo/video_analysis/trunk/rtvproc /home/serverdemo/video_analysis/trunk/rtvproc /home/serverdemo/video_analysis/trunk/rtvproc/build /home/serverdemo/video_analysis/trunk/rtvproc/build /home/serverdemo/video_analysis/trunk/rtvproc/build/CMakeFiles/RTVideoProcessing.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/RTVideoProcessing.dir/depend

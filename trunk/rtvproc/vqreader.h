//
//  vqreader.h
//  test
//
//  Created by Mikhail Volkov on 4/18/14.
//  Copyright (c) 2014 Mikhail Volkov. All rights reserved.
//

#ifndef __vqreader__
#define __vqreader__

#include <iostream>
#include <fstream>
#include <sstream>
#include <iterator>
#include <opencv/cv.h>
// GR: For Linux Implementations
#include <iterator>
struct VQ_struct
{
  cv::Mat mat;
  int descriptor_dim;
  int num_VQs;
};

VQ_struct LoadVQ(std::string vq_filename);

#endif /* defined(__vqreader__) */

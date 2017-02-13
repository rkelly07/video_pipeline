//
//  vqreader.cpp
//  test
//
//  Created by Mikhail Volkov on 4/18/14.
//  Copyright (c) 2014 Mikhail Volkov. All rights reserved.
//

#include "vqreader.h"

VQ_struct LoadVQ(std::string vq_filename)
{

  std::ifstream file;

  // find num rows and cols
  file.open(vq_filename.c_str());

  int descriptor_dim = 0;
  int num_VQs = 0;

  // new lines will be skipped unless we stop it from happening:
  file.unsetf(std::ios_base::skipws);

  // count the newlines with an algorithm specialized for counting:
  descriptor_dim = (int)std::count(std::istream_iterator<char>(file),std::istream_iterator<char>(),'\n');

  file.close();
  file.open(vq_filename.c_str());

  std::string line;
  std::getline(file,line);
  std::istringstream iss(line);

  while(iss.good())
  {
    cv::string val;
    getline(iss, val, ',');
    num_VQs++;
  }

  std::cout << "parsed descriptor_dim = " << descriptor_dim << std::endl;
  std::cout << "parsed num_VQs = " << num_VQs << std::endl;

  file.close();

  // now read in the data
  float* data = (float*)malloc(descriptor_dim*num_VQs*sizeof(float));

  file.open(vq_filename.c_str());

  int row = 0;
  int col = 0;

  while(file.good())
  {
    std::string line;
    std::getline(file, line);

    if (line.empty())
      break;

    std::stringstream iss(line);

    col = 0;

    while(iss.good())
    {
      std::string val;
      getline(iss, val, ',');

      std::stringstream ss(val);
      ss >> data[row*num_VQs+col];

      col++;
    }

    row++;
  }

  cv::Mat mat(num_VQs, descriptor_dim, CV_32FC1);

  for (int i=0;i<num_VQs;++i)
  {
    for (int j=0;j<descriptor_dim;++j)
    {
      mat.at<float>(i,j) = data[i*num_VQs+j];
      //std::cout << data[i][j] << ',';
    }
    //std::cout << std::endl;
  }

  VQ_struct VQ;
  VQ.mat = mat;
  VQ.descriptor_dim = descriptor_dim;
  VQ.num_VQs = num_VQs;

  free(data);
  
  return VQ;

}


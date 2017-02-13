#include <iostream>
#include "opencv/cv.h"
#include "opencv/highgui.h"

using namespace cv;

int main()
{
  
  cv::Mat image;

  cv::VideoCapture cap;
  cap.open(0);
  
  while(1)
  {
    try
    {
      cap >> image;
      cv::resize(image,image,cv::Size(640,480));
      cv::imshow("webcam",image);
    }
    catch (std::exception& e)
    {
      std::cerr << e.what() << std::endl;
    }

    cv::waitKey(33);
  }

}



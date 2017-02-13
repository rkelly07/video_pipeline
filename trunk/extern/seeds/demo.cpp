// SEEDS
// superpixels

#include <vector>
#include <string>

#include "seeds2.h"

#include <cv.h>
#include <highgui.h>
#include <fstream>

#include "helper.h"

using namespace std;
using namespace cv;


int main(int argc, char* argv[])
{
  int  height= 381;
    int width = 281;
    
  int NR_SUPERPIXELS = 20;


Mat image; 
  int numlabels = 20;
        cvNamedWindow("image",1);
        cvMoveWindow("image",240,-1280);
     cvNamedWindow("output1",1);
        cvMoveWindow("output1",540,-1280);

cv::VideoCapture cap(0); // 0: default camera
    cap.set(CV_CAP_PROP_FRAME_HEIGHT,width );
    cap.set(CV_CAP_PROP_FRAME_WIDTH,  height );

  int sz = height*width;



  UINT* ubuff = new UINT[sz];
  UINT* ubuff2 = new UINT[sz];
  UINT* dbuff = new UINT[sz];
int NR_BINS = 5; // Number of bins in each histogram channel

 
// SEEDS INITIALIZE
int nr_superpixels = NR_SUPERPIXELS;

int seed_width = 3; int seed_height = 4; int nr_levels = 4;

seed_width = 3; seed_height = 4; nr_levels = 4;
seed_width = 4; seed_height = 3; nr_levels = 4;
//seed_width = 2; seed_height = 2; nr_levels = 7;

IplImage* out1img=cvCreateImage(cvSize(height,width ),IPL_DEPTH_8U,3); 




while(true){
  SEEDS * seeds= new SEEDS( height, width , 3, NR_BINS, 0);
  

        cap >> image;
 cv:imshow("image",image);
	IplImage* img = &((IplImage) image);




  UINT pValue;
  UINT pdValue;
  char c;
  UINT r,g,b,d,dx,dy;
  int idx = 0;

 for(int j=0;j<img->height  ;j++){
  for(int i=0;i<img->width;i++){

  

            // image is assumed to have data in BGR order
   b =((uchar*)(img->imageData + img->widthStep*(j)))[(i)*img->nChannels];
	g = ((uchar*)(img->imageData + img->widthStep*(j)))[(i)*img->nChannels+1];
	r = ((uchar*)(img->imageData + img->widthStep*(j)))[(i)*img->nChannels+2];
			if (d < 128) d = 0;
            pValue = b | (g << 8) | (r << 16);
  
	    ubuff[idx] = pValue;
        ubuff2[idx] = pValue;
        idx++;
	}

  }


  seeds->initialize(ubuff, seed_width, seed_height, nr_levels);


printf("Generating SEEDS with %d superpixels\n", NR_SUPERPIXELS);


seeds->iterate();


// for (int i = 0; i<sz; i++) output_buff[i] = 0;

 DrawContoursAroundSegments(ubuff, seeds->labels[nr_levels-1], height ,  width , 0xff0000, false);//0xff0000 draws red contours
 // DrawContoursAroundSegments(output_buff, seeds.labels[nr_levels-1], width, height, 0xffffff, true);//0xff0000 draws white contours

  
  uchar* pValue1;
   idx = 0;

  for(int j=0;j<out1img->height;j++)
    for(int i=0;i<out1img->width  ;i++)
      {
        pValue1 = &((uchar*)(out1img->imageData + out1img->widthStep*(j)))[(i)*out1img->nChannels];
        pValue1[0] = ubuff[idx] & 0xff;
        pValue1[1] = (ubuff[idx] >> 8) & 0xff;
        pValue1[2] = (ubuff[idx] >>16) & 0xff;
        idx++;
      }

  cvShowImage("output1", out1img);
  delete seeds;
  waitKey(1);
  }

  return 0;
}

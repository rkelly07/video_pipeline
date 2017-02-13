#ifndef __RTVPROC_H
#define __RTVPROC_H

#pragma once
#include <vector>
#include <string>
#include <sys/time.h>
#include "opencv/cv.h"
#include "opencv/highgui.h"
#include "opencv2/core/core.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/nonfree/features2d.hpp"
//#include "opencv2/gpu/gpu.hpp"
//#include "opencv2/nonfree/gpu.hpp"
#include "vqreader.h"

using std::cin;
using std::cout;
using std::cerr;
using std::endl;

///////////////////////////////////////////////////////////////////////////
// frame desriptor class
class FrameDesc
{
public:

    FrameDesc()
    {
        isvalid = false;
    }

    unsigned int width;
    unsigned int height;

    unsigned long frame_idx;
    cv::Mat img;
    std::vector<unsigned int> hist;
    std::vector<float> desc;
    cv::Mat aux_img;
    unsigned int num_features;
    std::vector<unsigned int> feat_xy;

    bool isvalid;

};


///////////////////////////////////////////////////////////////////////////
// RT video processing class
class RTVideoProcessing
{
    long number_of_frames;
public:

    // size of the image used for processing
    const static unsigned int default_proc_width = 640;
    const static unsigned int default_proc_height = 480;
    const static int default_minHessian = 1000;
    unsigned int proc_width;
    unsigned int proc_height;
    // size of the image sent
    unsigned int tx_width;
    unsigned int tx_height;

    bool isUsingWebcam;

    cv::VideoCapture cap;
    std::string filename;
    cv::Mat VQ;
    //cv::Mat VQT;
    cv::Mat frame;
    cv::Mat frame_hsv;
    cv::Mat gray_image;
    cv::Mat tx_image;

    bool compute_bow;
    int minHessian;
    unsigned int idx;
    unsigned int base_descriptor_dim;
    int resulting_descriptor_dim;
    unsigned int min_hist_count;
    cv::Mat histogram;


    // static const bool use_gpu = false;
    cv::SurfFeatureDetector surf_detector;
    cv::SurfDescriptorExtractor extractor;

    //FREAK extractor;
    //FlannBasedMatcher matcher;vidcurr_frameeo_filename
    cv::BFMatcher  matcher;
    std::vector<cv::DMatch> matches;

    struct timeval start;

    enum DescriptorType {SURF,HOG,HSV,NONE};
    DescriptorType desc_type;

    // ------------------------------------------------------------------------
    static std::vector<long> GetVideoInfo(std::string filename, const int webcam_no=0)
    {
        cv::VideoCapture cap;
        
        if (filename.empty())
        {
            cout << "No file specified: reading from webcam " << webcam_no << endl;
            
            try
            {
                // open webcam
                cap = cv::VideoCapture(webcam_no);
                if (!cap.isOpened())
                {
                    cerr << "Could not open " << webcam_no << endl;
                }
            }
            catch(const std::exception& e)
            {
                cerr << "Could not open " << webcam_no << endl;
                cerr << e.what() << endl;
            }
            
        }
        else
        {
            // open file
            cap = cv::VideoCapture(filename);
            if (!cap.isOpened())
            {
                cerr << "Could not open " << filename << endl;
            }
        }
        
        std::vector<long> video_info;

        video_info.push_back(cap.get(CV_CAP_PROP_FRAME_COUNT));
        video_info.push_back(cap.get(CV_CAP_PROP_FRAME_WIDTH));
        video_info.push_back(cap.get(CV_CAP_PROP_FRAME_HEIGHT));
        video_info.push_back(cap.get(CV_CAP_PROP_FPS));

        return video_info;
    }

    // ------------------------------------------------------------------------
    RTVideoProcessing(bool _compute_bow,cv::Mat VQ, std::string desc_type, unsigned int _proc_width=default_proc_width, unsigned int _proc_height=default_proc_height, int _minHessian=default_minHessian)
    {
        compute_bow=_compute_bow;
        proc_width=_proc_width;
        proc_height=_proc_height;
        tx_width = proc_width;
        tx_height = proc_height;
        minHessian = _minHessian;
        surf_detector = cv::SurfFeatureDetector(minHessian);
        idx = 0;
        min_hist_count = 5;

        if (!desc_type.compare("SURF"))
        {
            this->desc_type = SURF;
        }
        else if (!desc_type.compare("HSV"))
        {
            this->desc_type = HSV;
        }
        else if (!desc_type.compare("HOG"))
        {
            this->desc_type = HOG;
        }
        else if (!desc_type.compare("NONE"))
        {
            this->desc_type = NONE;
        }
        else
        {
            cerr << "Invalid descriptor type: " << desc_type << endl;
        }
        if (compute_bow)
        {
            // rows should be descriptor dimension
            if (VQ.rows < VQ.cols)
            {
                cout << "transposing ";
                cv::transpose(VQ, VQ);
            }

            switch(this->desc_type)
            {
                case SURF:
                {
                    resulting_descriptor_dim = VQ.rows;
                    histogram = cv::Mat::zeros(resulting_descriptor_dim,1,CV_32SC1);
                }
                break;
                case HSV:
                {
                    resulting_descriptor_dim = VQ.rows;
                    histogram = cv::Mat::zeros(resulting_descriptor_dim,1,CV_32SC1);
                }
                break;
                case HOG:
                {
                    resulting_descriptor_dim = -1;
                }
                break;
                case NONE:
                {
                    resulting_descriptor_dim = 1;
                }
                break;
            }
            cout << "VQ: " << VQ.rows << " rows x " << VQ.cols << " cols" << endl;

            VQ.convertTo(this->VQ,CV_32F);
            base_descriptor_dim = VQ.rows;
            std::vector<cv::Mat> descs;
            for(int i = 0; i < VQ.cols; i++)
            {
                descs.push_back(VQ.col(i));
            }

            //matcher.add(descs);
            //matcher.train();
        }
        this->isUsingWebcam = false;

    }

    // ------------------------------------------------------------------------
    void open(const std::string& filename, const int webcam_no = 0)
    {
        this->filename = filename;
        this->idx=0;

        if (filename.empty())
        {
            cout << "No file specified: reading from webcam " << webcam_no << endl;
            this->isUsingWebcam = true;

            try
            {
                // open webcam
                cap = cv::VideoCapture(webcam_no);
                if (!cap.isOpened())
                {
                    cerr << "Could not open " << webcam_no << endl;
                }
            }
            catch(const std::exception& e)
            {   
                cerr << "Could not open " << webcam_no << endl;
                cerr << e.what() << endl;
            }

        }
        else
        {
            // open file
            cap = cv::VideoCapture(filename);
            if (!cap.isOpened())
            {
                cerr << "Could not open " << filename << endl;
            }
        }

        cout << "Opened successfully!" << endl;

        number_of_frames = cap.get(CV_CAP_PROP_FRAME_COUNT);
        cout << "Number of frames: " << number_of_frames << endl;

    }

    // process next frame (defined in .cpp file)
    FrameDesc process_next_frame();
    FrameDesc extract_features();

    void skip_frame();
    void set_frame(unsigned long frame);

};

#endif /* __RTVPROC_H */


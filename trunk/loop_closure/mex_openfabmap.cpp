/*********************************************
 * Mex wrapper for openfabmap
 *
 * Usage:
 * tree=mex_openfabmap('create_tree',train_data); % creates a Chow-Liu tree
 * D=mex_openfabmap('localize',tree,locations,test_data,[PzGe, PzGNe]); % computes the log-likelihood
 *********************************************/
#include "mex.h"
#include <algorithm>
#include <vector>
#include <math.h>
#include <string>
#include <string.h>
#include "opencv2/opencv.hpp"
#include "opencv2/nonfree/nonfree.hpp"
#include <iostream>

using namespace cv;
using namespace cv::of2;

using std::max;
using std::cout;
using std::cerr;
using std::endl;
using std::vector;
using std::string;
using cv::Vec3b;

//class VideoProcessingStr{
//    string filename;
//    long unsigned int frame;
//    RTVideoProcessing img_proc;
//    public:
//    long unsigned int getFrame(){
//    return frame;
//    }
//    FrameDesc process_next_frame(){
//        frame++;
//        return img_proc.process_next_frame();
//    }
//    VideoProcessingStr(const string &filename_, cv::Mat &VQ):filename(filename_),frame(0),img_proc(VQ){
//        img_proc.open(filename);
//    }
//};

template<class T> inline T& access2DMatrix(T* M, const int& i, const int& j, const int& rows, const int& cols)
{
    return M[i+(j*rows)];
}
template<class T> inline const T& access2DMatrix(const T* M, int i, int j, const int& rows, const int& cols)
{
    return M[i+(j*rows)];
}

template<class T> inline T sqr(const T& a)
{
    return a*a;
}
//
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    char* command = mxArrayToString(prhs[0]);
    if (command==0)
    {
        mexErrMsgTxt("Null command");
    }
    
    // ------------------------------------------------------------------------
    if (strcmp(command, "create_tree")==0)
    {
        cout<<"init\n";
        if (nrhs<2)
        {
            mexErrMsgTxt("Wrong number of arguments");
        }
        string str;
        int num_examples = mxGetM(prhs[1]);
        int vocabulary_size = mxGetN(prhs[1]);

        cout << "vocabulary_size dim = " << vocabulary_size << endl;
        cout << "num_examples = " << num_examples << endl;

        cv::Mat hsts(num_examples,vocabulary_size,CV_32FC1);
        for (int i = 0; i<num_examples; ++i)
        {
            for (int j = 0; j<vocabulary_size; ++j)
            {
                hsts.at<float>(i,j) = ((float*)mxGetPr(prhs[1]))[i+j*num_examples];
            }
        }
        if (nlhs>=1)
        {
            of2::ChowLiuTree treeBuilder;
            treeBuilder.add(hsts);
            Mat tree = treeBuilder.make();            
            plhs[0] = mxCreateNumericMatrix(tree.rows, tree.cols, mxSINGLE_CLASS, mxREAL);
            
            for (int i = 0; i<tree.rows; ++i)
            {
                for (int j = 0; j<tree.cols; ++j)
                {
                    ((float*)mxGetPr(plhs[0]))[i+j*tree.rows]=tree.at<double>(i,j);
                    //((float*)mxGetPr(plhs[0]))[i+j*tree.rows]=VQ.at<float>(i,j);
                    //((float*)mxGetPr(plhs[0]))[i+j*tree.rows]=i;
                }
            }
        }
    }
    
    // ------------------------------------------------------------------------
    else if (strcmp(command, "localize")==0)
    {
        if (nrhs<4)
        {
            mexErrMsgTxt("Wrong number of arguments");
        }
        string str;
        int num_page_locations = mxGetM(prhs[2]);
        int num_test_locations = mxGetM(prhs[3]);
        int vocabulary_size = mxGetN(prhs[2]);

        //cout << "vocabulary_size dim = " << vocabulary_size << endl;
        //cout << "num_page_locations = " << num_page_locations << endl;
        //cout << "num_test_locations = " << num_test_locations << endl;

        float PzGe=mxGetPr(prhs[4])[0];
        float PzGNe=mxGetPr(prhs[4])[1];
        
        cv::Mat page_locations;
        vector< cv::Mat > test_locations;
        cv::Mat tree(4,vocabulary_size,CV_64FC1);
        for (int i = 0; i<4; ++i)
        {
            for (int j = 0; j<vocabulary_size; ++j)
            {
                tree.at<double>(i,j) = ((float*)mxGetPr(prhs[1]))[i+j*4];
            }
        }
        //cerr << "check" << endl;
        
        for (int i = 0; i<num_page_locations; ++i)
        {
            cv::Mat bow(1,vocabulary_size,CV_32FC1);
            for (int j = 0; j<vocabulary_size; ++j)
            {
                bow.at<float>(0,j) = ((float*)mxGetPr(prhs[2]))[i+j*num_page_locations];
            }
            page_locations.push_back(bow);
        }
        //cerr << "check" << endl;
        
        for (int i = 0; i<num_test_locations; ++i)
        {
            cv::Mat bow(1,vocabulary_size,CV_32FC1);
            for (int j = 0; j<vocabulary_size; ++j)
            {
                bow.at<float>(0,j) = ((float*)mxGetPr(prhs[3]))[i+j*num_test_locations];
            }
            test_locations.push_back(bow);
        }
        //cerr << "check" << endl;
        
        if (nlhs>=1)
        {
            plhs[0] = mxCreateNumericMatrix(num_test_locations,num_page_locations,mxSINGLE_CLASS,mxREAL);
            for (int test_lx = 0; test_lx < num_test_locations; test_lx++)
            {
                //cout << "test_location = " << test_lx << endl;
                Ptr<of2::FabMap> fabmap;
                fabmap = new of2::FabMap2(tree, PzGe, PzGNe, of2::FabMap::SAMPLED | of2::FabMap::CHOW_LIU);
                fabmap->addTraining(test_locations[test_lx]);
                vector<of2::IMatch> matches;
                fabmap->compare(page_locations, matches, false);
                
                for (int page_lx = 0; page_lx < num_page_locations; page_lx++)
                {
                    float log_prob=matches[page_lx].likelihood;
                    ((float*)mxGetPr(plhs[0]))[test_lx+page_lx*num_test_locations]=log_prob;
                    //cout << "  page_location = " << page_lx << " -> log prob = " << log_prob << endl;
                }
                
            }
            //cout << "tree matrix: " << tree.rows << "," << tree.cols << "\n";
            
        }
        //cerr << "check" << endl;
    }
    
    // ------------------------------------------------------------------------
    else
    {
        mexErrMsgTxt("Unknown command");
    }
    
}


/*********************************************
 * Mex wrapper for RTVideoProcessing / iDiary
 *
 * Usage:
 * h = mex_video_processing('init',video_filename,params.DescriptorType,VQs,DescriptorDim,WebcamNo,[resize_x, resize_y]);
 * [v,img,idx] = mex_video_processing('newframe',h);plot(v);title(num2str(idx));
 * [v,img,idx] = mex_video_processing('skipframe',h);
 * mex_video_processing('deinit',h);
 *********************************************/
#include "mex.h"
#include <algorithm>
#include <vector>
#include <math.h>
#include "RTVideoProcessing.h"
#include <string>
#include <string.h>

using std::max;
using std::vector;
using std::string;
using cv::Vec3b;

#define CHECK_MATLAB_NUMEL(M,M_id,N)   if(mxGetNumberOfElements(M)!=N){\
                                            char BUFF[1024];\
                                                    sprintf(BUFF,"Expected %d elements at argument %d",N,M_id);\
                                                    mexErrMsgTxt(BUFF);\
}

#define CHECK_MATLAB_TYPE(M,M_id,TYPE)   if(mxGetClassID(M)!=TYPE){\
                                            char BUFF[1024];\
                                                    sprintf(BUFF,"Expected type %d at argument %d",TYPE,M_id);\
                                                    mexErrMsgTxt(BUFF);\
}

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

///////////////////////////////////////////////////////////////////////////////
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    char* command = mxArrayToString(prhs[0]);
    //cout << "mex_video_processing: " << command << endl;

    // ------------------------------------------------------------------------
    if (strcmp(command,"init") == 0)
    {
        //cout << "mex_video_processing: " << command << endl;
        if (nrhs<5)
        {
            mexErrMsgTxt("Wrong number of arguments");
        }

        string filename;
        if (!mxIsEmpty(prhs[1]))
        {
            char *S;
            S = mxArrayToString(prhs[1]);
            filename = string(S);
            mxFree(S);
        }
        else
        {
            cout << "No filename specified" << endl;
        }

        RTVideoProcessing *pStr = 0;

        char *S;
        S = mxArrayToString(prhs[2]);
        string desc_type = string(S);
        mxFree(S);


        int num_VQs = mxGetM(prhs[3]);
        int descriptor_dim = mxGetN(prhs[3]);
        int webcam_no = *(mxGetPr(prhs[5]));

        unsigned int proc_width=0;
        unsigned int proc_height=0;
        if (nrhs>6)
        {
            proc_width=(mxGetPr(prhs[6]))[0];
            proc_height=(mxGetPr(prhs[6]))[1];
        }

        if (descriptor_dim != 66 &&descriptor_dim !=2 &&descriptor_dim !=0)
        {
            mexErrMsgTxt("Expected a 66/2/0-bin descriptor set");
        }

        bool do_vq = true;
        if (descriptor_dim == 0)
        {
            do_vq=false;
        }
        else
        {
            CHECK_MATLAB_TYPE(prhs[3],4,mxSINGLE_CLASS);
        }

        // create VQ matrix
        cv::Mat VQ;
        if (do_vq)
        {
            VQ=cv::Mat(num_VQs,descriptor_dim,CV_32FC1);
            for (int i = 0; i<num_VQs; ++i)
            {
                for (int j = 0; j<descriptor_dim; ++j)
                {
                    // VQ.at<float>(i,j) = ((float*)mxGetPr(prhs[3]))[i+j*num_VQs];
                    VQ.at<float>(i,j) = ((float*)mxGetPr(prhs[3]))[i+j*num_VQs];
                }
            }
        }
        plhs[0] = mxCreateNumericMatrix(1, 1, mxINT64_CLASS, mxREAL);

        // open capture source
        // TODO: parameterize magic number?
        pStr = new RTVideoProcessing(do_vq,VQ,desc_type,proc_width,proc_height,800);

        if (filename != "")
        {
            cout << "Opening video: " << filename << endl;
            pStr->open(filename);
        }
        else
        {
            cout << "Opening webcam: " << webcam_no << endl;
            pStr->open(filename,webcam_no);
        }

        // fprintf(stderr,"ptrs: %ld,%ld\n",info,tree);
        mexMakeArrayPersistent(plhs[0]);
        *((long*)mxGetPr(plhs[0])) = (long)(pStr);

    }

    // ------------------------------------------------------------------------
    else if (strcmp(command,"deinit") == 0)
    {
        //cout << "mex_video_processing: " << command << endl;
        if (nrhs<2)
        {
            mexErrMsgTxt("Wrong number of arguments");
        }
        RTVideoProcessing *pStr = (RTVideoProcessing *)(((long*)(mxGetPr(prhs[1])))[0]);
        //delete pStr->icp;
        delete pStr;

    }

    // ------------------------------------------------------------------------
    else if (strcmp(command,"newframe") == 0)
    {
        // cout << "mex_video_processing: " << command << endl;
        if (nrhs<2 || nlhs<2)
        {
            mexErrMsgTxt("Wrong number of arguments");
        }

        RTVideoProcessing *pStr = (RTVideoProcessing *)(((long*)(mxGetPr(prhs[1])))[0]);

        FrameDesc desc = pStr->process_next_frame();

        int ndim = 3;
        int dim[3];
        if (desc.isvalid)
        {
            dim[0] = desc.height;
            dim[1] = desc.width;
        }
        else
        {
            mexErrMsgTxt("Descriptor invalid..");
        }
        dim[2] = 3;

        plhs[1] = mxCreateNumericArray(ndim,dim, mxUINT8_CLASS, mxREAL);
        plhs[2] = mxCreateNumericMatrix(1, 1, mxDOUBLE_CLASS, mxREAL);
        unsigned int desc_cnt = 0;

        switch (pStr->desc_type)
        {
            case RTVideoProcessing::SURF:
            {

                plhs[0] = mxCreateNumericMatrix(desc.desc.size(), 1, mxSINGLE_CLASS, mxREAL);
                for (unsigned int i = 0; i<desc.desc.size(); ++i)
                {
                    desc_cnt += desc.desc[i];
                }

                unsigned int min_cnt = 10;
                for (unsigned int i = 0; i<desc.desc.size(); ++i)
                {
                    ((float *)mxGetPr(plhs[0]))[i] = desc.desc[i];
                }
            }
            break;
            case RTVideoProcessing::HSV:
            {

                plhs[0] = mxCreateNumericMatrix(desc.desc.size(), 1, mxSINGLE_CLASS, mxREAL);
                for (unsigned int i = 0; i<desc.desc.size(); ++i)
                {
                    desc_cnt += desc.desc[i];
                }

                unsigned int min_cnt = 10;
                for (unsigned int i = 0; i<desc.desc.size(); ++i)
                {
                    ((float *)mxGetPr(plhs[0]))[i] = desc.desc[i];
                }
            }
            break;
            case RTVideoProcessing::HOG:
            {
                plhs[0] = mxCreateNumericMatrix(desc.desc.size(), 1, mxSINGLE_CLASS, mxREAL);
                for (unsigned int i = 0; i<desc.desc.size(); ++i)
                {
                    ((float *)mxGetPr(plhs[0]))[i] = desc.desc[i];
                }
            }
            break;
            case RTVideoProcessing::NONE:
            {

                plhs[0] = mxCreateNumericMatrix(desc.desc.size(), 1, mxSINGLE_CLASS, mxREAL);
                for (unsigned int i = 0; i<desc.desc.size(); ++i)
                {
                    ((float *)mxGetPr(plhs[0]))[i] = 0;
                }
            }
            break;
        }
        if (desc.isvalid)
        {
            for (unsigned int y = 0; y<desc.height; ++y)
            {
                for (unsigned int x = 0; x<desc.width; ++x)
                {
                    Vec3b &color = desc.img.at<Vec3b>(y,x);
                    // mxGetPr(plhs[1])[(x*desc.height+y)] = color.val[2];
                    // mxGetPr(plhs[1])[(x*desc.height+y)+desc.height*desc.height] = color.val[1];
                    // mxGetPr(plhs[1])[(x*desc.height+y)+desc.height*desc.height*2] = color.val[0];
                    ((uchar*)mxGetPr(plhs[1]))[(x*desc.height+y)] = color.val[2];
                    ((uchar*)mxGetPr(plhs[1]))[(x*desc.height+y)+desc.width*desc.height] = color.val[1];
                    ((uchar*)mxGetPr(plhs[1]))[(x*desc.height+y)+desc.width*desc.height*2] = color.val[0];
                }
            }
        }

        // memcpy(mxGetPr(plhs[1]),desc.img.ptr<unsigned char>(0),desc.width*desc.height*3);
        mxGetPr(plhs[2])[0] = desc.frame_idx;

    }
    // ------------------------------------------------------------------------
    else if (strcmp(command,"newframedesc") == 0)
    {
        // cout << "mex_video_processing: " << command << endl;
        if (nrhs<2 || nlhs<2)
        {
            mexErrMsgTxt("Wrong number of arguments");
        }
        RTVideoProcessing *pStr = (RTVideoProcessing *)(((long*)(mxGetPr(prhs[1])))[0]);

        FrameDesc desc = pStr->extract_features();
        int ndim = 3;
        int dim[3];
        if (desc.isvalid)
        {
            dim[0] = desc.height;
            dim[1] = desc.width;
        }
        else
        {
            mexErrMsgTxt("Descriptor invalid..");
        }
        dim[2] = 3;

        plhs[1] = mxCreateNumericArray(ndim,dim, mxUINT8_CLASS, mxREAL);
        plhs[2] = mxCreateNumericMatrix(1, 1, mxDOUBLE_CLASS, mxREAL);
        unsigned int desc_cnt = 0;
        switch (pStr->desc_type)
        {
            case RTVideoProcessing::SURF:
            {
                unsigned int rows=desc.aux_img.size().height;
                unsigned int cols=desc.aux_img.size().width;
                plhs[0] = mxCreateNumericMatrix(rows,cols, mxSINGLE_CLASS, mxREAL);
                for (unsigned int i = 0; i<rows; ++i)
                {
                    for (unsigned int j = 0; j<cols; ++j)
                    {
                        access2DMatrix(((float *)mxGetPr(plhs[0])), i,j, rows,cols) =desc.aux_img.at<float>(i,j);
                    }
                }

                unsigned int min_cnt = 10;
            }
            case RTVideoProcessing::HSV:
            {
                unsigned int rows=desc.aux_img.size().height;
                unsigned int cols=desc.aux_img.size().width;
                plhs[0] = mxCreateNumericMatrix(rows,cols, mxSINGLE_CLASS, mxREAL);
                for (unsigned int i = 0; i<rows; ++i)
                {
                    for (unsigned int j = 0; j<cols; ++j)
                    {
                        access2DMatrix(((float *)mxGetPr(plhs[0])), i,j, rows,cols) =desc.aux_img.at<float>(i,j);
                    }
                }

                unsigned int min_cnt = 10;
            }
            break;
            case RTVideoProcessing::HOG:
            {
                plhs[0] = mxCreateNumericMatrix(desc.desc.size(), 1, mxSINGLE_CLASS, mxREAL);
                for (unsigned int i = 0; i<desc.desc.size(); ++i)
                {
                    ((float*)mxGetPr(plhs[0]))[i] = desc.desc[i];
                }
            }
            break;
            case RTVideoProcessing::NONE:
            {
                plhs[0] = mxCreateNumericMatrix(desc.desc.size(), 1, mxSINGLE_CLASS, mxREAL);
                for (unsigned int i = 0; i<desc.desc.size(); ++i)
                {
                    ((float*)mxGetPr(plhs[0]))[i] = 0;
                }
            }
            break;
        }
        if (desc.isvalid)
        {
            for (unsigned int y = 0; y<desc.height; ++y)
            {
                for (unsigned int x = 0; x<desc.width; ++x)
                {
                    Vec3b &color = desc.img.at<Vec3b>(y,x);
                    // mxGetPr(plhs[1])[(x*desc.height+y)] = color.val[2];
                    // mxGetPr(plhs[1])[(x*desc.height+y)+desc.height*desc.height] = color.val[1];
                    // mxGetPr(plhs[1])[(x*desc.height+y)+desc.height*desc.height*2] = color.val[0];
                    ((uchar*)mxGetPr(plhs[1]))[(x*desc.height+y)] = color.val[2];
                    ((uchar*)mxGetPr(plhs[1]))[(x*desc.height+y)+desc.width*desc.height] = color.val[1];
                    ((uchar*)mxGetPr(plhs[1]))[(x*desc.height+y)+desc.width*desc.height*2] = color.val[0];
                }
            }
        }

        // memcpy(mxGetPr(plhs[1]),desc.img.ptr<unsigned char>(0),desc.width*desc.height*3);
        mxGetPr(plhs[2])[0] = desc.frame_idx;

    }

    // ------------------------------------------------------------------------
    else if (strcmp(command,"skipframe") == 0)
    {
        // cout << "mex_video_processing: " << command << endl;
        if (nrhs<2)
        {
            mexErrMsgTxt("Wrong number of arguments");
        }
        RTVideoProcessing *pStr = (RTVideoProcessing *)(((long*)(mxGetPr(prhs[1])))[0]);
        pStr->skip_frame();

    }

    // ------------------------------------------------------------------------
    else if (strcmp(command,"setframe") == 0)
    {
        // cout << "mex_video_processing: " << command << endl;
        if (nrhs<3)
        {
            mexErrMsgTxt("Wrong number of arguments");
        }
        RTVideoProcessing *pStr = (RTVideoProcessing *)(((long*)(mxGetPr(prhs[1])))[0]);
        unsigned long frame = mxGetPr(prhs[2])[0];
        pStr->set_frame(frame);
    }

    // ------------------------------------------------------------------------
    else if (strcmp(command,"getinfo") == 0)
    {
        //cout << "mex_video_processing: " << command << endl;
        if (nrhs<2)
        {
            mexErrMsgTxt("Wrong number of arguments");
        }

        string filename;
        if (!mxIsEmpty(prhs[1]))
        {
            char *S;
            S = mxArrayToString(prhs[1]);
            filename = string(S);
            mxFree(S);

            vector<long> video_info = RTVideoProcessing::GetVideoInfo(filename);

            plhs[0] = mxCreateNumericMatrix(1,5,mxDOUBLE_CLASS,mxREAL);

            mxGetPr(plhs[0])[0] = video_info[0]; // num frames
            mxGetPr(plhs[0])[1] = video_info[1]; // width
            mxGetPr(plhs[0])[2] = video_info[2]; // heigt
            mxGetPr(plhs[0])[3] = video_info[3]; // fps
            
        }
        else
        {
            int webcam_no = *(mxGetPr(prhs[2]));
            
            //cerr << "No filename specified!" << endl;
            
            vector<long> video_info = RTVideoProcessing::GetVideoInfo(filename,webcam_no);

            plhs[0] = mxCreateNumericMatrix(1,5,mxDOUBLE_CLASS,mxREAL);

            mxGetPr(plhs[0])[0] = video_info[0]; // num frames
            mxGetPr(plhs[0])[1] = video_info[1]; // width
            mxGetPr(plhs[0])[2] = video_info[2]; // heigt
            mxGetPr(plhs[0])[3] = video_info[3]; // fps

        }

    }

    // ------------------------------------------------------------------------
    else
    {
        cout << "mex_video_processing: " << command << endl;
        mexErrMsgTxt("Unknown command");
    }

}

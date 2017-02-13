#include "RTVideoProcessing.h"
#include "SimpleProfiler.h"

FrameDesc RTVideoProcessing::process_next_frame()
{
    // cout << "Inside RTVideoProcessing" << endl;

#ifdef USE_LINUX_PROFILER
    SimpleProfiler *prof=SimpleProfiler::getInstance();
#endif

    FrameDesc frame_struct;

    if(!cap.isOpened()) // check if we succeeded
    {
        cerr << "Capture source not opened!" << endl;
        frame_struct.isvalid = false;
        return frame_struct;
    }

    if (!this->isUsingWebcam)
    {
        idx = cap.get(CV_CAP_PROP_POS_FRAMES);
        if (number_of_frames>0 && idx>=number_of_frames)
        {
            cout << "Reached end of file!" << endl;
            frame_struct.isvalid = false;
            return frame_struct;
        }
    }

#ifdef USE_LINUX_PROFILER
    prof->StartWatch("capture");
#endif
    cap >> frame;
#ifdef USE_LINUX_PROFILER
    prof->StopWatch("capture");
#endif

    if (frame.rows==0 || frame.cols==0)
    {
        frame_struct.isvalid = false;
        return frame_struct;

    }

#ifdef USE_LINUX_PROFILER
    prof->StartWatch("resize");
#endif

    if (proc_width>0)
    {
        cv::resize(frame,frame,cv::Size(proc_width,proc_height));
    }
    if (tx_width>0)
    {
        cv::resize(frame,tx_image,cv::Size(tx_width,tx_height));
    }
    else
    {
        tx_image=frame.clone();
    }

#ifdef USE_LINUX_PROFILER
    prof->StopWatch("resize");
#endif

    // unsigned int num_el=(unsigned int)(width*height);
    // Mat tmpImg(height,width,CV_32FC1);
    // Mat tmpImg2(height,width,CV_32FC1);
    // unsigned int gs_iter=20;
    // unsigned int iter=10;
    // float fidelity=1.f;
    // float r=10.f;

#ifdef USE_LINUX_PROFILER
    prof->StartWatch("cvtColor");
#endif

#ifdef USE_LINUX_PROFILER
    prof->StopWatch("cvtColor");
#endif

    frame_struct.img = tx_image.clone();
    frame_struct.width = tx_image.cols;
    frame_struct.height = tx_image.rows;

    // CPU code
    // gettimeofday( &start, 0);

    if (compute_bow)
    {
    cvtColor(frame, gray_image, CV_BGR2GRAY);
    cvtColor(frame, frame_hsv, CV_BGR2HSV);
    std::vector<cv::KeyPoint> keypoints_1;
        switch(desc_type)
        {
            case SURF:
            {
                // step 1: compute keypoints
#ifdef USE_LINUX_PROFILER
                prof->StartWatch("detect");
#endif
                surf_detector.detect(gray_image, keypoints_1);
#ifdef USE_LINUX_PROFILER
                prof->StopWatch("detect");
#endif

                // step 2: calculate descriptors (feature vectors)
                cv::Mat descriptors_1;
                cv::Mat descriptors_2;
                cv::Mat src_descriptors_add;

#ifdef USE_LINUX_PROFILER
                prof->StartWatch("compute");
#endif
                extractor.compute( gray_image, keypoints_1, descriptors_1 );
#ifdef USE_LINUX_PROFILER
                prof->StopWatch("compute");
#endif

                frame_struct.num_features = (unsigned int)keypoints_1.size();

                // step 3: matching descriptor vectors using FLANN matcher
                // cout << frame.rows << "x" << frame.cols << endl;

                src_descriptors_add = cv::Mat(descriptors_1.rows,2,descriptors_1.type());
                for (int i=0; i<keypoints_1.size(); ++i)
                {
                    int x=keypoints_1[i].pt.x;
                    int y=keypoints_1[i].pt.y;

                    // cout << "x,y: " << x << "," << y << endl;
                    cv::Vec3b &intensity = frame_hsv.at<cv::Vec3b>(y,x);
                    float hue = intensity.val[0]/255.f;
                    float sat = intensity.val[1]/255.f;

                    // float val = intensity.val[2]/255.f;
                    src_descriptors_add.at<float>(i,0)=hue;
                    src_descriptors_add.at<float>(i,1)=sat;

                    // scale by tx/proc dimensions
                    x = x*(((float)tx_height)/proc_height);
                    y = y*(((float)tx_width)/proc_width);

                    bool mask = ((float)x/(float)proc_width < 0.32) && ((float)y/(float)proc_height > 0.92);
                    if (!mask)
                    {
                        frame_struct.feat_xy.push_back((unsigned int)(x));
                        frame_struct.feat_xy.push_back((unsigned int)(y));
                    }
                }

                try
                {
                    if (!keypoints_1.empty())
                    {
                        // cout << "hconcat: "<<descriptors_1.rows<<"x"<<descriptors_1.cols<<","<<src_descriptors_add.rows<<"x"<<src_descriptors_add.cols<<"\n";
                        descriptors_2=cv::Mat(0,descriptors_1.cols+2,descriptors_1.type());
                        hconcat(descriptors_1,src_descriptors_add,descriptors_2);
                    }
                    else
                    {
                        descriptors_2=cv::Mat(0,descriptors_1.cols+2,descriptors_1.type());
                    }
                }
                catch(...)
                {
                    cerr << "error: hconcat" << endl;
                }

                // cv::transpose(descriptors_2, descriptors_2);
                // cout << "matching " << VQ.rows << "x" << VQ.cols << ", " << descriptors_2.rows << "x" << descriptors_2.cols << endl;

#ifdef USE_LINUX_PROFILER
                prof->StartWatch("match");
#endif
                matcher.match(descriptors_2,VQ, matches);
#ifdef USE_LINUX_PROFILER
                prof->StopWatch("match");
#endif

                // cout << "matched" << endl;
                unsigned long vote_cnt=0;
                // cout << "creating:" << resulting_descriptor_dim << "-long desc" << endl;
                frame_struct.desc=std::vector<float>(resulting_descriptor_dim);
                // cout << "adding features" << endl;
                // frame_struct.hist = std::vector<unsigned int>(descriptor_dim);
                for (int i = 0; i < matches.size(); i++)
                {
                    // histogram.at<int>(matches[i].trainIdx)++;
                    frame_struct.desc[matches[i].trainIdx]=frame_struct.desc[matches[i].trainIdx]+1.f;
                    vote_cnt++;
                }
            }

            // cout << "vote_cnt: " << vote_cnt << endl;
            break;

            case HSV:
            {
                // step 1: compute keypoints
#ifdef USE_LINUX_PROFILER
                prof->StartWatch("detect");
#endif
                surf_detector.detect(gray_image, keypoints_1);
#ifdef USE_LINUX_PROFILER
                prof->StopWatch("detect");
#endif

                // step 2: calculate descriptors (feature vectors)
                cv::Mat descriptors_1;
                cv::Mat descriptors_2;
                cv::Mat src_descriptors_add;

#ifdef USE_LINUX_PROFILER
                prof->StartWatch("compute");
#endif
                extractor.compute( gray_image, keypoints_1, descriptors_1 );
#ifdef USE_LINUX_PROFILER
                prof->StopWatch("compute");
#endif

                frame_struct.num_features = (unsigned int)keypoints_1.size();

                // step 3: matching descriptor vectors using FLANN matcher
                // cout << frame.rows << "x" << frame.cols << endl;

                src_descriptors_add = cv::Mat(descriptors_1.rows,2,descriptors_1.type());
                for (int i=0; i<keypoints_1.size(); ++i)
                {
                    int x=keypoints_1[i].pt.x;
                    int y=keypoints_1[i].pt.y;

                    // cout << "x,y: " << x << "," << y << endl;
                    cv::Vec3b &intensity = frame_hsv.at<cv::Vec3b>(y,x);
                    float hue = intensity.val[0]/255.f;
                    float sat = intensity.val[1]/255.f;

                    // float val = intensity.val[2]/255.f;
                    src_descriptors_add.at<float>(i,0)=hue;
                    src_descriptors_add.at<float>(i,1)=sat;

                    // scale by tx/proc dimensions
                    x = x*(((float)tx_height)/proc_height);
                    y = y*(((float)tx_width)/proc_width);

                    bool mask = ((float)x/(float)proc_width < 0.32) && ((float)y/(float)proc_height > 0.92);
                    if (!mask)
                    {
                        frame_struct.feat_xy.push_back((unsigned int)(x));
                        frame_struct.feat_xy.push_back((unsigned int)(y));
                    }
                }

                try
                {
                    if (!keypoints_1.empty())
                    {
                        // cout << "hconcat: "<<descriptors_1.rows<<"x"<<descriptors_1.cols<<","<<src_descriptors_add.rows<<"x"<<src_descriptors_add.cols<<"\n";
                        //descriptors_2=cv::Mat(0,descriptors_1.cols+2,descriptors_1.type());
                        //hconcat(descriptors_1,src_descriptors_add,descriptors_2);
                        descriptors_2=src_descriptors_add;
                    }
                    else
                    {
                        descriptors_2=cv::Mat(0,descriptors_1.cols+2,descriptors_1.type());
                    }
                }
                catch(...)
                {
                    cerr << "error: hconcat" << endl;
                }

                // cv::transpose(descriptors_2, descriptors_2);
                // cout << "matching " << VQ.rows << "x" << VQ.cols << ", " << descriptors_2.rows << "x" << descriptors_2.cols << endl;

#ifdef USE_LINUX_PROFILER
                prof->StartWatch("match");
#endif
                matcher.match(descriptors_2,VQ, matches);
#ifdef USE_LINUX_PROFILER
                prof->StopWatch("match");
#endif

                // cout << "matched" << endl;
                unsigned long vote_cnt=0;
                // cout << "creating:" << resulting_descriptor_dim << "-long desc" << endl;
                frame_struct.desc=std::vector<float>(resulting_descriptor_dim);
                // cout << "adding features" << endl;
                // frame_struct.hist = std::vector<unsigned int>(descriptor_dim);
                for (int i = 0; i < matches.size(); i++)
                {
                    // histogram.at<int>(matches[i].trainIdx)++;
                    frame_struct.desc[matches[i].trainIdx]=frame_struct.desc[matches[i].trainIdx]+1.f;
                    vote_cnt++;
                }
            }

            // cout << "vote_cnt: " << vote_cnt << endl;
            break;

            case HOG:
            {
                cv::HOGDescriptor hog;
                hog.blockSize=cv::Size(32,32);
                hog.cellSize=cv::Size(32,32);
                hog.blockStride=cv::Size(16,16);
                std::vector<float> desc_hog;
                std::vector<cv::Point> pts_hog;

                hog.compute( frame, desc_hog, cv::Size(128,128), cv::Size(0,0), pts_hog);
                frame_struct.desc=std::vector<float>(desc_hog.size());
                for (int i=0; i<desc_hog.size(); ++i)
                {
                    frame_struct.desc[i]=desc_hog[i];
                }
            }
            break;

            case NONE:
            {
                frame_struct.desc=std::vector<float>(resulting_descriptor_dim);
            }
            break;

        }
    }

    // cout << "match..\n";
    // cout << "descriptors_2: " << double(descriptors_2.type()==CV_32F) << "\n";
    // cout << descriptors_2.rows << "x" << descriptors_2.cols << "\n";
    // cout << "VQT: " << double(VQT.type()==CV_32F) << "\n";
    // cout << VQT.rows << "x" << VQT.cols << "\n";
    // cv::BFMatcher matcher_1(cv::NORM_L2);

    // float normalizing_factor=1.f/(fmaxf(vote_cnt,min_hist_count));
    // for (int i = 0; i < descriptor_dim; i++)
    // {
    //   frame_struct.hist[i] = histogram.at<unsigned int>(i);
    // }

    if (!frame.isContinuous())
    {
        cerr << "frame discontinuous!" << endl;
    }

#ifdef USE_LINUX_PROFILER
    prof->PrintWatches();
#endif

    // struct timeval finish;
    // gettimeofday(&finish, 0);
    // cout << "Found " << matches.size() << " matches: " <<  finish.tv_usec-start.tv_usec+1e6*(finish.tv_sec-start.tv_sec) << " usec" << endl;

    frame_struct.isvalid = true;
    ++idx;
    frame_struct.frame_idx=idx;

    return frame_struct;

}

FrameDesc RTVideoProcessing::extract_features()
{
    FrameDesc frame_struct;

    if(!cap.isOpened())   // check if we succeeded
    {
        cerr << "Capture source not opened!" << endl;
        frame_struct.isvalid = false;
        return frame_struct;
    }

    if (!this->isUsingWebcam)
    {
        idx = cap.get(CV_CAP_PROP_POS_FRAMES);
        if (number_of_frames>0 && idx>=number_of_frames)
        {
            cout << "Reached end of file!" << endl;
            frame_struct.isvalid = false;
            return frame_struct;
        }
    }

    cap >> frame;

    // imshow("image",frame);

    if (frame.rows==0 || frame.cols==0)
    {
        frame_struct.isvalid = false;
        return frame_struct;

    }

    if (proc_width>0)
    {
        cv::resize(frame,frame,cv::Size(proc_width,proc_height));
    }
    if (tx_width>0)
    {
        cv::resize(frame,tx_image,cv::Size(tx_width,tx_height));
    }
    else
    {
        tx_image=frame.clone();
    }

    cvtColor(frame, gray_image, CV_BGR2GRAY);
    // cvtColor(frame, gra, CV_BGR2GRAY);
    frame_hsv=cv::Mat(frame.size(),frame.type());
    // cv::Mat frame2=frame*(1.f/255.f);
    cvtColor(frame, frame_hsv, CV_BGR2HSV);
    // cvtColor(gray_image, frame_struct.img, CV_GRAY2BGR);
    frame_struct.img = tx_image.clone();
    frame_struct.width = tx_image.cols;
    frame_struct.height = tx_image.rows;
    // cerr<<"type: "<<frame_hsv.type()<<"\n";
    // CPU code
    gettimeofday( &start, 0);
    std::vector<cv::KeyPoint> keypoints_1;

    if (compute_bow)
    {
        switch(desc_type)
        {
            case SURF:
            {

                // Step 1: compute keypoints
                surf_detector.detect(gray_image, keypoints_1);
                // cv::Mat img_matches;
                // cv::drawKeypoints(frame, keypoints_1, img_matches );
                // cv::imshow("Matches", img_matches );
                // cv::waitKey(0);
                // cv::destroyWindow("Matches");

                // Step 2: calculate descriptors (feature vectors)
                cv::Mat descriptors_1;
                cv::Mat descriptors_2;
                cv::Mat src_descriptors_add;
                extractor.compute( gray_image, keypoints_1, descriptors_1 );
                frame_struct.num_features = (unsigned int)keypoints_1.size();

                // Step 3: matching descriptor vectors using FLANN matcher
                // cerr << frame.rows << "x" << frame.cols << endl;
                // cout << frame.rows << "x" << frame.cols << endl;

                src_descriptors_add = cv::Mat(descriptors_1.rows,4,descriptors_1.type());
                // cerr<<"descriptors type: "<<descriptors_1.type()<<"\n";
                for (int i=0; i<keypoints_1.size(); ++i)
                {
                    float x=keypoints_1[i].pt.x;
                    float y=keypoints_1[i].pt.y;
                    // cout << "x,y: " << x << "," << y << endl;
                    cv::Vec3b &intensity = frame_hsv.at<cv::Vec3b>(y,x);
                    // cv::Vec3b &intensity = frame_hsv.at<cv::Vec3b>(y,x);
                    // float sm = intensity.val[0]+intensity.val[1]+intensity.val[2]+0.05f;
                    float hue = intensity.val[0]/255.f;
                    float sat = intensity.val[1]/255.f;
                    // float val = intensity.val[2]/255.f;
                    src_descriptors_add.at<float>(i,0)=hue;
                    src_descriptors_add.at<float>(i,1)=sat;

                    // scale by tx/proc dimensions
                    x = (((float)x)*tx_height)/proc_height;
                    y = (((float)y)*tx_width)/proc_width;
                    if (fabs(x)>1e4)
                    {
                        cerr << "x,y(2): " << x << "," << y << endl;
                    }
                    src_descriptors_add.at<float>(i,2)=x;
                    src_descriptors_add.at<float>(i,3)=y;

                    frame_struct.feat_xy.push_back((unsigned int)(x));
                    frame_struct.feat_xy.push_back((unsigned int)(y));
                }

                try
                {
                    if (!keypoints_1.empty())
                    {
                        // cout << "hconcat: "<<descriptors_1.rows<<"x"<<descriptors_1.cols<<","<<src_descriptors_add.rows<<"x"<<src_descriptors_add.cols<<"\n";
                        descriptors_2=cv::Mat(0,descriptors_1.cols+4,descriptors_1.type());
                        hconcat(descriptors_1,src_descriptors_add,descriptors_2);
                    }
                    else
                    {
                        // cerr << "creating empty mat\n";
                        descriptors_2=cv::Mat(0,descriptors_1.cols+4,descriptors_1.type());
                    }
                }
                catch(...)
                {
                    cerr << "error: hconcat" << endl;
                }

                // cv::transpose(descriptors_2, descriptors_2);
                // cout << "matching " << VQ.rows << "x" << VQ.cols << ", " << descriptors_2.rows << "x" << descriptors_2.cols << endl;
                // matcher.match(descriptors_2,VQ, matches);
                // cerr << "matched\n";
                // cout << "matched" << endl;
                // unsigned long vote_cnt=0;
                // cout << "creating:" << resulting_descriptor_dim << "-long desc" << endl;

                frame_struct.aux_img=cv::Mat(descriptors_2.size(),descriptors_2.type());
                descriptors_2.copyTo(frame_struct.aux_img);
                // cout << "adding features" << endl;
                // frame_struct.hist = std::vector<unsigned int>(descriptor_dim);
                // for (int i = 0; i < matches.size(); i++)
                // {
                //    // histogram.at<int>(matches[i].trainIdx)++;
                //    frame_struct.desc[matches[i].trainIdx]=frame_struct.desc[matches[i].trainIdx]+1.f;
                //    vote_cnt++;
                // }
                // cout << "vote_cnt: " << vote_cnt << endl;

            }
            break;
            case HSV:
            {

                // Step 1: compute keypoints
                surf_detector.detect(gray_image, keypoints_1);
                // cv::Mat img_matches;
                // cv::drawKeypoints(frame, keypoints_1, img_matches );
                // cv::imshow("Matches", img_matches );
                // cv::waitKey(0);
                // cv::destroyWindow("Matches");

                // Step 2: calculate descriptors (feature vectors)
                cv::Mat descriptors_1;
                cv::Mat descriptors_2;
                cv::Mat src_descriptors_add;
                //extractor.compute( gray_image, keypoints_1, descriptors_1 );
                frame_struct.num_features = (unsigned int)keypoints_1.size();

                // Step 3: matching descriptor vectors using FLANN matcher
                // cerr << frame.rows << "x" << frame.cols << endl;
                // cout << frame.rows << "x" << frame.cols << endl;

                src_descriptors_add = cv::Mat(descriptors_1.rows,4,descriptors_1.type());
                // cerr<<"descriptors type: "<<descriptors_1.type()<<"\n";
                for (int i=0; i<keypoints_1.size(); ++i)
                {
                    float x=keypoints_1[i].pt.x;
                    float y=keypoints_1[i].pt.y;
                    // cout << "x,y: " << x << "," << y << endl;
                    cv::Vec3b &intensity = frame_hsv.at<cv::Vec3b>(y,x);
                    // cv::Vec3b &intensity = frame_hsv.at<cv::Vec3b>(y,x);
                    // float sm = intensity.val[0]+intensity.val[1]+intensity.val[2]+0.05f;
                    float hue = intensity.val[0]/255.f;
                    float sat = intensity.val[1]/255.f;
                    // float val = intensity.val[2]/255.f;
                    src_descriptors_add.at<float>(i,0)=hue;
                    src_descriptors_add.at<float>(i,1)=sat;

                    // scale by tx/proc dimensions
                    x = (((float)x)*tx_height)/proc_height;
                    y = (((float)y)*tx_width)/proc_width;
                    if (fabs(x)>1e4)
                    {
                        cerr << "x,y(2): " << x << "," << y << endl;
                    }
                    src_descriptors_add.at<float>(i,2)=x;
                    src_descriptors_add.at<float>(i,3)=y;

                    frame_struct.feat_xy.push_back((unsigned int)(x));
                    frame_struct.feat_xy.push_back((unsigned int)(y));
                }

                try
                {
                    if (!keypoints_1.empty())
                    {
                        // cout << "hconcat: "<<descriptors_1.rows<<"x"<<descriptors_1.cols<<","<<src_descriptors_add.rows<<"x"<<src_descriptors_add.cols<<"\n";
                        //descriptors_2=cv::Mat(0,descriptors_1.cols+4,descriptors_1.type());
                        //hconcat(descriptors_1,src_descriptors_add,descriptors_2);
                        descriptors_2=src_descriptors_add;
                    }
                    else
                    {
                        // cerr << "creating empty mat\n";
                        descriptors_2=cv::Mat(0,descriptors_1.cols+4,descriptors_1.type());
                    }
                }
                catch(...)
                {
                    cerr << "error: hconcat" << endl;
                }

                // cv::transpose(descriptors_2, descriptors_2);
                // cout << "matching " << VQ.rows << "x" << VQ.cols << ", " << descriptors_2.rows << "x" << descriptors_2.cols << endl;
                // matcher.match(descriptors_2,VQ, matches);
                // cerr << "matched\n";
                // cout << "matched" << endl;
                // unsigned long vote_cnt=0;
                // cout << "creating:" << resulting_descriptor_dim << "-long desc" << endl;

                frame_struct.aux_img=cv::Mat(descriptors_2.size(),descriptors_2.type());
                descriptors_2.copyTo(frame_struct.aux_img);
                // cout << "adding features" << endl;
                // frame_struct.hist = std::vector<unsigned int>(descriptor_dim);
                // for (int i = 0; i < matches.size(); i++)
                // {
                //    // histogram.at<int>(matches[i].trainIdx)++;
                //    frame_struct.desc[matches[i].trainIdx]=frame_struct.desc[matches[i].trainIdx]+1.f;
                //    vote_cnt++;
                // }
                // cout << "vote_cnt: " << vote_cnt << endl;

            }
            break;

            case HOG:
            {
                cv::HOGDescriptor hog;
                hog.blockSize=cv::Size(32,32);
                hog.cellSize=cv::Size(32,32);
                hog.blockStride=cv::Size(16,16);
                std::vector<float> desc_hog;
                std::vector<cv::Point> pts_hog;

                hog.compute( frame, desc_hog, cv::Size(128,128), cv::Size(0,0), pts_hog);
                frame_struct.desc=std::vector<float>(desc_hog.size());
                for (int i=0; i<desc_hog.size(); ++i)
                {
                    frame_struct.desc[i]=desc_hog[i];
                }
            }
            break;

            case NONE:
            {
                // suppress warning:
                // enumeration value 'NONE' not handled in switch [-Wswitch]
            }
            break;

        }
    }

    if (!frame.isContinuous())
    {
        cerr << "frame discontinuous!" << endl;
    }

    struct timeval finish;
    gettimeofday(&finish, 0);
    // cout << "found " << matches.size() << " matches: " << finish.tv_usec-start.tv_usec+1e6*(finish.tv_sec-start.tv_sec) << " usec" << endl;

    frame_struct.isvalid = true;
    ++idx;
    frame_struct.frame_idx=idx;

    return frame_struct;

}

void RTVideoProcessing::skip_frame()
{
    if (this->isUsingWebcam)
    {
        // using webcam: no need to skip
        return;
    }

    if(!cap.isOpened())   // check if we succeeded
    {
        cerr << "Capture source not opened!" << endl;
    }
    ++idx;

    if (number_of_frames>0 && idx>=number_of_frames)
    {
        // got to the end of the file
        cap.set(CV_CAP_PROP_POS_FRAMES,idx); // will be caught next processing
    }
    else
    {
        cap.grab();
    }

}

void RTVideoProcessing::set_frame(unsigned long frame)
{
    // check if we succeeded
    if(!cap.isOpened())
    {
        cerr << "Capture source not opened!" << endl;
    }

    cap.set(CV_CAP_PROP_POS_FRAMES,frame);
    idx = cap.get(CV_CAP_PROP_POS_FRAMES);
}

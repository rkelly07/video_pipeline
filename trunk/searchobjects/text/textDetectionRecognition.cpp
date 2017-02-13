#include "textDetectionRecognition.h"
#include <string>
#include <iostream>

void er_draw(vector<Mat> &channels, vector<vector<ERStat> > &regions, vector<Vec2i> group, Mat& segmentation)
{
    for (int r=0; r<(int)group.size(); r++)
    {
        ERStat er = regions[group[r][0]][group[r][1]];
        if (er.parent != NULL) // deprecate the root region
        {
            int newMaskVal = 255;
            int flags = 4 + (newMaskVal << 8) + FLOODFILL_FIXED_RANGE + FLOODFILL_MASK_ONLY;
            floodFill(channels[group[r][0]],segmentation,Point(er.pixel%channels[group[r][0]].cols,er.pixel/channels[group[r][0]].cols),
                      Scalar(255),0,Scalar(er.level),Scalar(0),flags);
        }
    }
}

bool isRepetitive(const string& s)
{
    int count = 0;
    for (int i=0; i<(int)s.size(); i++)
    {
        if ((s[i] == 'i') ||
                (s[i] == 'l') ||
                (s[i] == 'I'))
            count++;
    }
    if (count > ((int)s.size()+1)/2)
    {
        return true;
    }
    return false;
}

static PyObject* text_getStringFromPic(PyObject* self, PyObject* args) {

    char* PicName;
    if (!PyArg_ParseTuple(args, "s", &PicName)) {
	printf("ERROR");
        return NULL;
    }
    Mat src = imread(PicName);

    vector<Mat> channels;
 
    Mat grey;
    cvtColor(src,grey,COLOR_RGB2GRAY);
    // Notice here we are only using grey channel, see textdetection.cpp for example with more channels
    channels.push_back(grey);
    channels.push_back(255-grey);

    // Create ERFilter objects with the 1st and 2nd stage default classifiers
    Ptr<ERFilter> er_filter1 = createERFilterNM1(loadClassifierNM1("trained_classifierNM1.xml"),16,0.00015f,0.13f,0.2f,true,0.1f);
    Ptr<ERFilter> er_filter2 = createERFilterNM2(loadClassifierNM2("trained_classifierNM2.xml"),0.5);

    vector<vector<ERStat> > regions(channels.size());
    // Apply the default cascade classifier to each independent channel (could be done in parallel)

    for (int c=0; c<(int)channels.size(); c++)
    {
        er_filter1->run(channels[c], regions[c]);
        er_filter2->run(channels[c], regions[c]);
    }

    // Detect character groups

    vector< vector<Vec2i> > region_groups;
    vector<Rect> nm_boxes;
    erGrouping(src, channels, regions, region_groups, nm_boxes, ERGROUPING_ORIENTATION_HORIZ);
    //erGrouping(src, channels, regions, region_groups, nm_boxes, ERGROUPING_ORIENTATION_ANY, "./trained_classifier_erGrouping.xml", 0.5);

    /*Text Recognition (OCR)*/
	cout << "start OCRTesseract" << endl;
    Ptr<OCRTesseract> ocr = OCRTesseract::create();

    string output;

//    Mat out_img;
//    Mat out_img_detection;
//    Mat out_img_segmentation = Mat::zeros(image.rows+2, image.cols+2, CV_8UC1);
//    image.copyTo(out_img);
//    image.copyTo(out_img_detection);
//    float scale_img  = 600.f/image.rows;
//    float scale_font = (float)(2-scale_img)/1.4f;
    vector<string> words_detection;
    vector<Rect> boxes_detection;
    vector<float>  confidences_detection;


    for (int i=0; i<(int)nm_boxes.size(); i++)
    {

//        rectangle(out_img_detection, nm_boxes[i].tl(), nm_boxes[i].br(), Scalar(0,255,255), 3);
	cout << "current box is: " << nm_boxes[i].x << " " << nm_boxes[i].y << " " << nm_boxes[i].width << " " << nm_boxes[i].height << endl;
	if (nm_boxes[i].x < 0 || nm_boxes[i].width < 0 || nm_boxes[i].x + nm_boxes[i].width > src.cols || nm_boxes[i].y < 0 || nm_boxes[i].height < 0 || nm_boxes[i].y + nm_boxes[i].height > src.rows)
		continue;
        Mat group_img = Mat::zeros(src.rows+2, src.cols+2, CV_8UC1);
        er_draw(channels, regions, region_groups[i], group_img);
	group_img(nm_boxes[i]).copyTo(group_img);
/*	switch(i)
	{// open if you want to check the text box found
		case 1:
			imwrite("groupimg1.jpg", group_img);
		break;
		case 2:
			imwrite("groupimg2.jpg", group_img);
		break;
		case 3:
			imwrite("groupimg3.jpg", group_img);
		break;
		case 4:
			imwrite("groupimg4.jpg", group_img);
		break;
	}*/ 
//        Mat group_segmentation;
//        group_img.copyTo(group_segmentation);
//        src(nm_boxes[i]).copyTo(group_img);
//	rectangle(group_img, nm_boxes[i].tl(), nm_boxes[i].br(), Scalar(0,255,255), 3);

//        group_img(nm_boxes[i]).copyTo(group_img);
        copyMakeBorder(group_img,group_img,15,15,15,15,BORDER_CONSTANT,Scalar(0));

        vector<Rect>   boxes;
        vector<string> words;
        vector<float>  confidences;

	cout << "It's box" << i << endl;
        ocr->run(group_img, output, &boxes, &words, &confidences, OCR_LEVEL_WORD);
        output.erase(remove(output.begin(), output.end(), '\n'), output.end());
        cout << "OCR output = \"" << output << "\" lenght = " << output.size() << endl;
        if (output.size() < 3)
            continue;
	string outChecked;
	int wordValid = 0;
	float confidenceAvg = 0;
        for (int j=0; j<(int)boxes.size(); j++)
        {	
            boxes[j].x += nm_boxes[i].x;
            boxes[j].y += nm_boxes[i].y;

            cout << "  word = " << words[j] << "\t confidence = " << confidences[j] << endl;
            if ((words[j].size() < 2) || (confidences[j] < 51) ||
                    ((words[j].size()==2) && (words[j][0] == words[j][1])) ||
                    ((words[j].size()< 4) && (confidences[j] < 60)) ||
                    isRepetitive(words[j]))
                continue;
	    if(wordValid)outChecked += " ";// handle the blank between words;
	    wordValid ++;
	    outChecked += words[j];
	    confidenceAvg += confidences[j];
        }
	if(wordValid)
	{
	    words_detection.push_back(outChecked);
	    boxes_detection.push_back(nm_boxes[i]);
	    confidences_detection.push_back(confidenceAvg/wordValid);
	}
    }

    // memory clean-up
    er_filter1.release();
    er_filter2.release();
    regions.clear();
    if (!nm_boxes.empty())
    {
        nm_boxes.clear();
    }
    PyObject* textList = PyList_New(0);

    for(int i = 0; i < (int)words_detection.size(); i++)
    {
	PyObject* dict = PyDict_New();
//	PyDict_SetItem(dict, Py_BuildValue("s", "frameNo"),  Py_BuildValue("i", frameNo));
	PyDict_SetItem(dict, Py_BuildValue("s", "x1"),  Py_BuildValue("i", boxes_detection[i].tl().x));
	PyDict_SetItem(dict, Py_BuildValue("s", "y1"),  Py_BuildValue("i", boxes_detection[i].tl().y));
	PyDict_SetItem(dict, Py_BuildValue("s", "x2"),  Py_BuildValue("i", boxes_detection[i].br().x));
	PyDict_SetItem(dict, Py_BuildValue("s", "y2"),  Py_BuildValue("i", boxes_detection[i].br().y));
	PyDict_SetItem(dict, Py_BuildValue("s", "text"),  Py_BuildValue("s", words_detection[i].c_str()));
	PyDict_SetItem(dict, Py_BuildValue("s", "confidences"),  Py_BuildValue("f", confidences_detection[i]));

	PyList_Append(textList, dict);
    }
    return textList;
}

static PyMethodDef text_methods[] = {
    {"getStringFromPic",(PyCFunction)text_getStringFromPic,METH_VARARGS,NULL},
    {NULL,NULL,0,NULL}
};

PyMODINIT_FUNC inittext() {
    Py_InitModule3("text", text_methods, "Relax getStringFromPic");
}



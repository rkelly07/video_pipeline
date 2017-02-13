import numpy as np
import cv2
import cv
import time
#import matplotlib.pyplot as plt


frame_nums = [130]

cap = cv2.VideoCapture('videos/20150205_155823.mp4')
corner1 = (1,261)
corner2 = (188, 1000)

frames_count, fps, width, height = cap.get(cv2.cv.CV_CAP_PROP_FRAME_COUNT), cap.get(cv2.cv.CV_CAP_PROP_FPS), cap.get(cv2.cv.CV_CAP_PROP_FRAME_WIDTH), cap.get(cv2.cv.CV_CAP_PROP_FRAME_HEIGHT)

print frames_count, fps, width, height

'''
for frame_num in frame_nums:
    print frame_num
    cap.set(cv2.cv.CV_CAP_PROP_POS_FRAMES,frame_num) #Set index to last frame

    ret, img = cap.read()
    res = cv2.resize (img, (600, 1000), interpolation = cv2.INTER_CUBIC)
    cv2.rectangle(res,corner1,corner2,(0,255,0),3)
    cv2.namedWindow('frame', cv2.WINDOW_NORMAL)
    cv2.imshow('frame',res)
    #cv2.imwrite("images/test.jpg", img)
    cv2.waitKey()
    break
    #window = cv.NamedWindow("frame", cv.CV_WINDOW_AUTOSIZE)
    #namedWindow("MyVideo",CV_WINDOW_AUTOSIZE);

    screen_res = 1280, 720
    scale_width = screen_res[0] / 600.0
    scale_height = screen_res[1] / 1000.0
    scale = min(scale_width, scale_height)
    window_width = int(600.0 * scale)
    window_height = int(1000.0 * scale)

    #cv2.namedWindow('dst_rt', cv2.WINDOW_NORMAL)
    cv2.resizeWindow('dst_rt', 600, 1000)
    cv2.rectangle(img,corner1,corner2,(0,255,0),3)
   


    cv2.imshow('dst_rt', img)
    cv2.waitKey(0)
'''  
    




frame_count=0
while(cap.isOpened()):
    ret, frame = cap.read()
    #print frame
    print frame_count
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    cv2.rectangle(frame,(384,0),(510,128),(0,255,0),5)

    cv2.imshow('frame',frame)
    
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

    if frame_count == 130:
        break
    frame_count += 1


#length = int(cap.get(cv2.cv.CV_CAP_PROP_FRAME_COUNT))


cap.release()
cv2.destroyAllWindows()

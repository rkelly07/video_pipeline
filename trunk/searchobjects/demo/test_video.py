import numpy as np
import cv2
import cv
import time
#import matplotlib.pyplot as plt


frame_nums = [5, 10, 15, 20, 25, 35, 40, 45]

cap = cv2.VideoCapture('static/demo/videos/test.mp4')
corner1 = (1,261)
corner2 = (188, 1000)

frames_count, fps, width, height = cap.get(cv2.cv.CV_CAP_PROP_FRAME_COUNT), cap.get(cv2.cv.CV_CAP_PROP_FPS), cap.get(cv2.cv.CV_CAP_PROP_FRAME_WIDTH), cap.get(cv2.cv.CV_CAP_PROP_FRAME_HEIGHT)

print frames_count, fps, width, height

while(True):
    # Capture frame-by-frame
    ret, frame = cap.read()

    # Our operations on the frame come here
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

    # Display the resulting frame
    cv2.imshow('frame',gray)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# When everything done, release the capture
cap.release()
cv2.destroyAllWindows()
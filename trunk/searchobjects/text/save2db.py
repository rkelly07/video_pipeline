import sys
#sys.path.append('/scratch/relax/opencv2.4.10.1-install/lib/python2.7/dist-packages')
sys.path.append('/scratch/relax/rtvproc_install/lib')
sys.path.append('/home/serverdemo/video_analysis/trunk/searchobjects/demo')
import cv2
import text
import psycopg2
from coreset_structure import CoresetStructure
#coreset_path = '/scratch/relax/coreset_results/simpler_tree_0716095153.mat'

def hello():
    return 3

def updateTextInfo2DB(video_scene_id):
    print "connecting to db.."
    params = {
      'dbname': 'postgres',
      'user': 'postgres',
      'password': '?D8yr5^5',
      'host': 'localhost',
      'port': 5432
    }    
    conn = psycopg2.connect(**params)
    print "connected to db."
    cur = conn.cursor()
#    cur.execute("SELECT * FROM app_scene")
#    x = cur.fetchall()   

#    print "coreset selection"
    cur.execute("SELECT simple_coreset_path FROM app_coreset where scene_id = %i" % video_scene_id)
    coreset_simple_file = cur.fetchone()
    cur.execute("SELECT path FROM app_scene where id = %i" % video_scene_id)
    video_file_path = cur.fetchone()
    
#    cur.execute("SELECT id FROM app_scene where path = '%s'" % video_file_path)
    
#    video_scene_id = cur.fetchone()[0]
    
    coreset_str = CoresetStructure(coreset_simple_file[0])
    keyframes = coreset_str.get_keyframes()
    print "Key Frames are", keyframes
    cap = cv2.VideoCapture(video_file_path[0])
#    TextSchemaList = []
    for KeyFrame in keyframes:
        #at this point, if there is no cap, throw error
        if cap==None or not cap or (not cap.isOpened()):
            print "Error!! Vedeocapture failed.. Unable to open the video file ", cur_scene.path
            return HttpResponse("Video capture is Null. Unable to open video file", cur_scene.path)
        cap.set(cv2.cv.CV_CAP_PROP_POS_FRAMES,KeyFrame)
        ret, img = cap.read()        
        cv2.imwrite("temp.jpg", img)
        listtext = text.getStringFromPic('temp.jpg')    
        for curText in listtext:
            cur.execute("INSERT INTO app_text_detection VALUES (%s, %s, %s, %s, %s, %s, %s, %s)", (video_scene_id, int(KeyFrame), curText['x1'], curText['x2'], curText['y1'], curText['y2'], curText['text'], curText['confidences'], ))
            conn.commit()
        cur.execute("SELECT * FROM app_text_detection")
        x = cur.fetchall() 
        print x
    cap.release()
    
    
    cur.close()
    conn.close()

#(scene_id, frame, x1, y1, x2, y2, detected_text, confidence) \
#textSchemaList = updateTextInfo2DB(406)
#video = '/home/serverdemo/LOCAL_DATA/videos/text_det_video.mp4';
#simple_file = '/home/serverdemo/video_analysis/trunk/rtvproc/simpler_coreset_results/simple_text_det_video_coreset_tree_319_100_0814162535.mat';
#updateTextInfo2DB(video, simple_file);
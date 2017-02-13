### Helper functions for views.py
### Only the main functions (i.e. callable by clients) are defined there,
### and any sub-functions they should call are defined in here

import os
import cv2
from django.conf import settings
import ntpath
import subprocess
from django.http import HttpResponse
import numpy as np
import time
from scipy import io

#Global variables

SAVE_IMG_TEMP_FOLDER = "demo/images/temp/" #relative to static root. save the fetched images temporarily in this folder
RETURN_VIDEO_FILENAME_LEN = 10 #if video filename is too long, showing it in frontend gives bad layout, so shorten it before sending
MATLAB_VIDEO_PROCESS_FILE = '/home/serverdemo/video_analysis/trunk/rtvproc/process_uploaded_videos.m'
#MATLAB_LD_PRELOAD = '/home/serverdemo/rtvproc_install/lib/libRTVideoProcessing.so:/home/serverdemo/OpenCV/opencv-2.4.10_install/lib/libopencv_nonfree.so:/home/serverdemo/OpenCV/opencv-2.4.10_install/lib/libopencv_core.so:/home/serverdemo/OpenCV/opencv-2.4.10_install/lib/libopencv_gpu.so:/home/serverdemo/OpenCV/opencv-2.4.10_install/lib/libopencv_highgui.so:/home/serverdemo/OpenCV/opencv-2.4.10_install/lib/libopencv_video.so:/home/serverdemo/OpenCV/opencv-2.4.10_install/lib/libopencv_contrib.so:/home/serverdemo/OpenCV/opencv-2.4.10_install/lib/libopencv_calib3d.so:/home/serverdemo/OpenCV/opencv-2.4.10_install/lib/libopencv_flann.so'
SAVE_KEYFRAMES_FOLDER = "demo/images/temp/keyframes/"

NUM_KEYFRAMES_TO_SELECT = 2 #how many keyframes to select from each node?


def save_and_get_images(regions, frame_gap):
    frame_ignore_gap = frame_gap #the frames within this frames of one another are discarded. Eg. if prev_frame is 5, 
    # and the same object in any of cur_frame 6, 7, .. upto 5+frame_ignore_gap, those are ignored for sake of 
    #reducing clutter to user, 
    #print "Saving images and fetching them.."
    prev_frame = None
    cap = None
    ret, img = None, None
    img_num = 0
    image_paths = []
    max_confidence = -2
    prev_region = None
    prev_scene = None
    for region in regions:
        cur_scene = region.scene
        cur_frame = int(region.frame)
        if not os.path.exists(cur_scene.path):
            continue;

        #discard if the cur_frame is too close to prev_frame
        if prev_frame != None and (cur_frame>prev_frame) and \
           (cur_frame - prev_frame) <= frame_ignore_gap \
           and prev_scene.id == cur_scene.id:
            continue;


        #Open cap if the scene id changes
        if prev_scene == None or prev_scene.id != cur_scene.id:
            cap = cv2.VideoCapture(cur_scene.path)

        #at this point, if there is no cap, throw error
        if cap==None or not cap or (not cap.isOpened()):
            print "Error!! Vedeocapture failed.. Unable to open the video file ", cur_scene.path
            return HttpResponse("Video capture is Null. Unable to open video file", cur_scene.path)


        #if frame changes, save current img and create new img
        if cur_frame != prev_frame or prev_scene == None or prev_scene.id != cur_scene.id: #new frame
            if img != None:
                image_descr = save_image_and_get_descr(img, img_num, max_confidence,prev_region)
                image_paths.append(image_descr)
                img = None

            max_confidence = -2
            cap.set(cv2.cv.CV_CAP_PROP_POS_FRAMES,cur_frame-1)
            ret, img = cap.read()
	    if img == None:
		print "This is a bad thing. There is frame given but cap can't read. Debug"
		continue
            img = cv2.resize (img, (region.scene.width, region.scene.height), interpolation = cv2.INTER_CUBIC)
	    #cv2.imread('image',img);
            #cap.set(cv2.cv.CV_CAP_PROP_POS_FRAMES,0) #reset cap to zero
            img_num += 1

        if region.confidence > max_confidence:
            max_confidence = float("{0:.2f}".format(region.confidence)) #too long float, reducing to 2 dec places


        #draw rectangle in current region
        x1_y1 = (region.x1, region.y1)
        x2_y2 = (region.x2, region.y2)
        cv2.rectangle(img,x1_y1,x2_y2,(0,int(round(255*max(min((region.confidence+1)/4.0,1.0),0.0))),0),3)
        prev_region = region
        prev_frame = cur_frame
        prev_scene = cur_scene

    #after for loop, if cap isn't released or there is an image to be saved, do those
    if cap != None:
        cap.release()
    if img != None:
        image_descr = save_image_and_get_descr(img, img_num, max_confidence,prev_region)
        image_paths.append(image_descr)

    return image_paths



def save_image_and_get_descr(img, img_num, max_confidence,region):
    frame = int(region.frame)
    importance = 0
    if hasattr(region, 'importance'):
	importance = float(region.importance)
    static_path = settings.STATIC_ROOT
    img_save_path = SAVE_IMG_TEMP_FOLDER 
    #print "saving image to", img_save_path
    #unique_img_name = str(region.scene_id) + "_" +str(region.label_id) +"_"+str(region.frame)+"_" +str(img_num)+".jpg";
    unique_img_name = str(region.scene_id) +"_"+str(region.frame)+"_" +str(img_num)+"_"+str(int(time.time()))+".jpg";
    cv2.imwrite(static_path+ img_save_path+unique_img_name, img) #will create the folder if not exist
    g_val = int(round(255*max(min((max_confidence+1)/4.0,1.0),0.0)));
    color_text = "rgb(0,"+str(g_val)+",0)"
    video_file = extract_filename(region.scene.path)
    if len(video_file) > RETURN_VIDEO_FILENAME_LEN + 3:
        video_file = video_file[:RETURN_VIDEO_FILENAME_LEN] + "...";
    image_descr = [img_save_path+unique_img_name, frame, max_confidence, color_text, video_file, importance]
    return image_descr




#extracts the tail from the full path, e.g. /home/Documents/hello.txt => hello.txt
def extract_filename(fullpath):
    head, tail = ntpath.split(fullpath)
    return tail or ntpath.basename(head)



#TODO: Incomplete function, it should run a matlab file with subprocess.Popen (or similar alternative) so that MATLAB file
#runs in background but the code here still goes on. Input is only the filename. The GPS files are stored in media/uploads/gps_files.
# Note that if we have multiple files with same name, they are stored with suffix filename_i for ith duplicate. For demo, this won't be
# a problem because we will have different file names, or if we have same filename, it's the same file, so we don't need to do additional
# processing. But for long term, we should think about this. 
def process_gps_file(gps_file_name):
    return





#TODO:
#TODO: Incomplete function, it should run a matlab file with subprocess.Popen (or similar alternative) so that MATLAB file
#runs in background but the code here still goes on. Input is only the filename. The video files are stored in media/uploads/videos.
# Note that if we have multiple files with same name, they are stored with suffix filename_i for ith duplicate. For demo, this won't be
# a problem because we will have different file names, or if we have same filename, it's the same file, so we don't need to do additional
# processing. But for long term, we should think about this. 
def process_video_file(video_file_name):
    if len(video_file_name.strip())>0:
        env = dict(os.environ)
        env['LD_PRELOAD'] = MATLAB_LD_PRELOAD;
        subprocess.Popen(["matlab", "-nodesktop", "-nosplash", "-r", 
                          "run(\'"+MATLAB_VIDEO_PROCESS_FILE+"\');"], env=env)


#This saving is for keyframes in summarization
def save_keyframes(video_path, data):
    #print "Saving keyframes..."
    #print "The nodes data is", data   
    cap = cv2.VideoCapture(video_path)
    if cap==None or not cap or (not cap.isOpened()):
	print "Error!! Vedeocapture failed.. Unable to open the video file ", cur_scene.path
	return HttpResponse("Video capture is Null. Unable to open video file", cur_scene.path)    
    video_name = extract_filename(video_path)
    video_name = "_".join(video_name.split('.'))
    return_node_data = []
    for node in data:
	node_dict = {}
        frame_paths = []
	filtered_keyframe_paths = []
        keyframes = node['KeyFrames']
	
	best_frame_indices = get_best_frame_indices(node, NUM_KEYFRAMES_TO_SELECT)
	frame_index = 0
        for frame in keyframes:
            cap.set(cv2.cv.CV_CAP_PROP_POS_FRAMES,frame)
            ret, img = cap.read()
	    #cv2.imshow('frame', img)
            #img = cv2.resize (img, (150, 150), interpolation = cv2.INTER_CUBIC)
	    static_path = settings.STATIC_ROOT
            frame_path = SAVE_KEYFRAMES_FOLDER+video_name+"_"+str(frame)+".jpg";
	    try:
		cv2.imwrite(static_path + frame_path, img)
	    except:
		print "Couldn't save ",frame_path
            frame_paths.append(frame_path)
	    
	    if frame_index in best_frame_indices:
		filtered_keyframe_paths.append(frame_path)
	    frame_index = frame_index + 1
	#fill node info in node_dict
	node_dict['KeyFramePaths'] = frame_paths
	node_dict['FilteredKeyFramePaths'] = filtered_keyframe_paths
	description = ""
	for dict_key in node.keys():
	    description += str(dict_key) + ": "+str(node[dict_key]) + " "
	node_dict['Description'] = description
        return_node_data.append(node_dict)

    return return_node_data



def get_best_frame_indices(node, num_keyframes_to_select):
    tfrac = node['tFrac']
    '''
    max_t_list = []
    best_frame_indices = []
    for t_i in range(len(tfrac)):
	t = tfrac[t_i]
	if len(max_t_list) < num_keyframes_to_select:
	    max_t_list.append(t)
	    best_frame_indices.append(t_i)
	else:
    '''
	    
    return sorted(np.argsort(tfrac)[::-1][:num_keyframes_to_select]) #indices of n max elements


#summarizing based on depth of the tree
def parse_mat_and_save_depth_keyframes(video_path, mat_path, tree_depth):
    #first load the mat file
    mat = io.loadmat(mat_path)
    coreset_tree = mat['simple_coreset']

    keyframe_data = [];

    depth = 0
    if tree_depth == "0" or len(tree_depth.strip())==0: #root summarization
        depth = 0

    elif tree_depth == "inf":
        leaf_nodes = get_leaf_nodes(coreset_tree)
    else:
	try:
	    depth = int(tree_depth)
	except:
	    return HttpResponse("Write the correct depth format. It's either an integer or the input inf.") 
	
    if depth < 0:
	return HttpResponse("No negative depth please, or if you want 0 depth, just write 0") 
    
    tree_str = coreset_tree['TreeStructure'][0][0][0]
    if tree_depth == 'inf':
	depth_nodes = leaf_nodes
    else:
	depth_nodes = sorted(get_nodes_at_depth(depth, tree_str)) #TODO: is sorted needed?
    tree_nodes = coreset_tree['Nodes'][0][0][0]
    for node_num in depth_nodes:
	extra_info = {'NodeNum':node_num, 'Depth':depth}
	node_data = get_node_data(node_num, tree_nodes, extra_info)
	keyframe_data.append(node_data)	    
    return save_keyframes(video_path, keyframe_data)


def get_nodes_at_depth(depth, tree_str):
    root_node = len(tree_str) #TODO: check with Mikhail if it's always true
    depth_temp = 0
    cur_nodes = [root_node]
    while depth_temp < depth:
	child_nodes = get_child_nodes(cur_nodes, tree_str)
	depth_temp += 1
	cur_nodes = child_nodes
    return cur_nodes


#TODO: can we make it more efficient?
def get_child_nodes(nodes, tree_str):
    child_nodes = []
    for node in nodes:
	#find indices that equal to this node
	   children = [i+1 for i in range(len(tree_str)) if node==tree_str[i]] #TODO: this is the main culprit.. takes O(n) time
	   child_nodes.extend(children)
    return child_nodes




#summarizing based on height from the leaves
def parse_mat_and_save_height_keyframes(video_path, mat_path, tree_height):
    #first load the mat file
    mat = io.loadmat(mat_path)
    coreset_tree = mat['simple_coreset']
    keyframe_data = []

    if tree_height == "0" or len(tree_height.strip())==0: #leaves summarization
	height= 0
    else:
	try:
	    height= int(tree_height)
	except:
	    return HttpResponse("Write the correct height format. It's either an integer or blank.")
	
    if height< 0:
	return HttpResponse("No negative height please.")	
    
    leaf_nodes = get_leaf_nodes(coreset_tree)
    tree_str = coreset_tree['TreeStructure'][0][0][0]
    if height == 0:
	height_nodes = leaf_nodes
    else:
	height_nodes = sorted(get_nodes_at_height(height, tree_str, leaf_nodes)) #TODO: is sorted needed?
	
    tree_nodes = coreset_tree['Nodes'][0][0][0]
    for node_num in height_nodes:
	extra_info = {'NodeNum':node_num, 'Height':height}
        node_data = get_node_data(node_num,tree_nodes, extra_info)
        keyframe_data.append(node_data)     
    return save_keyframes(video_path, keyframe_data)



def get_leaf_nodes(coreset_tree):
    leaf_nodes = []
    nodes = coreset_tree['Nodes'][0][0][0]
    for node_num in range(len(nodes)):
	node = nodes[node_num]
	node_type = node['NodeType'][0]
	if node_type == 'Leaf':
	    #node_num are index+1
	    leaf_nodes.append(node_num + 1)
    return leaf_nodes


def get_nodes_at_height(height, tree_str, leaf_nodes):
    return_nodes = []
    height_temp = 0
    cur_nodes = leaf_nodes
    while height_temp < height:
	return_nodes = get_parent_nodes(cur_nodes, tree_str)
	cur_nodes = return_nodes
	height_temp += 1
    return return_nodes


#nodes are the integer node_nums
def get_parent_nodes(nodes, tree_str):
    parent_nodes = []
    for node_num in nodes:
	node_ind = node_num - 1
	par_node = tree_str[node_ind]
	if par_node not in parent_nodes:
	    parent_nodes.append(par_node)
    return parent_nodes


def prune_and_save_keyframes(video_path, mat_path, prune_type, threshold):
    mat = io.loadmat(mat_path)
    coreset_tree = mat['simple_coreset']
    keyframe_data = []
    tree_nodes = coreset_tree['Nodes'][0][0][0]
    tree_str = coreset_tree['TreeStructure'][0][0][0]
    
    root_node = len(tree_str) #TODO: check with Mikhail if it's always true
    depth_temp = 0
    cur_nodes = [root_node]
    
    nodes_to_display = {}
    
    crawling_tree = True
    while crawling_tree:
	nodes_to_explore = []
	for node_num in cur_nodes:
	    variability = get_variability(node_num, coreset_tree, prune_type)
	    tree_node = tree_nodes[node_num-1]
	    node_start = tree_node['FrameSpan'][0][0]
	    node_end = tree_node['FrameSpan'][0][1]
	    node_span = node_end - node_start + 1
	    #TODO: What to do with node_span? Should the threshold people input be 
	    # for the distance metric or including node_span?
	    if variability >= threshold:
		nodes_to_explore.append(node_num)
	    else:
		node_dict = {}
		node_dict['NodeNum'] = node_num
		node_dict['Variability'] = variability
		nodes_to_display[node_num] = node_dict
	if len(nodes_to_explore) == 0:
	    crawling_tree = False
	    break
	child_nodes = get_child_nodes(nodes_to_explore, tree_str)
	if len(child_nodes) == 0: #came to leaves
	    for node_num in nodes_to_explore:
		nodes_to_display.append(node_num)
	    crawling_tree = False
	    break
	cur_nodes = child_nodes
	
    #put data in the nodes_to_display
    for node_num in sorted(nodes_to_display.keys()):	
	extra_info = nodes_to_display[node_num]
	node_data = get_node_data(node_num, tree_nodes, extra_info)
	keyframe_data.append(node_data)	
	
    return save_keyframes(video_path, keyframe_data)
    
    
def get_node_data(node_num, tree_nodes, extra_info = False):
    
    tree_node = tree_nodes[node_num-1]
    node_data = {}
    keyframes = tree_node['KeyFrames'][0]
    node_data['KeyFrames'] = keyframes
    
    t_frac = tree_node['tFrac'][0]
    node_data['tFrac'] = t_frac
    
    if extra_info:
	for info in extra_info.keys():
	    node_data[info] = extra_info[info]
    
    return node_data   

def get_variability(node_num, coreset_tree, prune_type):
    # the variability measures are "avg_distance", "smallest_distance", 
    #"largest_distance", "num_coreset_segs", "num_frames", "blur_measure"
    
    #variability_measure = "avg_dist" #threshold 7 gave first 3 in the demo coreset
    variability_measure = prune_type
    #the sum variability
    if variability_measure == "avg_dist":
	return get_avg_dist_variability(node_num, coreset_tree)
    elif variability_measure == "min_dist":
	return get_smallest_dist_variability(node_num, coreset_tree)
    elif variability_measure == "max_dist":
	return get_largest_dist_variability(node_num, coreset_tree)
    else:
	return 0
    



def get_consecutive_keyframe_distances(keyframes):
    dist_list = []
    for i in range(len(keyframes) -1):
	dist = keyframes[i+1] - keyframes[i]
	dist_list.append(dist)
    return dist_list


def get_avg_dist_variability(node_num, coreset_tree):
    tree_nodes = coreset_tree['Nodes'][0][0][0]
    tree_node = tree_nodes[node_num -1]    
    keyframes = tree_node['KeyFrames'][0]
    print "Node num is", node_num
    print "keyframes are", keyframes
    dist_list = get_consecutive_keyframe_distances(keyframes)
    avg_dist = sum(dist_list)/float(len(dist_list))
    return avg_dist


def get_smallest_dist_variability(node_num, coreset_tree):
    tree_nodes = coreset_tree['Nodes'][0][0][0]
    tree_node = tree_nodes[node_num -1]    
    keyframes = tree_node['KeyFrames'][0]    
    dist_list = get_consecutive_keyframe_distances(keyframes)
    
    min_dist = min(dist_list)
    
    return min_dist

def get_largest_dist_variability(node_num, coreset_tree):
    tree_nodes = coreset_tree['Nodes'][0][0][0]
    tree_node = tree_nodes[node_num -1]    
    keyframes = tree_node['KeyFrames'][0]    
    print "Node num is", node_num
    print "keyframes are", keyframes    
    dist_list = get_consecutive_keyframe_distances(keyframes)
    
    max_dist = max(dist_list)
    return max_dist


def has_coreset_segs_variability(node_num, coreset_tree, threshold):
    return False

def has_frames_variability(node_num, coreset_tree, threshold):
    return False

def has_blur_variability(node_num, coreset_tree, threshold):
    return False


def get_total_importance(images_dict):
    imp_sum = 0
    for images_list in images_dict.values():
	for image in images_list:
	    if len(image)>5:
		imp_val = image[5]
		imp_sum += imp_val
    return imp_sum
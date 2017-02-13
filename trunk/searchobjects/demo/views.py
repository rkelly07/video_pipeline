from django.shortcuts import render_to_response
from demo.models import *
from django.http import HttpResponse

from django.template import RequestContext
from django.http import HttpResponseRedirect
from demo.forms import DocumentForm
import traceback
import os
import pdb
import time

import cProfile

from views_helper import *
from coreset_structure import CoresetStructure
from coreset_retrieval import *
import json

import threading
import time
from logger import SearchObjectsLogger

#GLOBAL VARIABLES
SUMMARIZE_VIDEO_PATH = '/home/serverdemo/LOCAL_DATA/summarization/video1/test.mp4' #later found from db, in the function below
SUMMARIZE_MAT_PATH = '/home/serverdemo/video_analysis/trunk/rtvproc/simpler_coreset_results/simpler_tree_0408184702.mat' #later use db
sessions_images_dict = {}
UPLOAD_LOG_FILE = '/home/serverdemo/demo_results/logs/upload_log.txt'
RETRIEVE_LOG_FILE = '/home/serverdemo/demo_results/logs/retrieve_log.txt'

def index(request):
    form = DocumentForm() # A empty, unbound form
    return render_to_response('demo/index.html',{'form': form}, context_instance=RequestContext(request))



def upload_video(request):
    # Handle file upload
    logger = SearchObjectsLogger(UPLOAD_LOG_FILE)
    upload_start = time.time()
    
    if request.method == 'POST':
        form = DocumentForm(request.POST, request.FILES)
        if form.is_valid():
            video_file = request.FILES['docfile']

            filename = video_file.name.strip()

            name_and_ext = filename.split('.')
            orig_name = filename
            if len(name_and_ext) ==2:
                name = name_and_ext[0]
                ext = name_and_ext[1]
                timestamp = time.time()
                unique_filename = name + "_"+ str(int(timestamp))+"."+ext;
                filename = unique_filename

            video_file.name = filename

            newdoc = VideoDocument(docfile = video_file)
            try:
                newdoc.save()

                #print "Processing file", video_file.name
                #process_video_file(video_file.name)
                logger.set_time_start(str(upload_start))
                logger.set_time_end(str(time.time()))
                logger.set_action("upload")
                logger.set_video_filepath(video_file.name)
                logger.log_to_file()
                return render_to_response('demo/index.html',{'form': form, 'video_upload_status':"Successfully uploaded "+orig_name+" and started processing."}, context_instance=RequestContext(request))
            except:
                trace = traceback.format_exc()
                return HttpResponse("Error uploading. \n"+trace )
        else:
            form = DocumentForm() # A empty, unbound form

    # Render list page with the documents and the form
    return render_to_response('demo/index.html',{'form': form, 'video_upload_status':""}, context_instance=RequestContext(request))



def upload_gps_file(request):
    # Handle file upload
    if request.method == 'POST':
        form = DocumentForm(request.POST, request.FILES)
        if form.is_valid():
            gps_file = request.FILES['docfile']
            newdoc = GPSDocument(docfile = gps_file)
            try:
                newdoc.save() #TODO: should I replace if same file exists or save it with alternate name? right now 
                                #system saves as filename_<i>, for ith duplicate 
                filename = gps_file.name
                process_gps_file(filename)
                return render_to_response('demo/index.html',{'form': form, 'gps_upload_status':"Successfully uploaded "+filename+" and started processing."}, context_instance=RequestContext(request))
            except:
                trace = traceback.format_exc()
                return HttpResponse("Error uploading. \n"+trace )
        else:
            form = DocumentForm() # A empty, unbound form

    # Render list page with the documents and the form
    return render_to_response('demo/index.html',{'form': form, 'upload_status':""}, context_instance=RequestContext(request))





def fetch_pics(request):
    #the retrieve logfile, at the time of its creation, has following headers:
    #keyword, threshold, frame_gap, filename_part, frame_range, retrieval_type, new_req, total_retrieval_time
    #but go to the file itself to verify
    fetch_start = time.time()
    
    #keyword = request.GET.get('keyWord', '')
    keyword = ""
    threshold = 1.0
    frame_gap = 15 #subsequent #frames to skip if same object is detected in those
    filename_part = ""
    frame_range = []

    #return test_coreset_retrieval() #remove this line after finishing testing

    if request.method == 'GET':
        global sessions_images_dict
        session_id = request.session.session_key
        keyword = request.GET.get('word')
        threshold_str = request.GET.get('threshold')
        frame_gap_str = request.GET.get('frame_gap')

        search_for_str = request.GET.get('search_for')
        
        filename_part_str = request.GET.get('filename_part')
        frame_range_str = request.GET.get('frame_range')
                                 
        if len(threshold_str.strip())>0:
            threshold = float(threshold_str)

        if len(frame_gap_str.strip()) > 0:
            frame_gap = int(frame_gap_str)

        if len(filename_part_str.strip())>0:
            filename_part = filename_part_str

        if len(frame_range_str.strip())>0:
            frame_range = frame_range_str.split('-')
            frame_range = [int(frame) for frame in frame_range] #check various user flaws
        else:
            frame_range = [1, float('inf')]
        
        assert len(frame_range) == 2 
        

        #return text search if asked for text search
        if search_for_str.strip().lower() == "text":
            return retrieve_text_from_db(filename_part, keyword, threshold, frame_gap, frame_range)


        retrieval_type = request.GET.get('retrieval_type')
        do_coreset_retrieval = False
        do_uniform_retrieval = False
        new_req = True
        if retrieval_type:
            if retrieval_type.strip().lower() == "coreset" or retrieval_type.strip().lower() == "uniform":

                do_coreset_retrieval = True
                new_req_str = request.GET.get('new_req')
                new_req = new_req_str == 'true' or new_req_str == None
                if new_req:
                    fill_session_dict(session_id, fetch_start)
        
        retrieval_data = request.GET.get('retrieval_data')    
        is_synthetic_retrieval = False
        if retrieval_data.strip().lower() == "synthetic":
            is_synthetic_retrieval = True
        
        if do_coreset_retrieval:
            return retrieve_from_coreset(new_req, filename_part, keyword, threshold,frame_gap,frame_range, session_id, retrieval_type.strip().lower(), is_synthetic_retrieval)
        else:
            return retrieve_from_db(filename_part, keyword, threshold, frame_gap, frame_range, fetch_start, is_synthetic_retrieval)


def retrieve_text_from_db(filename_part, keyword, threshold, frame_gap, frame_range):
    if frame_range[1] != float('inf'):
        text_regions = AppTextDetection.objects.filter(detected_text__icontains=keyword).filter(frame__range=tuple(frame_range)).filter(confidence__gte=threshold)
    else:
        text_regions = AppTextDetection.objects.filter(detected_text__icontains=keyword).filter(confidence__gte=threshold)
    #first construct the text regions dictionary, similar to images_dict for objects, but instead of image paths, they
    #are 
    text_regions_dict = {}
    for region in text_regions:
        if region.detected_text not in text_regions_dict:
            text_regions_dict[region.detected_text] = [region]
        else:
            text_regions_dict[region.detected_text].append(region)
            
    #now create text_images_dict
    text_images_dict = {}
    for detected_text in text_regions_dict.keys():
        text_regions = text_regions_dict[detected_text]
        images = save_and_get_images(text_regions, frame_range)
        text_images_dict[detected_text] = images
    
    return render_to_response("demo/filtered_images.html", {'images_dict':text_images_dict, 'threshold':threshold})

def retrieve_from_db(filename_part, keyword, threshold, frame_gap, frame_range, fetch_start, is_synthetic_retrieval):
    logger = SearchObjectsLogger(RETRIEVE_LOG_FILE)
    if is_synthetic_retrieval:
        classes = AppSyntheticObjectClasses.objects.filter(class_name__icontains=keyword);
    else:
        classes = AppClassMapping.objects.filter(class_name__icontains=keyword).filter(class_id__lte=200)

    # dict = {class1:[img1, img2,..], class2:[img1, img2,..]}

    images_dict = {}

    #pdb.set_trace()
    for obj_class in classes:
        #print "The obj class is ", obj_class.class_name
        if not is_synthetic_retrieval:
            label = AppLabel.objects.filter(title = obj_class.class_id)[0] #needs to have one to one mapping between label and class
        
        if not is_synthetic_retrieval:
            if frame_range[1] != float('inf'):
                regions = AppRegion.objects.filter(label__id = label.id).filter(scene__path__icontains=filename_part).filter(frame__range=tuple(frame_range)).filter(confidence__gte=threshold).order_by('scene__id').order_by('frame')
            else:
                regions = AppRegion.objects.filter(label__id = label.id).filter(scene__path__icontains=filename_part).filter(confidence__gte=threshold).order_by('scene__id').order_by('frame')
        else:
            if frame_range[1] != float('inf'):
                regions = AppSyntheticRegion.objects.filter(class_id = obj_class.id).filter(scene__path__icontains=filename_part).filter(frame__range=tuple(frame_range)).filter(confidence__gte=threshold).order_by('scene__id').order_by('frame')
            else:
                regions = AppSyntheticRegion.objects.filter(class_id = obj_class.id).filter(scene__path__icontains=filename_part).filter(confidence__gte=threshold).order_by('scene__id').order_by('frame')
            
        #some profiling code to figure out what's taking most time in saving
        #cProfile.runctx('save_and_get_images(regions, threshold, frame_gap, frame_range)', globals(), locals(), filename='profile')
        images = save_and_get_images(regions, frame_gap)
        
        if obj_class.class_name not in images_dict:
            images_dict[obj_class.class_name] = images
        else: #now,just appending to the current list, but probably need to do something different
            tot_images = images_dict[obj_class.class_name]
            tot_images.extend(images)
            images_dict[obj_class.class_name] = tot_images
    
    #log the times    
    #keyword, threshold, frame_gap, filename_part, frame_range, retrieval_type, new_req, total_retrieval_time, importance
    sum_importance = get_total_importance(images_dict)
    line_to_log = "\n"+keyword+","+ str(threshold)+","+str(frame_gap)+","+filename_part+","+str(frame_range)+"," + \
    "db"+","+"1"+","+str(time.time() - fetch_start)+","+str(sum_importance);
    logger.log_line_to_file(line_to_log)
    
    #print "Rendering the images back."
    return render_to_response("demo/filtered_images.html", {'images_dict':images_dict, 'threshold':threshold})




def retrieve_from_coreset(new_req, filename_part, keyword, threshold,frame_gap,frame_range, session_id, sample_type, is_synthetic_retrieval):
    new_req_str = "0"
    if new_req:
        new_req_str = "1"
        if is_synthetic_retrieval:
            classes = AppSyntheticObjectClasses.objects.filter(class_name__icontains=keyword);
        else:
            classes = AppClassMapping.objects.filter(class_name__icontains=keyword).filter(class_id__lte=200)        
        
        global sessions_images_dict
        
        start_time = time.time()
        images_dict = sessions_images_dict[session_id]['images_dict']
    
        scene_array = AppScene.objects.filter(path__icontains=filename_part)
        coreset_array = AppCoreset.objects.filter(scene__id__in = scene_array) 
        #if frame_range == []:
            #return render_to_response("demo/index.html", {'search_form_status':"Please input the frame range."})        
        thread = threading.Thread(target=populate_sessions_dict, args=(classes, coreset_array, threshold, frame_gap, frame_range, session_id, sample_type, is_synthetic_retrieval)) #run this as a thread
        thread.daemon = True
        thread.start()
        
 
    return render_coreset_retrieved_images(session_id, keyword, threshold, frame_gap, filename_part, frame_range, new_req_str, sample_type)
    
    

def populate_sessions_dict(classes, coreset_array, threshold, frame_gap, frame_range, session_id, sample_type, is_synthetic_retrieval):
    global sessions_images_dict
    images_dict = sessions_images_dict[session_id]['images_dict']
    
    for obj_class in classes:
        if not is_synthetic_retrieval:
            label = AppLabel.objects.filter(title = obj_class.class_id)[0]
        else:
            label = obj_class
        for coreset_obj in coreset_array:
            coreset_path = coreset_obj.simple_coreset_path 
            coreset_str = CoresetStructure(coreset_path)
            scene_id = coreset_obj.scene_id
            if sample_type == "coreset":
                regions_generator = coreset_retrieval(coreset_str, frame_range, label, scene_id, threshold, is_synthetic_retrieval) #it's a generator
            else:
                regions_generator = coreset_uniform_retrieval(coreset_str, frame_range, label, scene_id, threshold, is_synthetic_retrieval)
            for regions in regions_generator:
                if regions == None:
                    break;
                if len(regions) == 0:
                    continue;
                images = save_and_get_images(regions, frame_gap)
                
                if obj_class.class_name not in images_dict:
                    images_dict[obj_class.class_name] = images
                else: #now,just appending to the current list, but probably need to do something different
                    tot_images = images_dict[obj_class.class_name]
                    tot_images.extend(images)
                    images_dict[obj_class.class_name] = tot_images
    sessions_images_dict[session_id]['done'] = 1
    return


def render_coreset_retrieved_images(session_id, keyword, threshold, frame_gap, filename_part, frame_range, new_req_str, sample_type):
    logger = SearchObjectsLogger(RETRIEVE_LOG_FILE)
    global sessions_images_dict
    if session_id in sessions_images_dict:
        images_dict = sessions_images_dict[session_id]['images_dict']
    else:
        if new_req_str == "0": #trying to look for session that's no longer there
            return HttpResponse("Hit back and Shift + F5 because your browser is caching info");
    done = sessions_images_dict[session_id]['done'] == 1

    response_data = {'images_dict':images_dict.copy(), 'threshold':threshold, 'coreset':1, 'done':done}
    
    if done:
        images_dict.clear()

    if len(response_data['images_dict']) > 0:  
        #log time to file
        fetch_start = sessions_images_dict[session_id]['start_time']
        response_dict = response_data['images_dict'];
        num_images = sum(len(values) for values in response_dict.values());
        sum_importance = get_total_importance(response_dict)
        if sample_type == "coreset":
            line_to_log = "\n"+ keyword+","+ str(threshold)+","+str(frame_gap)+","+filename_part+","+str(frame_range)+"," + \
                "prefer_coreset"+","+new_req_str+","+str(time.time() - fetch_start)+","+str(num_images)+","+str(sum_importance);
        else:
            line_to_log = "\n"+ keyword+","+ str(threshold)+","+str(frame_gap)+","+filename_part+","+str(frame_range)+"," + \
                "uniform_coreset"+","+new_req_str+","+str(time.time() - fetch_start)+","+str(num_images)+","+str(sum_importance);            
        logger.log_line_to_file(line_to_log)   
        #print "Rendering the data", response_data
        return render_to_response("demo/filtered_images.html", response_data)
    
    if not done and len(response_data['images_dict']) == 0:
        return HttpResponse(json.dumps({'done':0}))
    
    sessions_images_dict[session_id]['done'] = 0
    return HttpResponse(json.dumps({'done':1}))


def fill_session_dict(session_id, fetch_start):
    session_dict = {}
    session_dict['images_dict'] = {}
    session_dict['done'] = 0
    session_dict['start_time'] = fetch_start
    sessions_images_dict[session_id] = session_dict      


def populate_generators_and_classes(generator_list,classes_list, classes, coreset_array, frame_range):
    for obj_class in classes:
        label = AppLabel.objects.filter(title = obj_class.class_id)[0]
        for coreset_obj in coreset_array:
            coreset_path = coreset_obj.simple_coreset_path 
            coreset_str = CoresetStructure(coreset_path)
            scene_id = coreset_obj.scene_id
            regions_generator = coreset_retrieval(coreset_str, frame_range, label, scene_id) #it's a generator
            generator_list.append(regions_generator)
            classes_list.append(obj_class)

def summarize_video(request):
    if request.method == 'GET':
        video_path = SUMMARIZE_VIDEO_PATH
        mat_path = SUMMARIZE_MAT_PATH
        tree_depth = request.GET.get('tree_depth')
        tree_height = request.GET.get('tree_height')
        
        pruning_type = request.GET.get('prune_type') #could be None, avg_dist,min_dist,max_dist,blur
        threshold = request.GET.get('threshold')
        
        #search by height only when depth field is empty and height field is non_empty.
        #otherwise, always take the tree_depth
        if len(tree_depth.strip()) == 0 and len(tree_height.strip()) == 0 and pruning_type != None:
            if len(threshold.strip()) == 0:
                threshold = 0
            else:
                try:
                    threshold = int(threshold)
                except:
                    #TODO:render to index at the right place
                    return render_to_response("demo/summarized_video.html", "Put in empty or an integer for threshold")
            if threshold < 0:
                return render_to_response("demo/summarized_video.html", "Threshold input cannot be negative.")
            nodes_info = prune_and_save_keyframes(video_path, mat_path, pruning_type, threshold)
        elif len(tree_depth.strip()) == 0 and len(tree_height.strip()) != 0:  
            nodes_info = parse_mat_and_save_height_keyframes(video_path, mat_path, tree_height)
        else:
            nodes_info = parse_mat_and_save_depth_keyframes(video_path, mat_path, tree_depth)


    #saved_keyframe_paths = save_keyframes(video_path, data_root)
    return render_to_response("demo/summarized_video.html", {'coreset_nodes':nodes_info})



    
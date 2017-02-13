cfg.RCNN_LIB='/home/drl-leopard/rcnn';
cfg.LSDA_LIB='/home/drl-leopard/lsda';
cfg.CAFFE_LIB='/home/drl-leopard/caffe-master';
cfg.VIDEO_ANALYSIS_LIB='/home/drl-leopard/video_analysis/trunk/';
%add the upload file path,and where to upload
cfg.VIDEO_UPLOAD_PATH = 'searchobjects/media/file_uploads/videos/'; %relative to VIDEO_ANALYSIS_LIB
cfg.CORESET_DATA_SAVE_PATH = 'coreset_data/'; %relative to VIDEO_ANALYSIS_LIB
cfg.PROCESSED_VIDEOS_PATH = 'searchobjects/media/processed_uploads/videos/';

cfg.server='localhost';
cfg.instance='postgres';
cfg.username='postgres';
cfg.password='robits!!';
cfg.db_name='postgres';


project_paths = {};

project_paths = cat(1,project_paths,pwd);
project_paths = cat(1,project_paths,'/home/drl-leopard/LOCAL_DATA');
project_paths = cat(1,project_paths, cfg.RCNN_LIB);
project_paths = cat(1,project_paths, cfg.LSDA_LIB);
disp('Adding project paths:')
try
  for i = 1:length(project_paths)
    addpath(genpath(project_paths{i}))
  end
catch err
  disp(err)
end

%add javaclasspath for database connection
disp('Adding javaclasspath for database');
javaclasspath('/home/drl-leopard/psql-connector/postgresql-9.4-1201.jdbc4.jar');
           
disp('Done!')
clear project_paths i


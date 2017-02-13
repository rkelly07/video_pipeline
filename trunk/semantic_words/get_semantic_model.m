function res = get_semantic_model(type,paths)

switch upper(type)
    
    case 'RCNN'
        rcnn_model_file = [paths.RCNN_LIB,'/data/rcnn_models/ilsvrc2013/rcnn_model.mat'];
        use_gpu = true;
        res.rcnn_path = paths.RCNN_LIB;
        curr_directory = pwd;
        cd(res.rcnn_path);
        % following two lines may only be needed to some (server needs those)
        startup;
        rcnn_build();
        res.rcnn_model = rcnn_load_model(rcnn_model_file,use_gpu);
        res.dim = 200;
        res.thresh = -0.5;
        res.thresh2 = -0.5;
        res.new_obj_thresh = 1;
        res.type = 'rcnn';
        cd(curr_directory);
    case 'FAST-RCNN'
        curr_directory = pwd;
        folder = paths.FAST_RCNN_LIB;
        res.fast_rcnn_path = folder;
        use_gpu = true;
        cd([res.fast_rcnn_path '/matlab']);

        caffe_path = fullfile(folder, 'caffe-fast-rcnn','matlab', 'caffe');
        addpath(caffe_path);
        % You can try other models here:
        %{
        def = fullfile(folder, 'models', 'VGG16', 'test.prototxt');
        net = fullfile(folder, 'data', 'fast_rcnn_models', ...
                       'vgg16_fast_rcnn_iter_40000.caffemodel');
        %}
        
        %def = fullfile(folder, 'caffe-fast-rcnn','models', 'bvlc_reference_rcnn_ilsvrc13', 'deploy.prototxt');
        def = fullfile(folder, 'models', 'CaffeNet', 'test.prototxt');
        net = fullfile(folder, 'caffe-fast-rcnn','models', 'bvlc_reference_rcnn_ilsvrc13', ...
               'bvlc_reference_rcnn_ilsvrc13.caffemodel');
        res.fast_rcnn_model = fast_rcnn_load_net(def, net, use_gpu);
        res.dim = 200;
        res.thresh = -0.5;
        res.thresh2 = -0.5;
        res.new_obj_thresh = 1;
        res.type = 'fast-rcnn';
        cd(curr_directory);
    case 'LSDA'
        curr_directory = pwd;
        % rcnn_model_file = [paths.LSDA_LIB,'/rcnn_model7200.mat'];
        cd(paths.LSDA_LIB);
        startup;
        res.rcnn_model = rcnn_model;
        res.rcnn_feat = rcnn_feat;
        % use_gpu = true;
        res.type = 'lsda';
        % res.rcnn_model = rcnn
        cd(curr_directory);
        
    case 'PLACES'
        % rcnn_model_file = [paths.RCNN_LIB,'/data/rcnn_models/ilsvrc2013/rcnn_model.mat'];
        res.places_model_file = [paths.CAFFE_LIB,'/models/places/places205CNN_iter_300000_upgraded.caffemodel'];
        res.places_model_def = [paths.CAFFE_LIB,'/models/places/places205CNN_deploy_upgraded.prototxt'];
        use_gpu = true;
        % res
        % res.rcnn_path = paths.RCNN_LIB;
        curr_directory = pwd;
        % cd(res.rcnn_path);
        % res.rcnn_model = rcnn_load_model(rcnn_model_file, use_gpu);
        res.dim = 205;
        res.coefficient = 10000;
        % res.thresh = -0.5;
        % res.thresh2 = -0.5;
        % res.new_obj_thresh = 1;
        res.type = 'places';
        cd(curr_directory);
     
    
        
end

% ------------------------------------------------
% reformatted with stylefix.py on 2015/03/13 16:56

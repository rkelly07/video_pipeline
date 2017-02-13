root_folder = '/home/drl-leopard/LOCAL_DATA/videos/demo_vids/';
detector = 'rcnn'; % also could be 'rcnn'
video_files = {'test0.mp4','test1.mp4', 'test2.mp4', 'test3.mp4', 'test4.mp4', 'test5.mp4', 'test6.mp4', 'test7.mp4'};

for video_file = video_files
    path = strcat(root_folder, char(video_file));
    if strcmp(detector, 'rcnn')
        fprintf(['Processing video ' path ' with rcnn']);
        process_video_semantic_wrapper(path);
    elseif strcmp(detector, 'lsda')
        fprintf(['Processing video ' path ' with lsda']);
        process_video_lsda_wrapper(path);
    else
        fprintf('Specify the detectors correctly, either rcnn or lsda');
    end
end


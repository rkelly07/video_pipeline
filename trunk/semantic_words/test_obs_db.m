cfg=[];cfg.server='localhost';
cfg.instance='postgres';
cfg.username='postgres';
cfg.password='fdhdfjaol';
cfg.db_name='postgres';

A=observations_db(cfg);
A.open_db();
A.clear_db();
A.set_tags_for_frame(1,2,3)
for i = 1:200
    A.add_label(struct('title',num2str(i)));
end
scene.path=' ';
scene.height=1080;
scene.width=1920;
scene.frame_rate=30;
scene.frames=3600;
A.add_scene(scene);

detection.label='1';
detection.scene_label=' ';% assumes the path is the scene label
detection.frame=1;
detection.x1=2;detection.x2=3;detection.y1=4;detection.y2=5;
A.add_detection_frame(detection);
A.close_db();

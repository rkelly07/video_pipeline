cfg=[];cfg.server='localhost';
cfg.instance='postgres';
cfg.username='postgres';
cfg.password='fdhdfjaol';
cfg.db_name='postgres';

A=observations_db(cfg);
A.open_db();
A.clear_db();
for i = 1:200
    A.add_label(struct('title',num2str(i)));
end
% scene.path=' ';
% scene.height=1080;
% scene.width=1920;
% scene.frame_rate=30;
% scene.frames=3600;
% A.add_scene(scene);

A.close_db();

filepath = 'demo_project.ogg';
coreset.coreset_results_path = '/home/serverdemo/video_analysis/trunk/rtvproc/results/demo_project_coreset_results_155_40_0707143000.mat';
coreset.coreset_tree_path = '/home/serverdemo/video_analysis/trunk/rtvproc/results/demo_project_coreset_tree_155_40_0707143000.mat';
coreset.simple_coreset_path = '/home/serverdemo/video_analysis/trunk/rtvproc/simpler_coreset_results/simpler_tree_0716082010.mat';

save_coreset_detections(filepath, coreset);

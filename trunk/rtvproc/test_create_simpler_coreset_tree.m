results_path = fullpath('results/demo_project_coreset_results_155_40_0707143000.mat');
tree_path = fullpath('results/demo_project_coreset_tree_155_40_0707143000.mat');

simple_path = create_simpler_coreset_tree(tree_path, results_path);

simple_path
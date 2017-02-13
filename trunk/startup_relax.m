project_paths = {};
project_paths = cat(1,project_paths,pwd);
project_paths = cat(1,project_paths,'/scratch/relax');
% project_paths = cat(1,project_paths,'/media/My Passport/MyRecord/');
disp('Adding project paths:')
project_paths
try
  for i = 1:length(project_paths)
    addpath(genpath(project_paths{i}))
  end
catch err
  disp(err)
end
disp('Done!')
clear project_paths i

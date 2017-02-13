project_paths = {};
project_paths = cat(1,project_paths,pwd);
if ispc
  project_paths = cat(1,project_paths,'C:/Users/Mikhail/Desktop/source_data');
else
  project_paths = cat(1,project_paths,'/Users/mikhail/Desktop/source_data');
end
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
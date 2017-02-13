project_paths = {};

project_paths = cat(1,project_paths,pwd);
project_paths = cat(1,project_paths,'/home/serverdemo/LOCAL_DATA');
%project_paths = cat(1,project_paths, cfg.RCNN_LIB);
%project_paths = cat(1,project_paths, cfg.LSDA_LIB);
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
javaclasspath('/home/serverdemo/psql-connector/postgresql-9.4-1201.jdbc41.jar');
           
disp('Done!')
clear project_paths i
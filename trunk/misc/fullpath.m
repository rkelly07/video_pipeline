% returns the full path of the filenames
% if filenames is a string, returns a string
% if filenames is a cell, returns a cell
function pathstr = fullpath(filenames)

if iscell(filenames)
    pathstr = {};
    for i = 1:length(filenames)
        pathstr = cat(1,pathstr,which(filenames{i}));
    end
else
    pathstr = which(filenames);
    if (isempty(pathstr) && ~isempty(filenames))
        pathstr=filenames;
    end
end

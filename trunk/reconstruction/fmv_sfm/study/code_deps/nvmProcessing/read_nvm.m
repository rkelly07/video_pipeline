function models = read_nvm(filename)
% Each "model" is a set of photos, a set of points, and a set of "views"
% (where a point was seen in a photo). Equivalently, views are edges in the
% graph of points<->photos.
%
% photos.focs is vector of focal params, "f"
% photos.radDist is vector of radial distortion params
% photos.X_cams is matrix of positions of camera center
% photos.Q is matrix of quaternions representing rotation of camera w.r.t. coord ref frame
%
% points.XYZ
% points.RGB
%
% Each point i has a set of views{i}. I'd prefer to have views associate points
% and photos *without* special treatment of points, but for now I'm trying
% to keep a close format in matlab memory to the .nvm file.
% 
% Reference:  http://www.cs.washington.edu/homes/ccwu/vsfm/doc.html#nvm
%
% WARNING/FIXME: only supports .nvm files with a single model! (will skip any models appearing thereafter)
%
% Example usage:
%
% filename = '\\Division10\Group102\SIGMA\Data\fenway_smallset\vSfM_output\fenway_smallset.nvm';
% models = read_nvm(filename)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    % WARNING/FIXME: only supports .nvm files with a single model! (will skip any models appearing thereafter)
    models = cell(1,1);

    % ingesta
    fid = fopen(filename);

    % read header
    data = textscan(fid,'%u',1,'headerlines',2);
    models{1}.numPhotos = data{1};


    disp(sprintf('Reading data for %d photos',models{1}.numPhotos));
    data = textscan(fid,'%s%s%s%s%s%s%s%s%s%s%*[^\n]',models{1}.numPhotos,'CollectOutput',true);
    photos.paths = data{1}(:,1);
    photos.focs = cellfun(@str2num,data{1}(:,2)); % vector of focal params, "f"
    photos.Q = cellfun(@str2num,data{1}(:,3:6)); % matrix of quaternions representing rotation of camera w.r.t. coord ref frame
    photos.X_cams = cellfun(@str2num,data{1}(:,7:9)); % matrix of positions of camera center
    photos.radDist = cellfun(@str2num,data{1}(:,10)); % vector of radial distortion params

    models{1}.photos = photos;

    data = textscan(fid,'%u%*[^\n]',1);
    points.numPoints = data{1};

    data = textscan(fid,'%s%s%s%s%s%s%s%[^\n]',points.numPoints,'CollectOutput',true);
    points.XYZ = cellfun(@str2num,data{1}(:,1:3)); % matrix of points, where each point (row) is [x,y,z,r,g,b]
    points.RGB = cellfun(@str2num,data{1}(:,4:6)); % matrix of points, where each point (row) is [x,y,z,r,g,b]

    models{1}.points = points;

    models{1}.numViews = cellfun(@str2num,data{1}(:,7)); % vector, each entry giving number of photos in which point was seen
    viewData = data{:}(:,8);

    views = cell(points.numPoints,1); % each point has a number of views
    for i=1:points.numPoints
        data = textscan(viewData{i},'%u%u%f%f',models{1}.numViews(i),'CollectOutput',true);
        views{i}.imgIdxs = data{1}(:,1);
        views{i}.featureIdxs = data{1}(:,2);
        views{i}.pixelLocations = data{2}(:,1:2);
        views{i}.numViews = models{1}.numViews(i);
    end

    models{1}.views = views;

    fclose(fid);

end


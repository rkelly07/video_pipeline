function write_nvm(models,outfilename)
%
% Example usage:
% 
% 
% models = read_nvm(filename);
% write_nvm(models,[filename(1:end-4),'.test.nvm']);

    % fid = 1; % stdout (testing)
    fid = fopen(outfilename,'w');

    fprintf(fid,'NVM_V3\n');
    fprintf(fid,'\n');
    
    for k=1:length(models)
        
        photos = models{k}.photos;
        fprintf(fid,'%u\n',models{k}.numPhotos);

        % ugly, iterative
        s = '';
        for i=1:models{k}.numPhotos
            s = [s, sprintf('%s %.12f %.12f %.12f %.12f %.12f %.12f %.12f %.12f %.12f 0\n',photos.paths{i},photos.focs(i),photos.Q(i,:),photos.X_cams(i,:),photos.radDist(i))];
        end
        s = strrep(s,'\','\\'); % annoying, we have to add escapes for \'s because fprintf interprets them as escapes
        fprintf(fid,s); % write as one block to save I/O time
        
        points = models{k}.points;
        views = models{k}.views;
        
        fprintf(fid,'\n');
        fprintf(fid,'%u\n',models{k}.points.numPoints);

        s = '';
        for j=1:models{k}.points.numPoints
            s = [s, sprintf('%.12f %.12f %.12f %u %u %u %u ',points.XYZ(j,:),points.RGB(j,:),models{k}.numViews(j))];
            for i=1:models{k}.numViews(j)
                s = [s, sprintf('%u %u %.12f %.12f ',views{j}.imgIdxs(i),views{j}.featureIdxs(i),views{j}.pixelLocations(i,:))];
            end
            s = [s,'\n'];
        end
        fprintf(fid,s);

        fprintf(fid,'\n');
        fprintf(fid,'\n');
        fprintf(fid,'\n');
        fprintf(fid,'0');
        fprintf(fid,'\n');
        fprintf(fid,'# comments...\n');
        fprintf(fid,'# ...comments\n');
        fprintf(fid,'0');
        
    end
    fclose(fid);


end


% From http://www.cs.washington.edu/homes/ccwu/vsfm/doc.html#nvm
% 
% VisualSFM saves SfM workspaces into NVM files, which contain input image paths and multiple 3D models. Below is the format description
% 
% NVM_V3 [optional calibration]                        # file version header
% <Model1> <Model2> ...                                # multiple reconstructed models
% <Empty Model containing the unregistered Images>     # number of camera > 0, but number of points = 0
% <0>                                                  # 0 camera to indicate the end of model section
% <Some comments describing the PLY section>
% <Number of PLY files> <List of indices of models that have associated PLY>
% 
% The [optional calibration] exists only if you use "Set Fixed Calibration" Function
% FixedK fx cx fy cy
% 
% Each reconstructed <model> contains the following
% <Number of cameras>   <List of cameras>
% <Number of 3D points> <List of points>
% 
% The cameras and 3D points are saved in the following format
% <Camera> = <File name> <focal length> <quaternion rotation> <camera center> <radial distortion> 0
% <Point>  = <XYZ> <RGB> <number of measurements> <List of Measurements>
% <Measurement> = <Image index> <Feature Index> <xy>
% 
% Check the LoadNVM function in util.h of Multicore bundle adjustment code for more details.  The LoadNVM function reads only the first model, and you should repeat to get all. Since V0.5.7, the white spaces in <file name> are replaced by '\"'. 
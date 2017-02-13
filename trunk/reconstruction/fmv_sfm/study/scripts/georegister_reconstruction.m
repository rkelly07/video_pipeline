function georegister_reconstruction(metadataFilename,nvmFilename,CACHE_DIR,RESULTS_DIR)

    % test data
    if nargin < 2
%        metadataFilename = '\\qonos\RRTO2D3D\study\truth\puma_2013_09_13_flt1_bin2txt.metadata';
%         metadataFilename = '\\qonos\D\DDAGOUS\mikepark_challenge\puma_May30_2013_CampEdwards_Day1_flight2.metadata';
        metadataFilename = 'D:\DDAGOUS\mikepark_challenge\puma_May30_2013_CampEdwards_Day1_flight2.metadata';
       if nargin < 1 
%            nvmFilename = '\\qonos\RRTO2D3D\puma_Sep13_2013_YPG\subset\subset.nvm';
%            nvmFilename = '\\qonos\D\DDAGOUS\mikepark_challenge\frames\mpcnvm3.nvm';
%             nvmFilename = 'D:\DDAGOUS\mikepark_challenge\frames\mpc_dense.nvm';
            nvmFilename = 'D:\DDAGOUS\mikepark_challenge\frames\mpc.nvm';
       end
    end

    if nargin < 4
%        RESULTS_DIR = fullfile(fileparts(metadataFilename),'..','reconstruction_results');
       RESULTS_DIR = fullfile(fileparts(metadataFilename),'reconstruction_results');
       if nargin < 3 
%           CACHE_DIR = fullfile(fileparts(metadataFilename),'..','reconstruction_cache');
          CACHE_DIR = fullfile(fileparts(metadataFilename),'reconstruction_cache');
       end
    end

    % read in metadata
    data = importdata(metadataFilename,' ');
    X = data.data(:,2:4);
    t = data.data(:,1);
    %dt = mean(diff(t));
    filenames = {data.textdata{2:end}}; % skip header line, which is commented field names
    
    % output .txt file in format vSfM expects as input (into cache folder)
    x0 = mean(X);
    X = bsxfun(@minus,X,x0); % positions centered
    
    coordsFilename = fullfile(CACHE_DIR,'geocoords.txt');
    fid = fopen(coordsFilename,'wt');
    for i=1:length(filenames)
        fprintf(fid,'%s %.2f %.2f %.2f\r\n',filenames{i},X(i,1),X(i,2),X(i,3));
    end
    fclose(fid);
    
    offsetFilename = fullfile(CACHE_DIR,'geocoords_offset.txt');
    dlmwrite(offsetFilename,x0,'delimiter',' ','precision',16);

    % call vSfM to perform geo-reg
    copyfile(nvmFilename,CACHE_DIR);
    [~,outfilename] = fileparts(nvmFilename);
    outfilename = fullfile(CACHE_DIR,outfilename);
    cmdStr = sprintf('visualSfM %s %s %s...',nvmFilename,coordsFilename,outfilename); % FIXME
    %system(cmdStr); % FIXME: for now, just pretend it came in geo-registered, skip calling vSfM
    outfilename = nvmFilename; % FIXME: for now, just pretend it came in geo-registered

    % read in geo-reg'd nvm file
    models = read_nvm(nvmFilename);
    model = models{1}; % just use the first one, which should be the largest/best
    [sortedFilenames,sortedIdxs] = sort(model.photos.paths); % put in temporal order
    Y = model.photos.X_cams(sortedIdxs,:);

    % derive mapping (re-ordering) between filenames from NVM file and GPS file
    idxs = nan(model.numPhotos,1);
    
    for i=1:model.numPhotos
        % removed 'frames\' from sortedFilenames - MJP 2014-11-03:
%         sortedFilenames2{i} = sortedFilenames{i}(8:end);        
        idxs(i) = find(strcmp(sortedFilenames{i},filenames));
    end
    Y = Y(~isnan(idxs),:);
    idxs = idxs(~isnan(idxs));
    X = X(idxs,:); % hmm... this is probably not re-ordering, but probably just removing non-existent entries
    t = t(idxs); % hmm... this is probably not re-ordering, but probably just removing non-existent entries
    filenames = {filenames{idxs}};
    
    % VIZ
%     Y = Y ./ mean(std(Y)).* mean(std(X)); % re-scale so it looks reasonable just for VIZ
%     scatter3(X(:,1),X(:,2),X(:,3),3,'r.'); hold on; scatter3(Y(:,1),Y(:,2),Y(:,3),3,'b+');
    
    % temporal alignment
    %delta_t_range = -10:0.1:10;
    delta_t_range = [-10,10];
    [delta_t,Y_hat,rmse,resids] = coordinate_temporal_alignment(X,Y,t,delta_t_range);

    % re-write geocoords.txt file
    % shift time: interpolate to find values of X at time points t_Y = t-delta_t (i.e., the times when snapshots were taken)
    x = interp1(t,X(:,1),t-delta_t,'pchip','extrap')';
    y = interp1(t,X(:,2),t-delta_t,'pchip','extrap')';
    z = interp1(t,X(:,3),t-delta_t,'pchip','extrap')';
    
    coordsFilename = fullfile(CACHE_DIR,'geocoords.gcp');
    fid = fopen(coordsFilename,'wt');
    for i=1:length(filenames)
        fprintf(fid,'%s %.2f %.2f %.2f\r\n',filenames{i},x(i),y(i),z(i));
    end
    fclose(fid);

    % re-run vSfM geo-reg
    cmdStr = sprintf('visualSfM %s %s %s...',nvmFilename,coordsFilename,outfilename); % FIXME
    %system(cmdStr); % FIXME: until we find the right syntax for this command, skip
    
    % copy geo-reg'd point cloud to output folder
    copyfile(outfilename,RESULTS_DIR);

end

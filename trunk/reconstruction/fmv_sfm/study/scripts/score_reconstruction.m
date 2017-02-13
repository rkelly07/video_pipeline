function stats = score_reconstruction(metadataFilename,nvmFilename)

    % test data
    if nargin < 2
%        metadataFilename = '\\qonos\RRTO2D3D\study\truth\puma_2013_09_13_flt1_bin2txt.metadata';      
       %metadataFilename = '\\qonos\RRTO2D3D\study\reconstruction_cache\geocoords.gcp';
       metadataFilename = 'D:\DDAGOUS\mikepark_challenge\puma_May30_2013_CampEdwards_Day1_flight2.metadata';
%        metadataFilename = 'D:\DDAGOUS\mikepark_challenge\reconstruction_cache\geocoords.gcp';
       
       if nargin < 1 
%            nvmFilename = '\\qonos\RRTO2D3D\puma_Sep13_2013_YPG\subset\subset.nvm';
%             nvmFilename = 'D:\DDAGOUS\mikepark_challenge\frames\mpc_dense_georegistered.nvm';
            nvmFilename = 'D:\DDAGOUS\mikepark_challenge\frames\mpc_geo.nvm';
       end
    end

    data = importdata(metadataFilename,' ');
    % data.textdata is an Nx1 cell array of frame filename strings
    % data.data is Nx9
    
    X = data.data(:,2:4);
    V = data.data(:,7:9) - data.data(:,2:4);

    x0 = mean(X);
    X = bsxfun(@minus,X,x0); % positions centered
    V = bsxfun(@times,V,1./sqrt(sum(V.^2,2))); % camera vector normalized

    filenames = {data.textdata{2:end}};
    %filenames = data.textdata;
    
    % viz
    % quiver3(X(:,1),X(:,2),X(:,3),V(:,1),V(:,2),V(:,3)); axis equal;
    
    % metadata file format:
    % image_filename   epoch (secs) UAV_easting UAV_northing UAV_alt  UAV_heading UAV_pitch UAV_bank tgt_easting  tgt_northing  tgt_alt
    
    models = read_nvm(nvmFilename);

    % derive mapping (re-ordering) between filenames from NVM file and metadata file
    idxs = 1:length(filenames); 
    idxs_hat = nan(length(filenames),1);
    for i=1:length(filenames)
        try
            idxs_hat(i) = find(strcmp(filenames{i},models{1}.photos.paths));
        catch
            % didn't find
        end
    end
    idxs = idxs(~isnan(idxs_hat)); % removing any not found in reconstruction
    idxs_hat = idxs_hat(~isnan(idxs_hat)); % removing any not found in reconstruction
    N = length(idxs_hat);

    X = X(idxs,:);
    V = V(idxs,:);
    
    X_hat = models{1}.photos.X_cams(idxs_hat,:);

    V = repmat([0,0,1],[N,1]); % camera vector, in camera's coordinate system
    V_hat = qvxform(models{1}.photos.Q,V); % TODO: do we need to invert?

    
    
    % assume .nvm already has geo-registration transform applied
    stats.X_resids = X - X_hat;
    stats.X_resid_norms = sqrt(sum(stats.X_resids.^2,2)); % euclidean distance
    
    stats.V_dist = 2*acos(dot(V',V_hat'))/pi - 1; % cosine distance
    
    % TODO: some histograms to visualize output
    
end

function [ no_err, nPhotos, nPoints, nOutliers ] = deconstruct_nvm( nvm_file, cache_dir, out_dir_top, write_flag)

% deconstruct_nvm:  function to read in the first nvm file produced by a sparse reconstruction
%                   and form separate nvm files to reconstruct gcp sparse models
%                   Models are returned in file: cache_dir/'nvm_file_model#'.nvm


no_err    = 1;
nPhotos   = 0;
nPoints   = 0;
nOutliers = 0;

%..... Step 1) Read in models
models     = read_nvm_mult(fullfile(cache_dir, horzcat(nvm_file, '.nvm') ));
num_models = length(models);  % not used for now

if (~isempty(models{1}) )
    %..... Step 2) Keep model with most points
    mod_idx    = 0;
    max_photos = 0;
    for ii = 1: num_models
        if (models{ii}.numPhotos > max_photos && models{ii}.points.numPoints > 0)
            mod_idx    = ii;
            max_photos = models{ii}.numPhotos;
        end
    end

    % ...... Step 3) Write model to file in cache dir
    if (write_flag)
        nvm_out_file = fullfile(cache_dir, horzcat(nvm_file, '_model1.nvm' ) );
        write_single_nvm( models{mod_idx}, nvm_out_file );
        no_err_last = copyfile( nvm_out_file, fullfile( out_dir_top, horzcat(nvm_file, '_model1.nvm') ) ,'f');    %#ok<NASGU>
    end


    %...... Step 4) Find number of outlier cameras; use mean absolute deviation rather than standard
    focs         = models{mod_idx}.photos.focs;
    outliers_mad = abs(focs - trimmean(focs,10)) > 3*mad(focs);
    nOutliers    = sum( outliers_mad) ;

    % ..... Step 5) Return values for accumulating output statistics
    nPhotos   = models{mod_idx}.numPhotos;
    nPoints   = models{mod_idx}.points.numPoints;
end

end


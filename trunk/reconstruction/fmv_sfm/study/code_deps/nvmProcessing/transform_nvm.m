function models = transform_nvm(infilename,R,t,s,invertTransform,writeIt,outfilename)
% Transforms points and camera positions in .nvm file,
% using tranformation [x' y' z']^T = s.* R [x y z]^T + t
% (where R is 3x3 rotation matrix, t is 3x1 translation vector, and s is scaling factor)
% 
% Example usage:
%
% addpath('\\division10\Group102\SIGMA\Software\nvmProcessing\quaternions');
% addpath('\\division10\Group102\SIGMA\Software\nvmProcessing');
% filename = '\\Division10\Group102\SIGMA\Data\fenway_smallset\vSfM_output\fenway_smallset.nvm';
%
% models = transform_nvm(filename);
%

    models = read_nvm(infilename);

    if nargin < 4 || isempty(s), s = 1; end

    if nargin < 5 || isempty(invertTransform), invertTransform = false; end

    if nargin < 5 || isempty(writeIt), writeIt = true; end

    if nargin < 7 || isempty(outfilename), outfilename = sprintf('%s.xformd.nvm',infilename(1:end-4)); end

    % convert input rotation to quaternion, as multiplication of
    % quaternions has better numerical properties than multiplication of
    % rotation matrices
    q = dcm2q(R);

    models{1}.photos.Q = qmult(q,models{1}.photos.Q);
    models{1}.points.XYZ = s.* models{1}.points.XYZ * R' + repmat(t',[models{1}.points.numPoints,1]);
    models{1}.photos.X_cams = s.* models{1}.photos.X_cams * R'  + repmat(t',[models{1}.numPhotos,1]);
    
    if writeIt, write_nvm(models,outfilename); end

end
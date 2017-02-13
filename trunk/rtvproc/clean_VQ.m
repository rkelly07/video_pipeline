% Loads descriptor representatives (VQ) and descriptor weights (VW). 
% Will fix older files to match the new naming convention:
%   VQ: [n x d] descriptor array
%   VW: [n x 1] descriptor weights
function clean_VQ(filename)

if not(strcmp(filename(end-3:end),'.mat'))
    filename = [filename '.mat'];
end

pathstr = fullpath(filename);
load(pathstr);

% standardize VQ
if exist('descriptor_representatives','var')
    if iscell(descriptor_representatives)
        VQ = descriptor_representatives{1};
    else
        VQ = descriptor_representatives;
    end
else
    assert(exist('VQ','var')==1)
end

descriptor_dim = 66;
VQ = single(VQ(:,1:descriptor_dim));
    
% standardize VW
if exist('descriptor_weights','var')
    if iscell(descriptor_weights)
        VW = descriptor_weights{1};
    else
        VW = descriptor_weights;
    end
elseif not(exist('VW','var'))
    VW = [];
end

VW = single(VW);

save(pathstr,'VQ','VW')


function [ final_list ] = remove_darks( temp_list, in_dir, maxDarkPixPerc, maxDarkMag )

% Look for frames that are mostly dark, and discard them.
%
% maxDarkPix = maximum percentage of dark pixels allowed before discarding
% maxDarkVal = maximum magnitude for a "dark" pixel

safe_dir = pwd;
cd(in_dir);

num_images = size(temp_list, 1);
temp_mask  = false(size(temp_list,1) );

maxDarkPix = maxDarkPixPerc / 100.;

% check each frame for blank for final list
for ii = 1:num_images
    A = imread(temp_list(ii).name);
    magA  = sum(A, 3 );
    nDark = sum(magA(:) < maxDarkMag );
    nPix  = size(A,1)*size(A,2);
    pDark = nDark/nPix;
    temp_mask(ii) = (pDark <= maxDarkPix);   
end

% Apply mask
final_list = temp_list(temp_mask);

cd(safe_dir);

end


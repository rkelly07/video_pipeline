function [ no_err, res, num_images ] = set_up_jpegs(in_dir, out_dir_top, cache_dir, jpeg_step, images_fname)

% set_up_jpegs function to move image files and create input text file for
%VisualSFM reconstruction


% ...... Step 1) Read the filenames in the directory containing jpg image files

jpg_files_try1 = horzcat(in_dir, '/*.jpg');
jpg_files_try2 = horzcat(in_dir, '/*.JPG');

list = dir(jpg_files_try1);
if (size(list, 1) == 0)
    list = dir(jpg_files_try2);
end

no_err = (size(list,1) > 0 );    % error on empty listing
err_check(~no_err, '...... Error: no jpg or JPG files found in input directory ..... \n');


% ....... Step 2) Decide how many files to process ......
switch jpeg_step
    case '1'
        temp_list = list;
        
    case '2'
        temp_list = list( 1: 2:  size(list, 1));
        
    case 'first_half'
        temp_list = list( 1: size(list, 1)/2 );
        
    case 'last_half'
        temp_list = list( size(list, 1)/2 : end );
end

% ...... Step 2a) Remove any dark images ....
[final_list] = remove_darks(temp_list, in_dir,  95, 30);
num_images = size(list, 1);


% ...... Step 3) Write files into "input_images.txt" in cache_dir
image_file = fullfile(cache_dir, images_fname);
fid        = fopen(image_file,'w');
fprintf(fid, '%s\n', final_list(:).name);
fclose(fid);


% ..... Step 4) Copy files in "input_images.txt" to cache_dir
for ii = 1: size(final_list, 1)
    cur_image_src = fullfile(in_dir,    final_list(ii).name);
    cur_image_dst = fullfile(cache_dir, final_list(ii).name);
    no_err = copyfile(cur_image_src, cur_image_dst, 'f');                                      %#ok<NASGU>
   % err_check(~no_err, '......   Error copying files to cache directory .......\n'); 
end


% .... Step 5) Save permanent copy of "input_images.txt" in top dir
no_err = copyfile(image_file,  fullfile(out_dir_top, 'input_images.txt'), 'f' );               %#ok<NASGU>
%err_check(~no_err, '......   Error copying "input_images.txt" files to top reconstruction directory .......\n'); 


% ..... Step 6) Send back jpg image resolution size
jpg_info = imfinfo(fullfile(in_dir, final_list(1).name) );
res      = [jpg_info.Width, jpg_info.Height];


no_err = 1;  % temp -dtmg

end


function synthetic_info = create_images_and_descriptors( num_total_images, im_height, im_width )
%create_images_and_descriptors Summary of this function goes here
%   Detailed explanation goes here
    if ~exist('im_height', 'var')
        im_height = 300;
    end
    
    if ~exist('im_width', 'var')
        im_width = 400;
    end
    
    images = cell(1, num_total_images);
    descriptors = cell(1, num_total_images);
    
    hsv_vals = hsv(num_total_images);
    for image_num = 1:num_total_images
        
        pixel_values = hsv_vals(image_num,:);

        I = zeros(im_height, im_width, 3);

        h = im_height/3; %fill_height_range
        w = im_width/3; %fill_width_range

        I(uint8(h):uint8(h*2),uint8(w):uint8(w*2),1) = pixel_values(1);
        I(uint8(h):uint8(h*2),uint8(w):uint8(w*2),2) = pixel_values(2);
        I(uint8(h):uint8(h*2),uint8(w):uint8(w*2),3) = pixel_values(3);

        %I(:,:,1) = pixel_values(1);
        %I(:,:,2) = pixel_values(2);
        %I(:,:,3) = pixel_values(3);

        %encode importance value in the first red pixel
        imp_value = image_num/num_total_images;
        I(1,1,1) = imp_value;

        %create descriptor for this, dim = 10,000
        B = zeros(10000, 1);
        bin_size = 10000/num_total_images;
        bin_start_ind = image_num*bin_size - bin_size+1;
        bin_end_ind = bin_start_ind + bin_size-1;
        B(bin_start_ind:bin_end_ind) = ones(bin_size, 1)/10;
        B = B';
        images{image_num} = I;
        descriptors{image_num} = B;
    end
    
    synthetic_info.Images = images;
    synthetic_info.Descriptors = descriptors;
end


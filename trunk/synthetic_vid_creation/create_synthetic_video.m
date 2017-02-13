function [ filepath ] = create_synthetic_video( num_total_frames, dir_path, num_total_images, height, width )
%CREATE_SYNTHETIC_VIDEO Creates a synthetic video of num_frames length, and
%saves the video to dir_path

    %% fill optional variables
    if ~exist('num_total_images', 'var')
        num_total_images = 10;
    end

    if ~exist('height', 'var')
        height = 300;
    end

    if ~exist('width', 'var')
        width = 450;
    end

    video_create_start = tic;
    
    %% video properties
    filename = ['synthetic_video_' int2str(num_total_frames) '_' datestr(now,'dd-mm-yyyy_HH:MM:SS.avi')];

    filepath = fullfile(dir_path,filename);
    outputVideo = VideoWriter(filepath);
    outputVideo.FrameRate = 30;
    outputVideo.Quality = 30;
    open(outputVideo)
    
    %% generate video 
    frame_num = 0;
    seg_num = 0;
    while frame_num < num_total_frames
        %sample a segment length with a geometric distribution with parameter p.
        % if p= 0.025 (=1/40), in expectation, there are 40 frames in a segment. One
        %segment contains same image repeated for sge_len number of frames
        p = 0.025;
        seg_len = geornd(p);
        seg_num = seg_num + 1;
        
        %create a synthetic image for this segment
        image_num = mod(seg_num, num_total_images);
        disp(['Creating segment number ' int2str(seg_num) ' with seg length ' int2str(seg_len)]);
        if image_num == 0
            image_num = num_total_images;
        end
        %disp(['image num is ' int2str(image_num)]);
        I = create_synthetic_image(num_total_images, image_num, height, width);
        %image(I);
        
        for ii = 1:seg_len
            if mod(frame_num, 1000) == 0
                disp([int2str(frame_num) '/' int2str(num_total_frames) ' finished']);
            end
            writeVideo(outputVideo,I)
            frame_num = frame_num + 1;
        end
    end
    
    close(outputVideo)
    video_create_time = toc(video_create_start);
    disp(['done creating the video with ' int2str(num_total_frames) ' frames and ' int2str(seg_num) ' segments.' ])
    fprintf('%.2f minutes elapsed\n',video_create_time/60);
      
end


function I = create_synthetic_image(num_total_images, image_num, im_height, im_width)
        hsv_vals = hsv(num_total_images);
        pixel_values = hsv_vals(image_num,:);

        I = zeros(im_height, im_width, 3);

        h = im_height/3; %fill_height_range
        w = im_width/3; %fill_width_range

        I(h:h*2,w:w*2,1) = pixel_values(1);
        I(h:h*2,w:w*2,2) = pixel_values(2);
        I(h:h*2,w:w*2,3) = pixel_values(3);

        %I(:,:,1) = pixel_values(1);
        %I(:,:,2) = pixel_values(2);
        %I(:,:,3) = pixel_values(3);


        %encode importance value in the first red pixel
        imp_value = image_num/num_total_images;
        I(1,1,1) = imp_value;
end



function read_video( filepath )
%READ_VIDEO Summary of this function goes here
%   Detailed explanation goes here

    %make sure matlab can open the video file and read images
    %todo
    start = tic;
    vidReader = VideoReader(filepath);
    k = 1;
    while hasFrame(vidReader)
        if mod(k, 500) == 0
            disp(['Num Frames Done: ' int2str(k)]);
        end
        frame = readFrame(vidReader);  
        image(frame);
        k = k+1;
    end
    runtime = toc(start);
    fprintf('%.2f minutes elapsed\n',runtime/60);
end


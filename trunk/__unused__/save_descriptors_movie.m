close all;
% re-run the video, show track matches between subsequent frames

for k = 2 : nFrames
    I=mov(:,:,:,k);
    tracklets=trackletss{k};
    old_I=mov(:,:,:,k-1);
    tracklets.old_I=old_I;
    if (k>1)
        show_points
        drawnow;
    end
end
%
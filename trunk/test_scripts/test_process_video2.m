% Demonstrate tracking on a video sequence (without building a graph)
profile off;profile on;
close all
BORDER_WIDTH=20;
if (~exist('mov','var'))
options=[];
options.method='surf';
options.verbose=false;
    FILENAME='../../../data/Stata_video/stata_long2.avi';
options.interference_mask=false([960,1280]);
options.interference_mask((end-70):end,1:400)=true;
options.interference_mask(1:BORDER_WIDTH,:)=true;
options.interference_mask(end+1-(1:BORDER_WIDTH),:)=true;
options.interference_mask(:,1:BORDER_WIDTH)=true;
options.interference_mask(:,end+1-(1:BORDER_WIDTH))=true;
   flipvideo=false;
%     FILENAME='../../../data/outdoor1.avi';
% options.interference_mask=false([1920,1080]);
% options.min_num_tracklets=200;
%     flipvideo=true;
    movieObj = VideoReader(FILENAME);
    
    nFrames = movieObj.NumberOfFrames;
    vidHeight = movieObj.Height;
    vidWidth = movieObj.Width;
    clear mov;
    % Preallocate movie structure.
    mov(1:nFrames) = ...
        struct('cdata', zeros(vidHeight, vidWidth, 3, 'uint8'),...
        'colormap', []);
    mov = read(movieObj);
if (flipvideo)
    mov=permute(mov,[2 1 3 4]);
end
end
options.tracklet_cnt_start=0;
tracklets=[];
randn('seed',0);rand('seed',0);
% options.method='ncc';
% track the video using descriptors, frame-by-frame
trackletss={};
for k = 1 : nFrames
    options.current_frame=k;
    %     I = read(movieObj, k);
    I=mov(:,:,:,k);
    tracklets_old=tracklets;
    try
        tracklets=update_tracklets(tracklets_old,I,options);
    catch
        % lost track - restart tracking
        tracklets_old=[];
%         tracklets_old.current_frame=tracklets.current_frame;
        
        try
            tracklets=update_tracklets(tracklets_old,I,options);
        catch
            tracklets=[]; %failed to restart, try next frame
        end
    end
    if (k>1)
        try
        show_points;
        k;
        tracklets2=rmfield(tracklets,'old_I');
        tracklets2=rmfield(tracklets2,'interference_mask');
        catch
        end
        try
        trackletss{k}=tracklets2;
        catch
        end
    end
    options.tracklet_cnt_start=tracklets.tracklet_cnt;
    tracklets.old_I=I;
    drawnow;
end

%%
close all;
% re-run the video, show track matches between subsequent frames
for k = 2 : nFrames
    I=mov(:,:,:,k);
    tracklets=trackletss{k};
    old_I=mov(:,:,:,k-1);
    tracklets.old_I=old_I;
    if (k>1)
        try
        show_points
        catch
        end
        drawnow;
    end
end
%%
% draw a tracking-indices graph
figure;axis;hold on;for k=1:length(trackletss);if isempty(trackletss{k}) continue;end;plot(k*ones(size(trackletss{k}.track_indices(:))),trackletss{k}.track_indices(:),'.');drawnow;end;hold off;xlabel('Frame');ylabel('Track Index');


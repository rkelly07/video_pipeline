% Demonstrate tracking on a video sequence (without building a graph)
profile off;profile on;
close all
BORDER_WIDTH=20;
if (~exist('mov','var'))
options=[];
options.method='surf';
options.verbose=false;
%    flipvideo=false;
%     FILENAME='../../../data/Stata_video/stata_long2.avi';
% options.interference_mask=false([960,1280]);
% options.interference_mask((end-70):end,1:400)=true;
% options.interference_mask(1:BORDER_WIDTH,:)=true;
% options.interference_mask(end+1-(1:BORDER_WIDTH),:)=true;
% options.interference_mask(:,1:BORDER_WIDTH)=true;
% options.interference_mask(:,end+1-(1:BORDER_WIDTH))=true;
    FILENAME='../../../data/kendall_outdoor1/%05d.jpg';
%     FILENAME='../../../data/csail_indoors1/%05d.png';
%     FILENAME='../../../data/indoor1.avi';
    I = imread(sprintf(FILENAME,1));
    flipvideo=true;
    if (flipvideo)
        I=permute(I,[2 1 3 4]);
    I=flipdim(I,2);
    end        
options.interference_mask=false(size(I,1),size(I,2));
% options.interference_mask=false([1920,1080]);
% options.min_num_tracklets=200;
%     movieObj = VideoReader(FILENAME);
    
    max_nFrames = 1e5;
%     I = imread(sprintf(FILENAME,1));
    vidHeight = size(I,1);
    vidWidth = size(I,2);
    clear mov;
    % Preallocate movie structure.
%     mov(1:nFrames) = ...
%         struct('cdata', zeros(vidHeight, vidWidth, 3, 'uint8'),...
%         'colormap', []);
%     mov = read(movieObj);
end
options.tracklet_cnt_start=0;
tracklets=[];
randn('seed',0);rand('seed',0);
% options.method='ncc';
% track the video using descriptors, frame-by-frame
trackletss={};
nFrames=0;
for k = 1 : max_nFrames
    nFrames=nFrames+1;
    I = imread(sprintf(FILENAME,k));
    if (flipvideo)
        I=permute(I,[2 1 3 4]);
    I=flipdim(I,2);
    end
    options.current_frame=k;
    %     I = read(movieObj, k);
%     I=mov;
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
    old_I = imread(sprintf(FILENAME,k-1));
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
    try
    options.tracklet_cnt_start=tracklets.tracklet_cnt;
    catch
        options.tracklet_cnt_start=options.tracklet_cnt_start+1;
    end
    tracklets.old_I=I;
drawnow;
if (mod(k,10)==0)
    disp(k);
end
end

%%
close all;
% re-run the video, show track matches between subsequent frames
for k = 2 : nFrames
    I = imread(sprintf(FILENAME,k));
%     I=read(movieObj,k);
    tracklets=trackletss{k};
%     old_I=read(movieObj,k-1);
    old_I = imread(sprintf(FILENAME,k-1));

    if (flipvideo)
        I=permute(I,[2 1 3 4]);
    I=flipdim(I,2);
        old_I=permute(old_I,[2 1 3 4]);
    old_I=flipdim(old_I,2);
    end
    tracklets.old_I=old_I;
    if (k>1)
        try
        show_points
        title(sprintf('Frame %d - %d pts',k,length(trackletss{k}.track_indices(:))));
        catch
        end
        drawnow;
    end
end
%%
% draw a tracking-indices graph
figure;axis;hold on;for k=1:length(trackletss);if isempty(trackletss{k}) continue;end;plot(k*ones(size(trackletss{k}.track_indices(:))),trackletss{k}.track_indices(:),'.');drawnow;end;hold off;xlabel('Frame');ylabel('Track Index');


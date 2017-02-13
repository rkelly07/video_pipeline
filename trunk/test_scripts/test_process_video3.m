profile off;profile on;
close all
if (~exist('mov','var'))
    FILENAME='../../../data/Stata_video/stata_long2.avi';
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
end
tracklets=[];
options=[];
randn('seed',0);rand('seed',0);
BORDER_WIDTH=20;
options.method='surf';
% options.method='ncc';
options.verbose=false;
options.interference_mask=false([960,1280]);
options.interference_mask((end-70):end,1:400)=true;
options.interference_mask(1:BORDER_WIDTH,:)=true;
options.interference_mask(end+1-(1:BORDER_WIDTH),:)=true;
options.interference_mask(:,1:BORDER_WIDTH)=true;
options.interference_mask(:,end+1-(1:BORDER_WIDTH))=true;
% track the video using descriptors, frame-by-frame
trackletss={};
for k = 1 : nFrames
    %     I = read(movieObj, k);
    I=mov(:,:,:,k);
    tracklets_old=tracklets;
    tracklets=update_tracklets(tracklets_old,I,options);
    if (k>1)
        show_points;
        k;
        tracklets2=rmfield(tracklets,'old_I');
        tracklets2=rmfield(tracklets2,'interference_mask');
        trackletss{k}=tracklets2;
    end
    tracklets.old_I=I;
    drawnow;
end

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
% draw a tracking-indices graph
figure;axis;hold on;for k=1:length(trackletss);if isempty(trackletss{k}) continue;end;plot(k*ones(size(trackletss{k}.track_indices(:))),trackletss{k}.track_indices(:),'.');drawnow;end;hold off;xlabel('Frame');ylabel('Track Index');


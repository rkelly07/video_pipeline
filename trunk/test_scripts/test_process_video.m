profile off;profile on;
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
% options.method='surf';
options.method='ncc';
options.verbose=false;
options.interference_mask=false([960,1280]);
options.interference_mask((end-70):end,1:400)=true;
options.interference_mask(1:BORDER_WIDTH,:)=true;
options.interference_mask(end+1-(1:BORDER_WIDTH),:)=true;
options.interference_mask(:,1:BORDER_WIDTH)=true;
options.interference_mask(:,end+1-(1:BORDER_WIDTH))=true;
% options.corner_detector=struct('filter',fspecial('gaussian',[15 1],4));
% % Read one frame at a time.
trackletss={};
for k = 1 : nFrames
    %     I = read(movieObj, k);
    I=mov(:,:,:,k);
    %     imshow(I,[]);drawnow;
    if (options.verbose)
        figure(mod(k-1,5)+1);
    end
    tracklets_old=tracklets;
    tracklets=update_tracklets(tracklets,I,options);
    if (k>1)
        imshow(double([I,tracklets.old_I])/255,[]);
        hold on;
        for i=1:size(tracklets.old_trackpoints,1)
            plot(size(I,2)+tracklets.old_trackpoints(i,1),tracklets.old_trackpoints(i,2),'b.');
        end
        for i=1:numel(tracklets.track_indices)
            plot(tracklets.current_trackpoints(i,1),tracklets.current_trackpoints(i,2),'b.');
            i2=find(tracklets.old_indices==tracklets.track_indices(i));
            if ~isempty(i2)
                plot([tracklets.current_trackpoints(i,1),size(I,2)+tracklets.old_trackpoints(i2,1)],[tracklets.current_trackpoints(i,2) tracklets.old_trackpoints(i2,2)],'k-.');
                plot(size(I,2)+tracklets.old_trackpoints(i2,1),tracklets.old_trackpoints(i2,2),'r+');
                plot(tracklets.current_trackpoints(i,1),tracklets.current_trackpoints(i,2),'r+');
            end
        end
        hold off
        drawnow;
        disp(tracklets.age)
        tracklets2=rmfield(tracklets,'old_I');
        tracklets2=rmfield(tracklets2,'interference_mask');
        trackletss{end+1}=tracklets2;
    end
    tracklets.old_I=I;
    %     imshow(double(I)/255,[]);hold on;plot(tracklets.current_trackpoints(:,1),tracklets.current_trackpoints(:,2),'r+');hold off
    drawnow;
end
%     mov = read(xyloObj);
%%

close all;
for k = 2 : nFrames
    I=mov(:,:,:,k);
    old_I=mov(:,:,:,k-1);
    tracklets=trackletss{k};
    if (k>1)
        imshow(double([I,old_I])/255,[]);
        hold on;
        for i=1:size(tracklets.old_trackpoints,1)
            plot(size(I,2)+tracklets.old_trackpoints(i,1),tracklets.old_trackpoints(i,2),'b.');
        end
        for i=1:numel(tracklets.track_indices)
            plot(tracklets.current_trackpoints(i,1),tracklets.current_trackpoints(i,2),'b.');
            i2=find(tracklets.old_indices==tracklets.track_indices(i));
            if ~isempty(i2)
                plot([tracklets.current_trackpoints(i,1),size(I,2)+tracklets.old_trackpoints(i2,1)],[tracklets.current_trackpoints(i,2) tracklets.old_trackpoints(i2,2)],'k-.');
                plot(size(I,2)+tracklets.old_trackpoints(i2,1),tracklets.old_trackpoints(i2,2),'r+');
                plot(tracklets.current_trackpoints(i,1),tracklets.current_trackpoints(i,2),'r+');
            end
        end
        hold off
        drawnow;
    end
end    
% Size a figure based on the video's width and height.
hf = figure;
set(hf, 'position', [150 150 vidWidth vidHeight])



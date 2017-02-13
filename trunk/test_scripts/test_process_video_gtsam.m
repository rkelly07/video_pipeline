
import gtsam.*
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
BORDER_WIDTH=20;
% options.method='ncc';
options.method='surf';
options.verbose=false;
options.interference_mask=false([960,1280]);
options.interference_mask((end-70):end,1:400)=true;
options.interference_mask(1:BORDER_WIDTH,:)=true;
options.interference_mask(end+1-(1:BORDER_WIDTH),:)=true;
options.interference_mask(:,1:BORDER_WIDTH)=true;
options.interference_mask(:,end+1-(1:BORDER_WIDTH))=true;
% options.corner_detector=struct('filter',fspecial('gaussian',[15 1],4));
graph=[];
% % Read one frame at a time.
for k = 1 : nFrames
    %     I = read(movieObj, k);
    I=mov(:,:,:,k);
    %     imshow(I,[]);drawnow;
%     if (options.verbose)
%         figure(mod(k-1,5)+1);
%     end
    [tracklets,graph]=update_tracklets(tracklets,I,options,graph);
%     imshow(double(I)/255,[]);hold on;plot(tracklets.current_trackpoints(:,1),tracklets.current_trackpoints(:,2),'r+');hold off
if (k>1)
show_points
    drawnow;
end
    tracklets.old_I=I;
end
%     mov = read(xyloObj);

% Size a figure based on the video's width and height.
hf = figure;
set(hf, 'position', [150 150 vidWidth vidHeight])



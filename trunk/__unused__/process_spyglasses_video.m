% Demonstrate tracking on a video sequence (without building a graph)
function res=process_spyglasses_video(FILENAME,video_processing_options)
if (exist('video_processing_options','var')==0)
    video_processing_options=[];
end
profile off;profile on;
if (video_processing_options.verbose)
    close all
end
BORDER_WIDTH=20;
if (~exist('mov','var'))
    options=[];
    options.method='surf';
    options.verbose=false;
    %     FILENAME='/media/My Passport/MyRecord/20130712/1.ogv';
    options.interference_mask=false([960,1280]);
    options.interference_mask((end-70):end,1:400)=true;
    options.interference_mask(1:BORDER_WIDTH,:)=true;
    options.interference_mask(end+1-(1:BORDER_WIDTH),:)=true;
    options.interference_mask(:,1:BORDER_WIDTH)=true;
    options.interference_mask(:,end+1-(1:BORDER_WIDTH))=true;
    flipvideo=false;
    movieObj = VideoReader(FILENAME);
    
end
options.tracklet_cnt_start=0;
tracklets=[];
randn('seed',0);rand('seed',0);
% options.method='ncc';
% track the video using descriptors, frame-by-frame
trackletss={};
nFrames=1e8;
% This states if you want to gather descriptor values, for statistics
gather_descriptors=true;
if (gather_descriptors)
    descriptors=[];
end
for k = 1 : nFrames
    options.current_frame=k;
    %     I = read(movieObj, k);
    I=read(movieObj,k);
    if (flipvideo)
        I=permute(I,[2 1 3 4]);
    end
    tracklets_old=tracklets;
    if (isfield(tracklets,'old_I')) && norm(double(tracklets.old_I(:)-I(:)))<10
        disp(k);
        continue;
    end
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
    if (mod(k,10)==0)
        disp(k);
    end
    if (gather_descriptors)
        descriptors=[descriptors;tracklets.features];
    end
    if (k>1)
        try
            if (video_processing_options.verbose)
                show_points;
            end
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
    
    if (video_processing_options.verbose)
        title(num2str(k));
        drawnow;
    end
end

%%
% close all;
% % re-run the video, show track matches between subsequent frames
% for k = 2 : nFrames
%     mov=read(movieObj,k);
%     I=mov(:,:,:,1);
%     tracklets=trackletss{k};
%     old_I=mov(:,:,:,k-1);
%     tracklets.old_I=old_I;
%     if (k>1)
%         try
%             show_points
%         catch
%         end
%         drawnow;
%     end
% end
%%
% draw a tracking-indices graph
% figure;axis;hold on;for k=1:length(trackletss);if isempty(trackletss{k}) continue;end;plot(k*ones(size(trackletss{k}.track_indices(:))),trackletss{k}.track_indices(:),'.');drawnow;end;hold off;xlabel('Frame');ylabel('Track Index');
end

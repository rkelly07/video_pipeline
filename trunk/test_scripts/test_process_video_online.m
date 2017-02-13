% Demonstrate tracking on a video sequence (without building a graph)
profile off;profile on;
close all
BORDER_WIDTH=20;
if (~exist('mov','var'))
    options=[];
    options.method='surf';
    options.verbose=false;
    %FILENAME='/media/My Passport/MyRecord/20130712/KANE0302_20130712122913.mp4';
    %FILENAME='/media/My Passport/MyRecord/20130712/KANE0302_20130712122923.ogv';
%     FILENAME='/media/My Passport/MyRecord/20130712/KANE0302_20130712122913.ogv';
    FILENAME='/media/My Passport/MyRecord/20130713/KANE0302_20130713170204.ogv';
%     FILENAME='/media/My Passport/MyRecord/20130715/KANE0302_20130715033833.ogv';

    FILENAME = 'data/test.mp4'

    options.interference_mask=false([960,1280]);
    options.interference_mask((end-70):end,1:400)=true;
    options.interference_mask(1:BORDER_WIDTH,:)=true;
    options.interference_mask(end+1-(1:BORDER_WIDTH),:)=true;
    options.interference_mask(:,1:BORDER_WIDTH)=true;
    options.interference_mask(:,end+1-(1:BORDER_WIDTH))=true;
    flipvideo=false;
    movieObj = VideoReader(FILENAME);
    
    vidHeight = movieObj.Height;
    vidWidth = movieObj.Width;
    clear mov;
    mov = read(movieObj,1);
    % Preallocate movie structure.
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
nFrames=1e8;
% This is you want to gather descriptor values, for statistics
gather_descriptors=true;
gather_bag_of_words=true;
clear_statistics=false;
if (gather_descriptors)
    if (clear_statistics)
    descriptors=[];
    end
end
if (gather_bag_of_words)
    if (clear_statistics)
    bags_of_words=false(0,0);
    end
end
k_start=1;
% k_start=3056;
for k = k_start : nFrames
    options.current_frame=k;
    %     I = read(movieObj, k);
    I=read(movieObj,k);
    tracklets_old=tracklets;
    if (isfield(tracklets,'old_I')) && norm(double(tracklets.old_I(:)-I(:)))/norm(double(I(:)))<0.1
        disp(k);
        continue;
    end
    % extract superpixels
    try
        tracklets=update_tracklets(tracklets_old,I,options);
        tracklets.superpixels=mexSEEDS(I,40);
        tracklets.superpixels=vl_slic(single(I),100,5);
        tracklets.superpixels=tracklets.superpixels+1;
            tracklets.merged_superpixels=update_superpixels(tracklets.superpixels,double(I));
            
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
    if (gather_bag_of_words)
        % note: probably too simplistic for location understanding..
        D=pdist2(tracklets.features,descriptor_representatives);
        [yy,ii]=(min(D,[],2));
%         bow_vec=false(size(descriptor_representatives,1),1);
        bow_vec=hist(ii,1:size(descriptor_representatives,1));
        % todo: handle multiple repetitions of words/descriptors in the same frame
%         bow_vec(ii)=true;
        bags_of_words(:,end+1)=bow_vec;
    end
    if (gather_descriptors)
        if (isfield(tracklets,'new_tracked_ids'))
            new_ids=find(ismember(tracklets.track_indices,tracklets.new_tracked_ids));
            descriptors=[descriptors;tracklets.features(new_ids,:)];
            descriptors;
            subplot(121);imshow(I,[]);hold on;plot(tracklets.current_trackpoints.Location(new_ids,1),tracklets.current_trackpoints.Location(new_ids,2),'r+');hold off            
            try
            new_ids2=find(ismember(tracklets_old.track_indices,tracklets.new_tracked_ids));
            subplot(122);imshow(tracklets.old_I,[]);hold on;plot(tracklets_old.current_trackpoints.Location(new_ids2,1),tracklets_old.current_trackpoints.Location(new_ids2,2),'r+');hold off            
            catch
            end
        else
            try
%         descriptors=[descriptors;tracklets.features];
descriptors;
            catch
            end
        end
    end
    if (k>1)
        try
%             show_points;
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
        tracklets;
    end
    
    tracklets.old_I=I;

%     imshow(I,[]);
    title([num2str(k),' - found ',num2str(size(descriptors,1)),' points']);
    drawnow;
end

%%
close all;
% re-run the video, show track matches between subsequent frames
for k = 2 : nFrames
    mov=read(movieObj,k);
    I=mov(:,:,:,1);
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


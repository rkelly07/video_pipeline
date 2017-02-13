% Demonstrate tracking on a video sequence (without building a graph)
profile off;profile on;
close all
FILE_LIST='video_files_list.txt';
% load image_descriptors_surf_example.mat descriptor_representatives
serversList={'127.0.0.1'};
load streamOut_4000 descriptor_representatives
try
    % load /media/My' Passport'/Data/VOCdevkit_processed/classifiers.mat classifiers
    if (~exist('classifiers','var'))
        load('/home/rosman/Documents/MIT/video_analysis/trunk/learning/classifiers3.mat','classifiers','regressors')
    end
catch
end
load('/home/rosman/Documents/MIT/video_analysis/trunk/learning/blur_classifier3.mat','blur_classifier');
BORDER_WIDTH=20;
verbose=true;
file_list=read_files_list(FILE_LIST);
last_descriptors_check=0;
descriptors_cnt=0;
if (~exist('coreset_stream','var'))
    coreset_stream=[];
end
TEMPORAL_BAG_SIZE=40000;
for file_i=1:length(file_list)
    descriptors=[];
    image_idxs=[];
    bags_of_words=[];
    semantic_cues=[];
    semantic_cues2=[];
    FILENAME=file_list{file_i};
    [FILENAME_pathstr, FILENAME_name, FILENAME_ext]= fileparts(FILENAME);
    OUT_FILENAME=[FILENAME,'_classifiers6.mat'];
    if (exist(OUT_FILENAME))
        continue;
    end
    save(OUT_FILENAME,'FILENAME');
    disp(OUT_FILENAME)
    if (exist('movieObj','var') && strcmp([FILENAME_name,FILENAME_ext],movieObj.Name))
    else
    movieObj = VideoReader(FILENAME);
    end
    clear mov;
    mov = read(movieObj,1);
    options=[];
    options.method='surf';
    options.verbose=false;
    options.interference_mask=false([960,1280]);
    options.interference_mask((end-70):end,1:400)=true;
    options.interference_mask(1:BORDER_WIDTH,:)=true;
    options.interference_mask(end+1-(1:BORDER_WIDTH),:)=true;
    options.interference_mask(:,1:BORDER_WIDTH)=true;
    options.interference_mask(:,end+1-(1:BORDER_WIDTH))=true;
    vidHeight = movieObj.Height;
    vidWidth = movieObj.Width;
    options.tracklet_cnt_start=0;
    tracklets=[];
    
    randn('seed',0);rand('seed',0);
    % options.method='ncc';
    % track the video using descriptors, frame-by-frame
    trackletss={};
    nFrames=1e8;
    % This is you want to gather descriptor values, for statistics
    gather_descriptors=true;
    gather_bag_of_words=false;
    gather_semantic_cues=false;
    compute_candidates_bows=false;
    compute_superpixels=false;
    clear_statistics=false;
    change_L2_threshold=0.15; %0.1
    k_start=1;
    k_old=0;
    try
        frame_numbers=[];
        d_frames=[];
        blur_measure=[];
        blur_measure2=[];
        for k = k_start : nFrames
            options.current_frame=k;
            
            %     I = read(movieObj, k);
            if (exist('I','var'))
                old_I=I;
            end
            I=read(movieObj,k);
            
            tracklets_old=tracklets;
            if (isfield(tracklets,'old_I')) && norm(double(tracklets.old_I(:)-I(:)))/norm(double(I(:)))<change_L2_threshold
                %                 disp(k);
                continue;
            end
            
            frame_numbers(end+1)=k;
            M=40;
            blur_measure(end+1)=estimate_blur(I(M:(end-M),M:(end-M),:));
            Ib=I(M:(end-M),M:(end-M),:);
            Ib=Ib(1:2:end,1:2:end,:);
            
            b_v=estimate_blur_indicators2(Ib,[2*1.5.^[0:4]]);
            blur_measure2(end+1)=svmclassify(blur_classifier,b_v(:)');
            d_frames(end+1)=k-k_old;
            k_old=k;
            try
                tracklets_old=[];
                tracklets=update_tracklets(tracklets_old,I,options);
                if (compute_superpixels)
                    tracklets.superpixels=mexSEEDS(I,50);
                    tracklets.superpixels=tracklets.superpixels+1;
                    tracklets.merged_superpixels=update_superpixels(tracklets.superpixels,double(I));
                end
                if (compute_candidates_bows)
                    %                     RESCALE_FACTOR=4;
                    %                     I2=imresize(I,1/RESCALE_FACTOR,'bilinear');
                    %                 tracklets.boxes = runObjectness(I,500);
                    tracklets.boxes = runObjectness(I(1:4:end,1:4:end,:),400);tracklets.boxes(:,1:4)=tracklets.boxes(:,1:4)*4;
                    tracklets.boxes=prune_boxes_by_mask(tracklets.boxes,options.interference_mask,4);
                    tracklets.boxes=tracklets.boxes(1:min(end,20),:);
                    %                 tracklets.boxes(:,1:4)=tracklets.boxes(:,1:4)*RESCALE_FACTOR;
                    tracklets.objHeatMap = computeObjectnessHeatMap(I,tracklets.boxes);
                end
                %                 tracklets_objects
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
            if (gather_semantic_cues)
                %                 cue=[];
                %                 for i = 1:length(classifiers)
                %                     cue(i)=svmclassify(classifiers{i},bags_of_words(:,end)');
                %                 end
                sbow=generate_semantic_cues(I,[],tracklets.features,tracklets.current_trackpoints,classifiers,descriptor_representatives);
                semantic_cues(:,end+1)=sbow;
            end
            if (compute_candidates_bows)
                try
                    sbow=generate_semantic_cues(I,tracklets.boxes,tracklets.features,tracklets.current_trackpoints,regressors,descriptor_representatives);
                    semantic_cues2(:,end+1)=sbow;
                catch
                end
                
            end
            if (gather_descriptors)&~blur_measure2(end)
                descriptors=[descriptors;tracklets.features];
                image_idxs(end+1)=k;
                if (size(descriptors,1)-last_descriptors_check>TEMPORAL_BAG_SIZE)
                    % Aggregate descriptor examples per class
%                     descriptors_stream=Client(descriptors,serversList);
coreset_stream=update_kmeans_coreset(coreset_stream,descriptors);
CS=coreset_stream.getUnifiedCoreset();
fprintf(['coreset: ',num2str(CS.size()),' points representing a dataset of ',num2str(coreset_stream.numPointsStreamed),' points.\n']);
                    descriptors_cnt=descriptors_cnt+size(descriptors,1);
                    descriptors=[];
% %                     last_descriptors_check=size(descriptors,1);
% %                     save(OUT_FILENAME);
% %                     disp(size(descriptors,1));
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
            if (verbose)
                try
                    subplot(131);imshow(I,[]);title(['blur: ',num2str(blur_measure2(end))]);
                    i1=max(1,size(bags_of_words,2)-2000);
                    %             subplot(122);imshow(bags_of_words(:,i1:end),[0 3]);colormap jet
                    %                 subplot(132);imshow([semantic_cues2(:,i1:end);semantic_cues(:,i1:end);bags_of_words(:,i1:end)/3],[0 1]);colormap jet;
                    drawnow;
                    subplot(132);imshow([imresize(semantic_cues2(:,i1:end),[230,numel(i1:size(semantic_cues2,2))],'nearest')],[]);colormap jet;
                    
                    title([num2str(k),' - found ',num2str(size(descriptors,1)),' points']);
                    drawnow;
                    
                    if (compute_candidates_bows)
                        subplot(133);
                        imshow(tracklets.objHeatMap,[]);
                    end
                catch
                end
            end
        end
    catch
    end
    save(OUT_FILENAME);
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


% Demonstrate tracking on a video sequence (without building a graph)
profile off;profile on;
close all
FILE_LIST='video_files_list.txt';
% load image_descriptors_surf_example.mat descriptor_representatives
load streamOut_4000 descriptor_representatives
try
    % load /media/My' Passport'/Data/VOCdevkit_processed/classifiers.mat classifiers
    if (~exist('classifiers','var'))
    load('/home/rosman/Documents/MIT/video_analysis/trunk/learning/classifiers3.mat','classifiers','regressors')
    end
catch
end
BORDER_WIDTH=20;
verbose=true;
file_list=read_files_list(FILE_LIST);
for file_i=1:length(file_list)
    descriptors=[];
    bags_of_words=[];
    semantic_cues=[];
    semantic_cues2=[];
    FILENAME=file_list{file_i};
%     OUT_FILENAME=[FILENAME,'_classifiers3.mat'];
%     if (exist(OUT_FILENAME))
%         continue;
%     end
%     save(OUT_FILENAME,'FILENAME');
    disp(FILENAME)
    movieObj = VideoReader(FILENAME);
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
    gather_descriptors=false;
    gather_bag_of_words=true;
    gather_semantic_cues=false;
    compute_candidates_bows=true;
    compute_superpixels=false;
    clear_statistics=false;
    change_L2_threshold=0.07; %0.1
    k_start=1;
    k_old=0;
    M=70;
    try
        frame_numbers=[];
        d_frames=[];
        for k = k_start :5: nFrames
%             options.current_frame=k;
            
            %     I = read(movieObj, k);
            I=read(movieObj,k);
            I=I(M:(end-M),M:(end-M),:);
            I=I(1:2:end,1:2:end,:);
            b=estimate_blur(I);
%             b
            imshow(double(rgb2gray(I)),[]);title(['frame ',num2str(k),', blur = ',num2str(b)]);
%             pause(0.5);
            drawnow;
            pause;
        end
    catch
    end
    
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


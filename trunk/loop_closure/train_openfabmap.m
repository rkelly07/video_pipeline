myclear, close all, clc

% video_filenames = read_filelist('my_filelist.txt');
% video_filenames = {'/Users/mikhail/MIT/DATA/idiary/source/stills/stills2.mp4'};
% video_filenames = {'/Users/mikhail/MIT/DATA/idiary/source/BostonTour3/BostonTour3_30x_720p.mp4'};
video_filenames = {'/Users/mikhail/MIT/DATA/idiary/source/BostonTour3/BostonTour3_30x.mp4'};

frame_step = 5;
max_num_features = 500000;
buffer_size = 2000;

% load VQ
% R = single(randn(VQ_dim,desc_dim));
% R = [];

% load boston/d5000
% load VQ_stills
% load VQ_BostonTour3_30x_720p_08201735
load VQ_BostonTour3_30x_08272014

VQ_dim = size(VQ,1);
desc_dim = size(VQ,2);

hst = [];

%%
for file_no = 1:numel(video_filenames)
    % TODO: debug fullpath for the case of already full pathnames not in the
    % startup dat apaths
    video_filename = (video_filenames{file_no});
    % video_filename = fullpath(video_filenames{file_no});
    
    video_info = mex_video_processing('getinfo',video_filename);
    num_frames = video_info(1);
    
    h = mex_video_processing('init',video_filename,'SURF',VQ,desc_dim,0,[0 0]);
    
    V = [];
    W = [];

    %for i = 1:num_frames
    for i = 1:frame_step:num_frames
        
        % mod(i,frame_step) == 0
            fprintf('%d/%d\n',i,num_frames)
            mex_video_processing('setframe',h,i)
            [F,I,~] = mex_video_processing('newframe',h);
            hst=cat(2,hst,F(:));
        %else
        %    mex_video_processing('skipframe',h);
        %end
        
%         if mod(i,frame_step)==0 && exist('V','var') && not(isempty(V))
%             disp([i,size(V,1),size(F_buffer,1)]);
%         end
%         
%         if mod(i,frame_step)==0 && exist('Vi','var') && not(isempty(Vi))
%             imshow(I,[]);
%             hold on;
%             plot(Vi(:,end-1),Vi(:,end),'.');
%             hold off
%             drawnow
%         end

        num_features = size(V,1);
        if num_features > max_num_features
            break
        end
        
    end
    
    mex_video_processing('deinit',h);
    
end

%%
disp(['BOW count: ',num2str(size(hst,2))]);
save tmp_fabmap_pre
tic
fprintf('Building Chow-Liu tree...')
tree = mex_openfabmap('create_tree',hst');
toc
save tmp_fabmap_post
filename = video_filename(paren(strfind(video_filename,'/'),length(strfind(video_filename,'/')))+1:end-4);
save(['fabmap_tree_' filename '_' datestr(now,'mmddHHMM')])

try
% !echo "finished training CL tree\n" | mail -s "finished training CL tree" rosman@mit.edu
catch
end

% ------------------------------------------------
% reformatted with stylefix.py on 2015/07/29 10:01

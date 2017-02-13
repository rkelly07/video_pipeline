myclear, close all, clc

video_filenames = read_filelist('my_filelist.txt');

desc_dim = 66;
VQ_dim = 10000;

frame_step = 12;
max_num_features = 500000;

buffer_size = 200000;

R = single(randn(VQ_dim,desc_dim));

%%
for file_no = 1:numel(video_filenames)
    
    video_filename = fullpath(video_filenames{file_no});
    
    video_info = mex_video_processing('getinfo',video_filename);
    num_frames = video_info(1);
    
    h = mex_video_processing('init',video_filename,'SURF',R,desc_dim,0,[0 0]);
    
    V = [];
    W = [];
    
    F_buffer = [];
    for i = 1:num_frames
        
        if mod(i,frame_step) == 0
            [F,I,~] = mex_video_processing('newframedesc',h);
            if not(isempty(F))
                F_buffer = cat(1,F_buffer,F);
            end
            if size(F_buffer,1) > buffer_size
                [Vi,Wi] = weighted_kmeans(double(F_buffer),(ones(size(F_buffer(:,1)))),5000,false,[],15);
                V = cat(1,V,Vi);
                W = cat(1,W,Wi);
                F_buffer = [];
            end
        else
            mex_video_processing('skipframe',h);
        end
        
        if mod(i,frame_step*20)==0 && exist('V','var') && not(isempty(V))
            disp([i,size(V,1),size(F_buffer,1)]);
        end
        
        if mod(i,frame_step*4)==0 && exist('Vi','var') && not(isempty(Vi))
            imshow(I,[]);
            hold on;
            plot(Vi(:,end-1),Vi(:,end),'.');
            hold off
            drawnow
        end
        
        num_features = size(V,1);
        if num_features > max_num_features
            break
        end
        
    end
    
    mex_video_processing('deinit',h);
    
    if (~isempty(V))
        
        % compute VQ using weighted k-means
        [VQ,VW] = weighted_kmeans(V,W,5000,false);
        VQ = single(VQ);
        VW = single(VW);
        
        % save descriptors to file
        save(['VQ_' video_filename],'VQ','VW') 
        
    end
    
end

% ------------------------------------------------
% reformatted with stylefix.py on 2015/03/12 21:23

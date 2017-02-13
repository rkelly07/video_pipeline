myclear, close all, clc

% video_filenames = read_files_list('my_filelist.txt');
% video_filenames = {'/Users/mikhail/MIT/DATA/idiary/source/stills/stills2.mp4'};
% video_filenames = {'/Users/mikhail/MIT/DATA/idiary/source/BostonTour3/BostonTour3_30x_720p.mp4'};
video_filenames = {'/Users/mikhail/MIT/DATA/idiary/source/BostonTour3/BostonTour3_30x.mp4'};

desc_dim = 66;
VQ_dim = 10000;

frame_step = 120;
max_num_features = 600000;

R = single(randn(VQ_dim,desc_dim));
kdtree = KDTreeSearcher(R);

SHOW_VQ_COLOR = true;
colors = rand(VQ_dim,3);
%colors = jet(VQ_dim);

%%

for file_no = 1:numel(video_filenames)
    
    video_filename = video_filenames{file_no};
    fprintf('aggregating SURF features. filename = %s',video_filename)
    
%     num_frames = mex_video_processing('getframecount',video_filename);
    
    mex_video_info = mex_video_processing('getinfo',video_filename,0);
    video_info.Filename = video_filename;
    video_info.Duration = mex_video_info(1)/ mex_video_info(4);
    video_info.NumFrames = mex_video_info(1);
    video_info.Width = mex_video_info(2);
    video_info.Height = mex_video_info(3);
    video_info.FPS = mex_video_info(4);
    video_info
    
    h = mex_video_processing('init',video_filename,'SURF',R,desc_dim,0);
    
    F = [];
    
    try
        
        f_buffer = [];
        for i = 1:video_info.NumFrames
            
            fprintf('%d/%d\n',i,video_info.NumFrames)
            
            if (mod(i,frame_step)==0)
                [f,I,~] = mex_video_processing('newframedesc',h);
                if (~isempty(f))
                    f_buffer = cat(1,f_buffer,f);
                end
                if (size(f_buffer,1)>10000)
                F = cat(1,F,f_buffer);
                f_buffer = [];
                end
            else
                mex_video_processing('skipframe',h);
            end
            
            if (mod(i,frame_step)==0) 
                if exist('v','var') && ~isempty(f)
                    disp([i,size(f_buffer,1),size(F,1)]);
                    imshow(I,[]);
                    if SHOW_VQ_COLOR
                        [bins,~] = kdtree.knnsearch(f(:,1:size(R,2)));
                        hold on
                        scatter(f(:,(end-1)),f(:,end),100,colors(bins(:),:),'Marker','o','LineWidth',4);
                        hold off
                    else
                        hold on
                        plot(f(:,(end-1)),f(:,end),'xy');
                        hold off
                    end
                    drawnow;
                end
            end
            
            num_features = size(F,1)
            if num_features > max_num_features
                break
            end
            
        end
        mex_video_processing('deinit',h);
    
    catch e
        warning(e.identifier,e.message)
    end
    
    if (~isempty(F))
        
        F = double(F(:,1:(end-2)));
        
        % compute VQ using weighted k-means
        fprintf('Computing weighted k-means\n')
        [VQ,~] = weighted_kmeans(F,(ones(size(F(:,1)))),VQ_dim,false);
        VQ = single(VQ);
        
        % save descriptors to file
        filename = video_filename(paren(strfind(video_filename,'/'),length(strfind(video_filename,'/')))+1:end-4);
        save_filename = ['VQ_' filename '_' datestr(now,'mmddHHMM')];
        save(save_filename,'VQ') 
        
    end
    
end

% ------------------------------------------------
% reformatted with stylefix.py on 2014/11/06 11:48

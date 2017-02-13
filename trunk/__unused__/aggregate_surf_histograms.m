% h=mex_video_processing('init');
dim=5000;
% VQ=single(randn(5000,66));
% load descriptor_representatives_fabmap_new_college
load descriptor_representatives_stata2

VQ=single(descriptor_representatives);
% h = mex_video_processing('init','/usr/local/boston_glass_merged_gaps.mp4','SURF',VQ,0);
% h = mex_video_processing('init','/home/rosman/Documents/MIT/video_analysis/trunk/data/test.mp4','SURF',VQ,0);
% h = mex_video_processing('init','/home/rosman/Downloads/20140929_115118.mp4','SURF',VQ,0);

% video_filenames = read_files_list('localfiles.txt');
% video_filenames = {'/usr/local/boston_glass_merged_gaps.mp4'};
video_filenames = {'/home/rosman/Downloads/boston_glass_merged_gaps_5x.mp4'};
for n = 1:numel(video_filenames)
    
    hx{n} = [];
    H{n} = [];
    
    video_filename = video_filenames{n};
    
    num_frames = mex_video_processing('getframecount',video_filename);
    h = mex_video_processing('init',video_filename,'SURF',VQ,0);
    
    % if (~exist('vs','var'))
    vs=[];
    save_images=true;
    skip_frames=16;
    % end
    images={};
    for i = 1:num_frames
        if (mod(i,skip_frames)==0)
            [v,I,idx]=mex_video_processing('newframe',h);
            disp(i)
            v = v./sum(v);
            H{n} = [H{n} v];
            hx{n} = [hx{n} idx];
            
            if (~isempty(v))
                vs=cat(2,vs,v(:));
            end
            images{i}=I;
        else
            mex_video_processing('skipframe',h);
            
            
            
        end
        if (mod(i,skip_frames)==0) && ~isempty(vs)
                disp([i, size(vs,1)]);
            subplot(121);
            imshow(imresize(vs(:,(max(1,end-1000)):end),[100 100],'bilinear'),[]);
            colormap jet
            subplot(122);
            imshow(I,[]);
            title(num2str(i));
            drawnow;
        end
    end
    
    mex_video_processing('deinit',h);
    
end

myclear, clc

disp('Loading...')

% video_filename = '/Users/mikhail/MIT/DATA/idiary/source/stills/xstills.mp4';
% load VQ_BostonTour3_30x_720p_08201735
% load stills2_coreset_tree_600_5_0826151300
% load fabmap_tree_stills2_08261505

video_filename = '/Users/mikhail/MIT/DATA/idiary/source/BostonTour3/BostonTour3_30x_720p.mp4';
load VQ_BostonTour3_30x_720p_08201735
% load BostonTour3_30x_720p_coreset_tree_11880_120_0824162026
% load fabmap_tree_BostonTour3_30x_720p_08230911



desc_dim = 66;
VQ_dim = 10000;
% R = single(randn(VQ_dim,desc_dim));

% fprintf('testing. filename = %s',video_filename)
% mex_video_info = mex_video_processing('getinfo',video_filename,0);
% video_info.Filename = video_filename;
% video_info.Duration = mex_video_info(1)/ mex_video_info(4);
% video_info.NumFrames = mex_video_info(1);
% video_info.Width = mex_video_info(2);
% video_info.Height = mex_video_info(3);
% video_info.FPS = mex_video_info(4);
% video_info
%
% h = mex_video_processing('init',video_filename,'SURF',R,desc_dim,0);
% I = {};
% F = {};
% for i = 1:video_info.NumFrames
%     [F{i},~,~] = mex_video_processing('newframedesc',h);
%     i
% end

figure(99)

%%
disp('Computing...')

M1 = [];
M2 = [];

% offsets = [];
% xi = 1;
% for i = 1:numel(coreset_tree.Data)
%     if strcmp(coreset_tree.Data{i}.NodeType,'Leaf')
%         fprintf('i = %d\n',i)
%         
%         offsets(xi) = coreset_tree.Data{i}.FrameSpan(1)-1;
%         
%         xj = xi;
%         for j = i:numel(coreset_tree.Data)
%             if strcmp(coreset_tree.Data{j}.NodeType,'Leaf')
%                 fprintf('(%d,%d)\n',i,j)
%                 
%                 desc{i} = coreset_tree.Data{i}.Descriptors;
%                 desc{j} = coreset_tree.Data{j}.Descriptors;
%                 
%                 costs1 = mex_openfabmap('localize',tree,desc{i},desc{j},[0.01 0.001]);
%                 costs1 = -costs1;
%                 
%                 for ii = 1:size(desc{i},1)
%                     for jj = 1:size(desc{j},1)
%                         costs2(ii,jj) = norm(desc{i}(ii,:)-desc{j}(jj,:));
%                     end
%                 end
%                 
%                 M1(xi,xj) = min(costs1(:));
%                 M2(xi,xj) = min(costs2(:));
%                 % M1(xi,xj) = mean(costs1(:));
%                 % M2(xi,xj) = mean(costs2(:));
%                 
%                 xj = xj+1;
%                 
%             end
%         end
%         
%         xi = xi+1;
%         
%     end
% end


skip_frames = 60;
mex_video_info = mex_video_processing('getinfo',video_filename,0);
num_frames = mex_video_info(1);

h = mex_video_processing('init',video_filename,'SURF',VQ,desc_dim,0,[0 0]);

num_test_frames = length(1:skip_frames:num_frames);
frames = cell(1,num_test_frames);

for i = 1:skip_frames:num_frames
    
    fprintf('reading frame %d/%d\n',i,num_frames)
    
    mex_video_processing('setframe',h,i);
    [B,I,~] = mex_video_processing('newframe',h);
    
    frames{i} = I;
    
    figure(99), image(I), axis off
    pause(1)
    
end




disp('Done!')

% save stills_M_min M1 M2 offsets
% save stills_M_avg M1 M2 offsets
save boston_M_min M1 M2 offsets
% save boston_M_avg M1 M2 offsets

%%

% load stills_M_min M1 M2 offsets
% load stills_M_avg M1 M2 offsets
load boston_M_min M1 M2 offsets
% load boston_M_avg M1 M2 offsets

figure(20), clf, hold on

num_frames_per_leaf = 5;
loc_min = 5;
loc_max = 5;

for comp_measure = 1:2
    
    polarity = -1;
    
    eval(sprintf('M = M%d;',comp_measure))
    M = M*polarity;
    
    num_leaf_nodes = length(M);
    
    % for i = 1:length(M)
    %     M(i,i) = 0;
    % end
    
    % M = M(:,sum(M,1)>0);
    % M = M(sum(M,2)>0,:);
    
    % M = M-min(M(:));
    % M = M/max(M(:));
    
    Y = [];
    
    for i = 1:num_leaf_nodes-1
        
        x = M(i,i:end);
        
        % remove outliers
        x(x>mean(x)+2*std(x)) = 0;
        
        % normalize
%         x = x-min(x);
%         x = x/max(x);
        
        loc_idx = 1:min(length(x),loc_min);
        x(loc_idx) = 0;
        
        Y(i,1:length(x)) = x;
        
    end
    
    % figure(20+comp_measure), clf, hold on
    subplot(2,1,comp_measure), hold on
    
    %X = [1:size(Xnan)]*num_frames_per_leaf;
    
    Y(:,1:loc_min) = [];
    Ynan = Y;
    Ynan(Ynan==0) = NaN;
    plot(Ynan')
    
    Y0 = Y;
    Y0(isnan(Y0)) = 0;
    y = sum(Y0,1)./sum(Y0~=0,1);
    y = y(1:end-loc_max);
    plot(y,'k-','linewidth',5)
    
    set(gca,'XTickLabel',(0:10:num_leaf_nodes)*num_frames_per_leaf)
    title('Loop closure confidence')
    xlabel('Time offset (frames)')
    ylabel('Normalized confidence score')
    
end

% figure(123),imshow(fliplr(M))
% colormap(winter)

% M0 = (M+min(M(:)))./max(M(:)+min(M(:)));
% figure,imshow(fliplr(M0))

% ------------------------------------------------
% reformatted with stylefix.py on 2014/11/06 11:48

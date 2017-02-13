clc
if (~exist('stream','var')) % prevent loading twice
load kseg_results
end


load descriptor_representatives_66;
VQs = single(descriptor_representatives(:,1:66));
% figure(800), clf, hold on
filename = which('test.mp4');
vs_h = mex_video_processing('init',filename,VQs);
% vs = VideoStream('test.mp4');

% vs_h = mex_video_processing('init','test.mp4',VQs);
vs = VideoStream('test.mp4');

% % show video segmentation
% for i = 1:D.m
%   DT12 = D.T12;
%   myplot(D.m,2,2*(i-1)+1)
%   imshow(vs.get_frame(DT12(i,1)))
%   subplot(D.m,2,2*(i-1)+2)
%   imshow(vs.get_frame(DT12(i,1)))
% end

%%

% tree coresets list
tree_coresets = {};

% tree coresets start and end times
tree_T12 = {};

for i = 1:length(stream.coresetsList)
  tree_coresets{i} = stream.coresetsList{i};
  tree_T12{i} = [tree_coresets{i}.t1,tree_coresets{i}.t2];
end
tree_coresets{i+1} = D;
tree_T12{i+1} =[P.t1 P.t2];
tree_T12 = cell2mat(tree_T12');

% for i = 1:length(tree_coresets)
%   tree_segx_inds{i} = round(median(tree_coresets{i}.T12,2)*vs.NumFrames/D.n);
% end

%% parse tree levels
tree_nodes = zeros(size(tree_T12,1),1);
for i = 1:size(tree_T12,1)
  tree_nodes(i,1) = 1;
  for j = 1:i-1
    if any(tree_T12(i,1:2)==tree_T12(j,1:2))
      tree_nodes(i,1) = tree_nodes(j,1)+1;
    else
    end
  end
end

num_levels = max(tree_nodes(:,1));
for i = 1:num_levels
  tree_nodes(tree_nodes(:,1)==i,2) = (1:size(tree_T12(tree_nodes(:,1)==i,:),1))';
end

tree_T12

1;

%%

% FRAME_SIZE = [480 854 3];
% gray_fill = ones(FRAME_SIZE)*204;
% tree_imagex = {};

NEW_FRAME_SIZE = [120 160];

key_idx = cell(1,length(tree_coresets));
%key_frames = cell(1,length(tree_coresets));

for i = 1:length(tree_coresets)
  disp(repmat('-',1,80))
  disp(['i = ' num2str(i)])
  
  T12 = tree_coresets{i}.T12;
  
  key_idx{i} = cell(1,length(T12));
  %key_frames{i} = cell(1,length(T12));
  
  children_nodes = [];
  ch1_idx = find(tree_T12(:,1)==tree_coresets{i}.t1)';
  ch2_idx = find(tree_T12(:,2)==tree_coresets{i}.t2)';
  for ii = ch1_idx
    for jj = ch2_idx
      if tree_coresets{ii}.t2+1 == tree_coresets{jj}.t1
        ch1 = ii;
        ch2 = jj;
        children_nodes = [ch1 ch2]
      end
    end
  end
  
  % these are leaf nodes, so read frames from video stream
  if isempty(children_nodes)
    
    for j = 1:size(T12,1)
      
      %disp(repmat('=',1,20))
      %disp(['j = ' num2str(j)])
      
      %ii = median(processed_frame_idx(abs(processed_frame_idx-tree_segx_inds{i}(j))==min(abs(processed_frame_idx-tree_segx_inds{i}(j)))));
      
      kx = floor(median(T12(j,1):T12(j,2)));
      key_idx{i}{j} = kx;
      %key_frames{i}{j} = imresize(vs.get_frame(kx),NEW_FRAME_SIZE);
      
    end
    
  % these are parent nodes so use frames from child nodes
  else
    
    key_idx1 = key_idx{ch1};
    key_idx2 = key_idx{ch2};
    key_idx{i} = [key_idx1 key_idx2];
    
  end
  
  NUM_KEY_FRAMES = 9;
  key_idx{i} = select_key_frames(key_idx{i},vs,NUM_KEY_FRAMES);
  
  %   switch length(iframes)
  %     case 1
  %       tree_imagex{i} = [gray_fill iframes{1} gray_fill;...
  %         gray_fill gray_fill gray_fill];
  %     case 2
  %       tree_imagex{i} = [iframes{1} iframes{2} gray_fill;...
  %         gray_fill gray_fill gray_fill];
  %     case 3
  %       tree_imagex{i} = [iframes{1} iframes{2} iframes{3};...
  %         gray_fill gray_fill gray_fill];
  %     case 4
  %       tree_imagex{i} = [iframes{1} iframes{2} gray_fill;...
  %         iframes{3} iframes{4} gray_fill];
  %     case 5
  %       tree_imagex{i} = [iframes{1} iframes{2} iframes{3};...
  %         iframes{4} iframes{5} gray_fill];
  %     case 6
  %       tree_imagex{i} = [iframes{1} iframes{2} iframes{3};...
  %         iframes{4} iframes{5} iframes{6}];
  %     otherwise
  %       error(1)
  %   end
  
end
disp(repmat('-',1,80))

%%

% figure(900)
% hold on
% for i = 1:size(tree_T12,1)
%   this_level = tree_T12(i,3);
%   nodes_this_level = length(tree_T12(tree_T12(:,3)==this_level));
%   pos_ind = tree_T12(i,4);
%   subplot(num_levels,nodes_this_level,(num_levels-this_level)*nodes_this_level+pos_ind)
%   imshow(tree_imagex{i})
% end

%%
% disp('Pre-loading frames ...')
%
% used_idx = [];
% for i = 1:length(key_idx)
%   used_idx = [used_idx cell2mat(key_idx{i})];
% end
% used_idx = sort(unique(used_idx));
%
% preloaded_frames = cell(1,length(used_idx));
% for i = 1:length(used_idx)
%   fprintf('.')
%   preloaded_frames{used_idx(i)} = imresize(vs.get_frame(used_idx(i)),NEW_FRAME_SIZE);
% end
% fprintf('\n')
%
% disp('Done!')

%%


% num_frames = vs.NumFrames - mod(vs.NumFrames,leaf_size);
% ind = find((tree_T12(:,1)>num_frames | tree_T12(:,2)>num_frames) > 0);
% tree_T12(ind,:) = [];
% tree_nodes(ind,:) = [];


%%
%         mex_video_processing('deinit',h);

udata.vs = vs;
udata.tree_coresets = tree_coresets;
udata.tree_T12 = tree_T12;
udata.tree_nodes = tree_nodes;
udata.key_idx = key_idx;
udata.NEW_FRAME_SIZE = NEW_FRAME_SIZE;
udata
set(0,'UserData',udata);


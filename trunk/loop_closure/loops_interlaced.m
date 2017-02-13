myclear, clc

figure(600), clf

% desc = 'rgb_hist'
desc = 'SURF'

prefix = 'NewCollege';
 
load([prefix 'GroundTruth.mat'])

num_videos = 4;

%%
for n = 1:num_videos
  
  disp('Loading ...')
  load([prefix '_coreset_tree_data' num2str(n)])
  cdata = coreset_tree_data;
  
  leaf_nodes = setdiff(1:length(cdata.coresets),cdata.nodes);
  num_leaf_nodes = length(leaf_nodes);
  num_leaf_frames = num_leaf_nodes*cdata.MAX_KEYFRAMES;
  num_frames = cdata.NUM_FRAMES;
  
  %%
  
  hx = [];
  H = [];
  I = {};
  
  frame_size = [size(cdata.keyframes{1}{1},1) size(cdata.keyframes{1}{1},2)];
  waitbar_h = waitbar(0,'Analyzing image content:');
  for i = 1:num_leaf_nodes
    waitbar(i/num_leaf_nodes,waitbar_h,sprintf('Analyzing image content: %d/%d',i,num_leaf_nodes))
    
    li = leaf_nodes(i);
    %I3x3{i} = zeros(frame_size(1)*3,frame_size(2)*3,3);
    for j = 1:length(cdata.keyframes{li})
      r = mod(j-1,3)+1;
      c = ceil(j/3);
      xj = (1:frame_size(1))+(c-1)*(frame_size(1));
      yj = (1:frame_size(2))+(r-1)*(frame_size(2));
      frame = cdata.keyframes{li}{j};
      I = [I frame];
      %I3x3{i}(xj,yj,:) = frame;
      
      switch desc
        case 'rgb_hist'
          H = [H rgbhist_fast(frame,10,2)];
        case 'SURF'
          h = cdata.desc_coeff{li}(:,j);
          h = h./sum(h);
          H = [H h];
      end
      
    end
    
    hx = [hx cdata.key_idx{li}];
    
  end
  delete(waitbar_h)
  
  %%
  
  D{n} = nan(num_frames,num_frames);
  for i = 1:length(hx)
    for j = i+1:length(hx)
      xi = hx(i);
      xj = hx(j);
      hi = H(:,i);
      hj = H(:,j);
      D{n}(xj,xi) = sum((hi-hj).^2);
    end
  end
    
%   figure(600)
%   subplot(2,num_videos,n)
%   imshow(D{n})
%   title(['video ' num2str(n)],'FontSize',16)
%   set(gca,'YDir','normal')
%   axis on
  
end

%%

% thresholds = [30 25 20]/10000;
thresholds = [22 20 18]/10000;

thresh_dsc = 1;
detection_window = 12;
gt_rounding_factor = 0.1;
diag_boundary = 10;

%%

% ground truth
Tx = imresize(truth,1/detection_window);
Tx(Tx>gt_rounding_factor) = 1;
for i = 1:length(Tx)
    for j = 1:length(Tx)
        Tx(i,j) = Tx(i,j)|Tx(j,i);
        Tx(j,i) = Tx(i,j)|Tx(j,i);
    end
end

figure(600)
subplot(2,length(thresholds),2*length(thresholds))
imshow(Tx)
title('ground truth','FontSize',16)
axis on
set(gca,'YDir','normal')
set(gca,'xticklabel',num2str(round(str2num(get(gca,'xticklabel')).*detection_window)))
set(gca,'yticklabel',num2str(round(str2num(get(gca,'yticklabel')).*detection_window)))

%%
Dx = nan(size(D{1},1)+size(D{2},1)+size(D{3},1)+size(D{4},1));
Dx(1:4:end,1:4:end) = D{1};
Dx(2:4:end,2:4:end) = D{2};
Dx(3:4:end,3:4:end) = D{3};
Dx(4:4:end,4:4:end) = D{4};

num_total_frames = size(Dx,1);

%%
for ti = 1:length(thresholds)
  
  threshold = thresholds(ti);
  gx_size = ceil(num_total_frames/detection_window);
  Gx = zeros(gx_size);
  for i = 1:num_total_frames
    for j = 1:num_total_frames
      if Dx(i,j) <= threshold
        
        %Gij = (1-floor(D0(i,j)/threshold*thresh_dsc)/thresh_dsc)*threshold;
        Gij = 1;
        ix = ceil(i/detection_window);
        jx = ceil(j/detection_window);
        
        if abs(ix-jx) > diag_boundary
          Gx(ix,jx) = max(Gx(ix,jx),Gij);
          Gx(jx,ix) = max(Gx(jx,ix),Gij);
        end
        
      end
    end
  end
  
  gt_pos = find(Tx==1);
  gt_neg = find(Tx==0);
  res_pos = find(Gx==1);
  res_neg = find(Gx==0);
  true_pos = intersect(res_pos,gt_pos);
  false_pos = setdiff(res_pos,true_pos);
  true_neg = intersect(res_neg,gt_neg);
  false_neg = setdiff(res_neg,true_neg);
  
  TP = length(true_pos);
  FP = length(false_pos);
  TN = length(true_neg);
  FN = length(false_neg);
  
  precision = TP/(TP+FP);
  recall = TP/(TP+FN);
  accuracy = (TP+TN)/(TP+FP+TN+FN);
  
  figure(600)
  subplot(2,length(thresholds),ti)
  imshow(Gx)
  title(['threshold = ' num2str(threshold)],'FontSize',16)
  axis on
  set(gca,'YDir','normal')
  set(gca,'xticklabel',num2str(round(str2num(get(gca,'xticklabel')).*detection_window)))
  set(gca,'yticklabel',num2str(round(str2num(get(gca,'yticklabel')).*detection_window)))
  
  disp(repmat('-',1,20))
  disp(['precision = ' num2str(precision)])
  disp(['recall = ' num2str(recall)])
  disp(['accuracy = ' num2str(accuracy)])
  
end



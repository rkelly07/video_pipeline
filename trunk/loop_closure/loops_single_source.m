myclear, clc

% desc = 'rgb_hist'
desc = 'SURF'

uniform = 0 ;

disp('Loading ...')

% load Stata2_coreset_tree_data1_5998_L50
% load Stata2_coreset_tree_data1_5998_L100
load Stata2_coreset_tree_data1_5998_L150
% load Stata2_coreset_tree_data1_5998_L200
% load Stata2_coreset_tree_data1_5998_L300
% load Stata2_coreset_tree_data1_5998_L400

% load boston_ground_truth
load stata2_ground_truth

%%

cdata = coreset_tree_data;
num_frames = cdata.NUM_FRAMES;

leaf_nodes = setdiff(1:length(cdata.coresets),cdata.nodes);
num_leaf_nodes = length(leaf_nodes);
num_leaf_frames = num_leaf_nodes*cdata.MAX_KEYFRAMES;

nodes = leaf_nodes;
num_nodes = length(nodes)

level = 1;
for i = 2:level
  nodes = unique(cdata.nodes(nodes));
  num_nodes = length(nodes)
end

%%

H = [];
hx = [];
I = {};

frame_size = [size(cdata.keyframes{1}{1},1) size(cdata.keyframes{1}{1},2)]
waitbar_h = waitbar(0,'Analyzing image content:');
for i = 1:num_nodes
  waitbar(i/num_nodes,waitbar_h,sprintf('Analyzing image content: %d/%d',i,num_nodes))
  
  li = nodes(i);
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

% sH = sum(H,2);
% [~,ind] = sort(sH);
% ind = ind(end-199:end);
% H = H(ind,:);

%%

if uniform
  %   m = size(H,2)
  %   uniform_idx = [1 ceil((1:m-1)*num_frames/(m-1))];
  %   load stata2_all
  %   H = H0(:,uniform_idx);
  %   hx = hx0(:,uniform_idx);

  load stata2_ground_truth
  
%   load stata2_uniform_5
%   load stata2_uniform_11
  load stata2_uniform_16
%   load stata2_uniform_22
%   load stata2_uniform_33
%   load stata2_uniform_44
  
% idx = setdiff(1:1199,1:11:1199);
% H = H(:,idx);
% hx = hx(idx);

end

%%

disp('Calculating difference matrix')

detection_window = 20;
dx_size = ceil(num_frames/detection_window);
diag_boundary = 10;

% D = nan(num_frames);
Dx = nan(dx_size);

% min_D = inf;

for j = 1:length(hx)
  for i = j+1:length(hx)
    xi = hx(i);
    xj = hx(j);
    hi = H(:,i);
    hj = H(:,j);
    
    Dxixj = sum((hi-hj).^2);
    
    ixx = ceil(xi/detection_window);
    jxx = ceil(xj/detection_window);
    
    if abs(ixx-jxx) > diag_boundary
      Dx(ixx,jxx) = min(Dx(ixx,jxx),Dxixj);
    end
    
%     if D(xj,xi) < min_D
%       min_D = D(xj,xi);
%       min_i = i;
%       min_j = j;
%     end
    
  end
end

D = imresize(Dx,num_frames/dx_size);
D0 = D;

disp('Done!')

%%

% ground truth

% Tx = imresize(truth,dx_size/num_frames);
% Tx(Tx>gt_rounding_factor) = 1;
% for i = 1:length(Tx)
%   for j = 1:length(Tx)
%     Tx(i,j) = Tx(i,j)|Tx(j,i);
%     Tx(j,i) = Tx(i,j)|Tx(j,i);
%   end
% end

T = truth;
T(T>0) = 1;
T2 = rot90(T);
T2 = fliplr(T2);
T = T|T2;
T = flipud(T);
T0 = T;

%%

D = D0;
T = T0;

% clearvars precision recall accuracy

thresholds = [48]/10000;
% thresholds = (10:20:160)/10000;

% D = imresize(D,0.2);
% T = imresize(T,0.2);
% T(T>0) = 1;

% results
disp(repmat('-',1,40))
for ti = 1:length(thresholds)
  
  threshold = thresholds(ti);
  disp(threshold*10000)
  
  G = zeros(size(D));
  for ix = 1:size(D,1)%ceil(num_frames/detection_window)
    for jx = ix+1:size(D,2)%ceil(num_frames/detection_window)
      
      if D(ix,jx) <= threshold || D(jx,ix) <= threshold
        %Gij = (1-floor(Dx(ix,jx)*threshold/threshold*thresh_dsc)/thresh_dsc)
        %Gij = 1;
        %Gx(ix,jx) = max(Gx(ix,jx),Gij);
        %Gx(jx,ix) = max(Gx(jx,ix),Gij);
        G(ix,jx) = 1;
        G(jx,ix) = 1;
      end
      
    end
  end
  

  if length(thresholds) <= 5
    figure(500)
    subplot(2,length(thresholds),ti)
    imshow(G)
    title(['threshold = ' num2str(threshold)],'FontSize',16)
    axis on
    set(gca,'YDir','normal')
    set(gca,'xticklabel',num2str(round(str2num(get(gca,'xticklabel')))))
    set(gca,'yticklabel',num2str(round(str2num(get(gca,'yticklabel')))))
  end
  
  gt_pos = find(T==1);
  gt_neg = find(T==0);
  res_pos = find(G==1);
  res_neg = find(G==0);
  true_pos = intersect(res_pos,gt_pos);
  false_pos = setdiff(res_pos,true_pos);
  true_neg = intersect(res_neg,gt_neg);
  false_neg = setdiff(res_neg,true_neg);
  
  TP = length(true_pos);
  FP = length(false_pos);
  TN = length(true_neg);
  FN = length(false_neg);
  
  precision(ti) = TP/(TP+FP);
  recall(ti) = TP/(TP+FN);
  accuracy(ti) = (TP+TN)/(TP+FP+TN+FN);
  
  disp(['precision = ' num2str(precision(ti))])
  disp(['recall = ' num2str(recall(ti))])
  disp(['accuracy = ' num2str(accuracy(ti))])
  disp(repmat('-',1,20))

end

disp('Done!')

%%

figure(501), clf
hold on
% plot(uniform_r,uniform_p,'xg-','LineWidth',2)
plot(recall,precision,'xb-','LineWidth',2)
xlabel('Recall','FontSize',16)
ylabel('Precision','FontSize',16)
legend({'coreset tree','uniform sampling'},'FontSize',16)

figure(502), clf
hold on
% plot((1:length(thresholds))/length(thresholds),uniform_p,'b:')
% plot((1:length(thresholds))/length(thresholds),uniform_r,'g:')
plot((1:length(thresholds))/length(thresholds),precision,'b-','LineWidth',2)
plot((1:length(thresholds))/length(thresholds),recall,'g-','LineWidth',2)
xlabel('Threshold (Normalized)','FontSize',16)
ylabel('Precision, Recall','FontSize',16)
legend({'Precision (coreset)','Recall (coreset)'},'FontSize',16)

%%

figure(500)

subplot(2,length(thresholds),2*length(thresholds)-1)
D0 = D;
D0 = D0./max(D0(:));
D0(isnan(D)) = 0;
imshow(D0)
title('difference matrix','FontSize',16)
set(gca,'YDir','normal')
caxis([0 0.2])

subplot(2,length(thresholds),2*length(thresholds))
imshow(T)
title('ground truth','FontSize',16)
axis on
set(gca,'YDir','normal')
set(gca,'xticklabel',num2str(round(str2num(get(gca,'xticklabel')))))
set(gca,'yticklabel',num2str(round(str2num(get(gca,'yticklabel')))))


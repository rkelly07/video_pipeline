function [tracklets,graph] = update_tracklets(tracklets,I,options,graph)
warning('off','vision:transition:usesOldCoordinates')

defaults = struct( ...
  'method','SURF',...
  'verbose',false,...
  'current_frame',1,...
  'tracklet_cnt_start',1,...
  'corner_detector',struct( ...
    'filter',fspecial('gaussian',[25 1],5),...
    'CM_NM_suppression_scale',20,...
    'max_corners',250,...
    'min_corner_threshold',0.1),...
  'tracker',struct( ...
    'template_scale',17,...
    'search_window_scale',200,...
    'epipolar_scale',1e-4,...
    'min_num_tracklets',150,...
    'minimum_tracking_points',7,...
    'distance_threshold',5,...
    'min_std_normalized',0.3));

options = incorporate_defaults(options,defaults);

Ihsv = rgb2hsv(I);
% Ibw = rgb2gray(I);
I3=I;
I = double(I(:,:,3));
% switch (lower(options.method))
%   case 'ncc'
%     INF = 1e8;
%     NCC_THRESH = 0.85;
% end
UPDATE_GRAPH = false;
if (nargout>1)
  UPDATE_GRAPH = true;
end
if (isfield(tracklets,'interference_mask'))
  interference_mask = tracklets.interference_mask;
else
  interference_mask = imdilate(options.interference_mask,strel('disk',options.tracker.template_scale*2));
end
switch lower(options.method)
  
%   case 'ncc'
%     if isempty(tracklets)|| ~isfield(tracklets,'current_trackpoints')
%       new_track = true;
%       CM = 0;
%       for d = 1:size(I,3);
%         CM = CM+cornermetric(Ihsv(:,:,3),'FilterCoefficients',options.corner_detector.filter);
%       end
%       CM(interference_mask) = 0;
%       CM = CM+rand(size(CM))*1e-13;
%       local_CM_max = ordfilt2(CM,options.corner_detector.CM_NM_suppression_scale^2,true(options.corner_detector.CM_NM_suppression_scale));
%       maxima = CM =  = local_CM_max&~interference_mask;
%       [maxima_pos.y,maxima_pos.x] = find(maxima);
%       [yy,ii] = sort(CM(maxima),'descend');
%       idxs = ii(1:min(options.corner_detector.max_corners,find(yy<yy(5)/10,1)));
%       tracklets.current_trackpoints = [maxima_pos.x(idxs),maxima_pos.y(idxs)];
%       num_current_trackpoints = size(tracklets.current_trackpoints,1);
%       [dX,dY] = meshgrid(-options.tracker.template_scale:options.tracker.template_scale);
%       templates = {};
%       current_trackpoints = tracklets.current_trackpoints;
%       parfor i = 1:num_current_trackpoints
%         x1 = current_trackpoints(i,1);
%         y1 = current_trackpoints(i,2);
%         
%         X1 = x1+dX;Y1 = y1+dY;
%         template = [];
%         for d = 1:size(I,3)
%           template(:,:,d) = interp2(I(:,:,d),X1,Y1);
%         end
%         templates{i} = template;
%       end
%       tracklets.templates = templates;
%       tracklets.track_indices = 1:num_current_trackpoints;
%       tracklets.track_start = ones(size(tracklets.track_indices));
%       tracklets.current_frame = options.current_frame;
%       tracklets.tracklet_cnt = max(tracklets.track_indices)+1;
%       if UPDATE_GRAPH
%         % initialize gtsam graph
%         [tracklets,graph] = initialize_gtsam_factor_graph(tracklets);
%         
%       end
%     else
%       % tracking already in progress
%       num_current_trackpoints = size(tracklets.current_trackpoints,1);
%       I1 = Ihsv(:,:,3);
%       tracklets.current_frame = tracklets.current_frame+1;
%       newcorners = tracklets.current_trackpoints;
%       match_scores = zeros(num_current_trackpoints,1);
%       parfor i = 1:num_current_trackpoints
%         x1 = tracklets.current_trackpoints(i,1);
%         y1 = tracklets.current_trackpoints(i,2);
%         if (isnan(x1)||isnan(y1)) continue;end
%         X1 = x1+(-options.tracker.search_window_scale:options.tracker.search_window_scale);Y1 = y1+(-options.tracker.search_window_scale:options.tracker.search_window_scale);
% %         if (min(X1(:))<1 || min(Y1(:))<1||max(X1(:))>size(I,2)||max(Y1(:))>size(I,1))
% %           newcorners(i,:) = nan;
% %           continue;
% %         end
% %         search_window = I1(Y1,X1);
%         search_window = [];
%         for d = 1:size(I,3);
%           search_window(:,:,d) = interp2(I(:,:,d),X1(:),Y1(:)','nearest',INF);
%         end
%         template = tracklets.templates{i};
%         score_img = 0;
%         for d = 1:size(I,3);
%           score_img = score_img+normxcorr2(template(:,:,d),search_window(:,:,d));
%         end
%         [match_scores(i),ii] = max(score_img(:));
%         match_scores(i) = match_scores(i)/3;
%         [y2,x2] = ind2sub(size(score_img),ii);
%         x2 = x2+x1-options.tracker.search_window_scale-options.tracker.template_scale-1;
%         y2 = y2+y1-options.tracker.search_window_scale-options.tracker.template_scale-1;
%         newcorners(i,:) = [x2,y2];
%       end
%       tracklets.match_scores = match_scores;
%       hiscore = match_scores>NCC_THRESH;
%       [epi_scores1,F,dists] = get_epipolar_distance_scores(newcorners(hiscore,:),tracklets.current_trackpoints(hiscore,:),options);
%       epi_scores = inf(size(newcorners(:,1)));
%       epi_scores(hiscore) = epi_scores1;
%       tracklets.epi_scores = epi_scores;
% 
%       % Remove invalid tracklets
%       tracklets.old_trackpoints = tracklets.current_trackpoints;
%       tracklets.old_indices = tracklets.track_indices;
%       tracklets.current_trackpoints = newcorners;
%       valid_idx = ~isnan(newcorners(:,1)) & epi_scores<2 & match_scores>NCC_THRESH;
%       validated = validate_ncc_backwards(I,double(tracklets.old_I),tracklets.current_trackpoints(valid_idx,:),tracklets.old_trackpoints(valid_idx,:),options);
%       valid_idx(valid_idx) = valid_idx(valid_idx)&validated;
%       tracklets.valid_idx = valid_idx;
%       if (options.verbose)
%         %imshow(I/255,[]);hold on;plot(newcorners(:,1),newcorners(:,2),'.',newcorners(valid_idx,1),newcorners(valid_idx,2),'r+');hold off
%         subplot(121);imshow(tracklets.old_I,[]);hold on;plot(tracklets.old_trackpoints(:,1),tracklets.old_trackpoints(:,2),'r+');hold off;
%         subplot(122);imshow(double(I)/255,[]);hold on;plot(tracklets.current_trackpoints(:,1),tracklets.current_trackpoints(:,2),'r+');hold off
%         drawnow;
%       end
%       tracklets.track_indices = tracklets.track_indices(valid_idx);
%       tracklets.track_start = tracklets.track_start(valid_idx);
%       tracklets.current_trackpoints = tracklets.current_trackpoints(valid_idx,:);
%       tracklets.templates = {tracklets.templates{valid_idx}};
%       tracklets.age = tracklets.current_frame-tracklets.track_start;
% 
%       % Add new tracklets
%       if (size(tracklets.current_trackpoints,1)<options.tracker.min_num_tracklets)
%         tracklets = find_newinterrest_points(tracklets,I,interference_mask,options);
%       end
%     end
    
  case 'surf'
    if isempty(tracklets)|| ~isfield(tracklets,'current_trackpoints')
      % start new tracker
      I1 = Ihsv(:,:,3);
      
      points = detectSURFFeatures(I1,'MetricThreshold',100,'NumOctaves',5);
      [features,valid_points] = extractFeatures(I1,points);
      [features,valid_points] = remove_feature_by_mask(features,valid_points,interference_mask);
      if (points.Count>options.corner_detector.max_corners)
      [~,strong_pts]=sort(valid_points.Metric,'descend');
      valid_points=valid_points(strong_pts);
      features=features(strong_pts,:);
      end
      
      tracklets.features = features;
      F2(:,1)=interp2(Ihsv(:,:,1),valid_points.Location(:,1),valid_points.Location(:,2));
      F2(:,2)=interp2(Ihsv(:,:,2),valid_points.Location(:,1),valid_points.Location(:,2));
      tracklets.features(:,end+[1 2])=F2;
      tracklets.current_trackpoints = valid_points;
      num_current_trackpoints = valid_points.Count;
      tracklets.track_indices = options.tracklet_cnt_start+(1:num_current_trackpoints);
      if (~isempty(tracklets.track_indices))
        tracklets.tracklet_cnt = max(tracklets.track_indices);
      else
        tracklets.tracklet_cnt = options.tracklet_cnt_start+1;
      end
      tracklets.current_frame = options.current_frame;
      tracklets.track_start = options.current_frame*ones(size(tracklets.track_indices));
      if UPDATE_GRAPH
        % initialize gtsam graph
        [tracklets,graph] = initialize_gtsam_factor_graph(tracklets);
        K = eye(3);R = eye(3);t = [0;0;0];
        tracklets.current_estimated_pose = camstat_struct_from_KRT(K,R,t);
        [tracklets,graph] = add_gtsam_observations(tracklets,graph,tracklets.current_estimated_pose);
        
      end
      tracklets.new_ids = tracklets.track_indices;
      tracklets.new_tracked_ids = [];
      
    else
      % tracking already in progress
      I1 = Ihsv(:,:,3);;
      tracklets.current_frame = tracklets.current_frame+1;
      points = detectSURFFeatures(I1,'MetricThreshold',100,'NumOctaves',5);
      
      [features,valid_points] = extractFeatures(I1,points);
      [features,valid_points] = remove_feature_by_mask(features,valid_points,interference_mask);
      %TODO: make sure this works when tracklets.features also has hsv
      %information
      [idx_pairs,match_metric] =  matchFeatures(tracklets.features(:,1:size(features,2)),features,'MatchThreshold',100); %#ok
      matched_pts1 = tracklets.current_trackpoints.Location(idx_pairs(:,1),:);
      matched_pts2 = valid_points.Location(idx_pairs(:,2),:);
      
      [fRANSAC,inliers] = estimateFundamentalMatrix(matched_pts1,matched_pts2,'Method','MSAC','NumTrials',3000,'DistanceThreshold',options.tracker.distance_threshold);%#ok
      inliers2 = choose_valid_epipolar_line_distance(matched_pts1(inliers,:),matched_pts2(inliers,:),sqrt(numel(I(:,:,1)))/5);
      idxs = find(inliers);
      
      inliers(idxs(~inliers2)) = false;
      if (sum(inliers))<options.tracker.minimum_tracking_points
        error('Not enough tracking points');
      end
      valid_idx = false(size(tracklets.features(:,1)));
      valid_idx(idx_pairs(inliers,1)) = true;
      tracklets.valid_idx = valid_idx;
      tracklets.old_trackpoints = tracklets.current_trackpoints;
      tracklets.old_indices = tracklets.track_indices;
      tracklets.track_indices = tracklets.track_indices(valid_idx);
      if (isfield(tracklets,'new_ids'))
        tracklets.new_tracked_ids = intersect(tracklets.track_indices,tracklets.new_ids);
      else
        tracklets.new_tracked_ids = [];
      end
      tracklets.track_start = tracklets.track_start(valid_idx);
      tracklets.current_trackpoints = valid_points(idx_pairs(inliers,2),:);
      % update gtsam graph,if aiming at reconstruction
      if UPDATE_GRAPH
        K = eye(3);R = eye(3);t = [0;0;0];
        tracklets.current_estimated_pose = camstat_struct_from_KRT(K,R,t);
        [tracklets,graph] = add_gtsam_observations(tracklets,graph,tracklets.current_estimated_pose);
        optimizer = gtsam.LevenbergMarquardtOptimizer(graph,tracklets.graph.initialEstimate,tracklets.graph.parameters);
        initial_solution = optimizer.values();
        for i = 1:20
          optimizer.iterate();
          result = optimizer.values();
        end
      end
      tracklets.features = tracklets.features(valid_idx,:);
      
%       F2(:,1)=interp2(Ihsv(:,:,1),tracklets.current_trackpoints.Location(:,1),tracklets.current_trackpoints.Location(:,2));
%       F2(:,2)=interp2(Ihsv(:,:,2),tracklets.current_trackpoints.Location(:,1),tracklets.current_trackpoints.Location(:,2));
%       tracklets.features(:,end+[1 2])=F2;
      
      tracklets.age = tracklets.current_frame-tracklets.track_start;
      % display results
      if (options.verbose)
        subplot(121);imshow(tracklets.old_I,[]);hold on;plot(tracklets.old_trackpoints(:,1),tracklets.old_trackpoints(:,2),'r+');hold off;
        subplot(122);imshow(double(I)/255,[]);hold on;plot(tracklets.current_trackpoints(:,1),tracklets.current_trackpoints(:,2),'r+');hold off
        drawnow;
      end
      % Add new tracklets
      %
      normalized_std = std(tracklets.current_trackpoints.Location)/sqrt(numel(I(:,:,1)));
      tracklets.normalized_spatial_std = normalized_std;
      if (size(tracklets.current_trackpoints.Location,1)<options.tracker.min_num_tracklets) || min(normalized_std)<options.tracker.min_std_normalized
        tracklets = find_newinterrest_points(tracklets,I3,interference_mask,options);
      else
        tracklets.new_ids = [];
      end
      tracklets.age = tracklets.current_frame-tracklets.track_start;
      %
      
    end
    
end

tracklets.interference_mask = interference_mask;
tracklets.old_I = I3;

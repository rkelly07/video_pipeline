function tracklets=find_newinterrest_points(tracklets,I,interference_mask,options)
switch (lower(options.method))
    case 'ncc'
        CM=0;
        for d=1:size(I,3)
            CM=CM+cornermetric(I(:,:,d),'FilterCoefficients',options.corner_detector.filter);
        end
        CM(interference_mask)=0;
        CM=CM+rand(size(CM))*1e-13;
        local_CM_max=ordfilt2(CM,options.corner_detector.CM_NM_suppression_scale^2,true(options.corner_detector.CM_NM_suppression_scale));
        near_existing_points=false(size(I(:,:,1)));
        for i=1:size(tracklets.current_trackpoints,1)
            near_existing_points(round(tracklets.current_trackpoints(i,2)),round(tracklets.current_trackpoints(i,1)))=true;
        end
        near_existing_points=imdilate(near_existing_points,strel('disk',options.tracker.template_scale*2));
        maxima=CM==local_CM_max&~interference_mask&~near_existing_points;
        [maxima_pos.y,maxima_pos.x]=find(maxima);
        [yy,ii]=sort(CM(maxima),'descend');
        
        idxs=ii(1:min(find(yy<yy(10)/20,1),options.corner_detector.max_corners));
        
        num_old_trackpoints=size(tracklets.current_trackpoints,1);
        tracklets.current_trackpoints=[tracklets.current_trackpoints;[maxima_pos.x(idxs),maxima_pos.y(idxs)]];
        num_current_trackpoints=size(tracklets.current_trackpoints,1);
        
        [dX,dY]=meshgrid(-options.tracker.template_scale:options.tracker.template_scale);
        for i = (num_old_trackpoints+1):num_current_trackpoints
            x1=tracklets.current_trackpoints(i,1);
            y1=tracklets.current_trackpoints(i,2);
            
            X1=x1+dX;Y1=y1+dY;
            template=[];
            for d=1:size(I,3)
                template(:,:,d)=interp2(I(:,:,d),X1,Y1);
            end
            tracklets.templates{end+1}=template;
            tracklets.track_indices(end+1)=tracklets.tracklet_cnt;tracklets.tracklet_cnt=tracklets.tracklet_cnt+1;
            tracklets.track_start(end+1)=tracklets.current_frame;
        end
    case 'surf'
        near_existing_points=false(size(I(:,:,1)));
        for i=1:size(tracklets.current_trackpoints,1)
            near_existing_points(round(tracklets.current_trackpoints.Location(i,2)),round(tracklets.current_trackpoints.Location(i,1)))=true;
        end
        near_existing_points=imdilate(near_existing_points,strel('disk',options.tracker.template_scale*2));
        I1=rgb2gray(I/255);
        I2=I1;I2(interference_mask)=mean(I1(:));
        points = detectSURFFeatures(I2,'MetricThreshold',200,'NumOctaves',5);
        [features, valid_points] = extractFeatures(I1, points);
        [features, valid_points]=remove_feature_by_mask(features, valid_points,interference_mask|near_existing_points);
        num_old_trackpoints=size(tracklets.current_trackpoints,1);
        tracklets.current_trackpoints=vertcat(tracklets.current_trackpoints,valid_points);
        tracklets.features=[tracklets.features;features];
        % tracklets.track_start((end+1):size(features,1))=tracklets.current_frame;
        num_current_trackpoints=size(tracklets.current_trackpoints,1);
        tracklets.new_ids=[];
        for i = (num_old_trackpoints+1):num_current_trackpoints
            tracklets.track_indices(end+1)=tracklets.tracklet_cnt;
            tracklets.new_ids(end+1)=tracklets.tracklet_cnt;
            tracklets.tracklet_cnt=tracklets.tracklet_cnt+1;
            tracklets.track_start(end+1)=tracklets.current_frame;
        end
end

end
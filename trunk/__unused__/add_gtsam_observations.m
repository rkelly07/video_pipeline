function [tracklets,graph]=add_gtsam_observations(tracklets,graph,current_pose_estimate)
j=tracklets.current_frame;
if numel(tracklets.graph.pose_keys)<j
    tracklets.graph.pose_keys{j}=gtsam.symbol('x',j);
end
pose_j=tracklets.graph.pose_keys{j};
calibration_matrix=gtsam.Cal3DS2(current_pose_estimate.K(1,1),current_pose_estimate.K(2,2),current_pose_estimate.K(1,2),current_pose_estimate.K(1,3),current_pose_estimate.K(2,3),0,0,0,0);
for ii=1:length(tracklets.track_indices)
    i=tracklets.track_indices(ii);
    if (numel(tracklets.graph.point_keys)<i)
        % add 3D point key
        tracklets.graph.point_keys{i}=gtsam.symbol('p',i);
        x3=randn(3,1); % TODO: update to triangulation..
        point3_j = gtsam.Point3(x3);
        tracklets.graph.initialEstimate.insert(gtsam.symbol('p',i), point3_j);
    end
    point_i=tracklets.graph.point_keys{i};
    x2=tracklets.current_trackpoints.Location(ii,1);
    y2=tracklets.current_trackpoints.Location(ii,2);
    pt2=gtsam.Point2(double(x2),double(y2));
    graph.add(gtsam.GenericProjectionFactorCal3DS2(pt2,tracklets.graph.measurementNoise1,pose_j,point_i,calibration_matrix)); % add directly to graph
end
R=current_pose_estimate.R;
R=R+randn(3,3)*0.001;[U,~,V]=svd(R);R=U*V';
t=(current_pose_estimate.t)+randn(3,1)*0.01;
pose3_j=gtsam.Pose3(gtsam.Rot3(R),gtsam.Point3(t));
graph.add(gtsam.PriorFactorPose3(pose_j, pose3_j, tracklets.graph.poseNoise1));
tracklets.graph.initialEstimate.insert(pose_j, pose3_j);
if (tracklets.current_frame<3)
    graph.add(gtsam.PriorFactorPose3(pose_j, pose3_j, tracklets.graph.poseNoise1));
end

end
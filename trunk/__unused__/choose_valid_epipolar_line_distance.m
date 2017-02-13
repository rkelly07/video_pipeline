function inliers=choose_valid_epipolar_line_distance(matched_pts1,matched_pts2,scale)
dxs=matched_pts2-matched_pts1;
dX=median(dxs);
% scale2=min(scale,median(dd)*3);
dd=abs(dxs-dX(ones(size(dxs,1),1),:));
scale2=min(scale,(median(dd)+2)*4);
inliers=sum(dd<scale2(ones(size(dd,1),1),:),2)==2;
end
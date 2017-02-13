function [features, valid_points]=remove_feature_by_mask(features, valid_points,mask)
sampled=interp2(double(mask),valid_points.Location(:,1),valid_points.Location(:,2));
idx=sampled==0;
features=features(idx,:);
valid_points=valid_points(idx,:);
end
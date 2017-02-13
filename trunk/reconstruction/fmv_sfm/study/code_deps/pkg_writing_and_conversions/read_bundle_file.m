function [camera,point]=read_bundle_file(filepath)
% function [camera,point]=read_bundle_file(filepath)
%
% Extracts data from a bundle.out file (assumes Bundle file v0.3).  
%
% Inputs:
% filepath - the path to the bundle.out file
%
% Outputs:
% camera - a 3x5xN_cameras array of camera parameters, where:
%       camera(1,1,i) = focal length for camera i
%       camera(2,1,i) = k1 radial distortion coefficient for camera i
%       camera(3,1,i) = k2 radial distortion coefficient for camera i
%       camera(:,2:4) = rotation matrix from camera coordinates to bundler coordinates
%       camera(:,5) = offset vector that gets subtracted in camera coordinates before rotation into bundler coordinates
%
% point - a 1xN_points array of structures with the following fields:
%       position - [x;y;z] position in bundler coordinates
%       color - [r;g;b] color in RGB
%       view - structure describing the view of the point in all cameras that viewed it, with the following fields:
%           camera - N_views(point)x1 array of indices of cameras that viewed the point
%           key - N_views(point)x1 array of indices of SIFT keypoints
%           x - N_views(point)x1 array of x positions of keypoints in the image
%           y - N_views(point)x1 array of y positions of keypoints in the image
%
% For more info on bundle.out files, see:
% http://phototour.cs.washington.edu/bundler/bundler-v0.4-manual.html#S6
%
% Ethan Phelps, 2012-05

fid=fopen(filepath);

% read how many cameras and how many points
how_many=2;
[a,position]=textscan(fid,'%f',how_many,'CommentStyle','#');
n_cams=a{1}(1);
n_points=a{1}(2);

% read camera parameters
how_many=3*5*n_cams;
[a,position]=textscan(fid,'%f',how_many,'CommentStyle','#');
camera=reshape(a{1},[3,5,n_cams]);

if nargout<2
    return
end

% initialize point structure
point=struct('position',[0;0;0],'color',[0;0;0],'view',[]);
point.view=struct('camera',0,'key',0,'x',0,'y',0);
point=repmat(point,[1,n_points]);
% pos=zeros(3,n_points);
% col=zeros(3,n_points);

for kp=1:n_points
    % read position, color, and how many views
    how_many=7; % position, color, n_view
    [a,position]=textscan(fid,'%f',how_many,'CommentStyle','#');
    point(kp).position=a{1}(1:3);
    point(kp).color=a{1}(4:6);
%     pos(:,kp)=a{1}(1:3);
%     col(:,kp)=a{1}(4:6);
    
    n_view=a{1}(7);
    
    % read camera index, key index, image x, and image y for each view
    how_many=4*n_view;
    [b,position]=textscan(fid,'%f',how_many,'CommentStyle','#');
    point(kp).view.camera=b{1}(1:4:end);
    point(kp).view.key=b{1}(2:4:end);
    point(kp).view.x=b{1}(3:4:end);
    point(kp).view.y=b{1}(4:4:end);
end
fclose(fid);
return

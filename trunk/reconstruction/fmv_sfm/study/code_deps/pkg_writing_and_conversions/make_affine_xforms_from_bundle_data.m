function [bdl_A_cam,f,k1,k2]=make_affine_xforms_from_bundle_data(camera)
% function bdl_A_cam=make_affine_xforms_from_bundle_data(camera)
%
% Converts a 3D array of camera parameter data from read_bundle_file.m 
% into a 3D array of affine transform matrices from camera coordinates to 
% bundler-space coordinates.  Also extracts the focal length and radial
% distortion coefficients, which are also contained in the 3D array of
% camera parameters.  
%
% Ethan Phelps, 2012-05

% http://phototour.cs.washington.edu/bundler/bundler-v0.3-manual.html#S6

% [camera,point]=read_bundle_file('\\division10\Projects\SHAPE\data\mit2317\bundle_undistorted.2317.out');

n_cam=size(camera,3);

bdl_A_cam=zeros(4,4,n_cam);
f=zeros(n_cam,1);
k1=zeros(n_cam,1);
k2=zeros(n_cam,1);
for k=1:n_cam
    f(k)=camera(1,1,k); % focal length
    k1(k)=camera(2,1,k); % radial distortion coefficient 1
    k2(k)=camera(3,1,k); % radial distortion coefficient 2
    bdl_R_cam=camera(:,2:4,k);
    t_cam=camera(:,5,k);
    
    %     % works for arbitrary (invertible) matrices
    %     A_inv=[
    %         bdl_R_cam', t_cam;
    %         [0,0,0],    1;
    %         ];
    %
    %     A=inv(A_inv);
    
    % works only for rotation matrices
    A=[
        bdl_R_cam,  -bdl_R_cam*t_cam;
        [0,0,0],    1;
        ];
    
    bdl_A_cam(:,:,k)=A;
end
return

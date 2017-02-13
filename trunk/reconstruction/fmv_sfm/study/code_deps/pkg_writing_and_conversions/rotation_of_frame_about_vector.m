function R=rotation_of_frame_about_vector(u,theta)
% function R=rotation_of_frame_about_vector(u,theta)
%
% Finds the rotation matrix that represents a rotation of a frame by an 
% angle theta about the vector u.  The convention used is a right hand
% rotation of the frame about the vector.  To rotate a point instead of 
% the frame, change the sign of theta or u, but not both.  
%
% Example:
%
% rotation_of_frame_about_vector([0;0;1],pi/6)
% 
% ans =
% 
%     0.8660    0.5000         0
%    -0.5000    0.8660         0
%          0         0    1.0000
%
% Ethan Phelps, 2012-03-06

theta=-theta; % right hand rotation of frame rather than point

w=u(:)/norm(u);

Wx=cross_product_matrix(w);
Wx_sq=w*w'-eye(3); %Wx_sq=Wx*Wx;

R=eye(3)+sin(theta)*Wx+(1-cos(theta))*Wx_sq; % Rodrigues' rotation formula
return

function Wx=cross_product_matrix(w)
Wx=[
    0,      -w(3),  w(2);
    w(3),   0,      -w(1);
    -w(2),  w(1),   0;
    ];
return

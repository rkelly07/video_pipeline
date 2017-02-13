function utm_R_bdl=make_peters_rotation_matrix(az_el_roll)
% function utm_R_bdl=make_peters_rotation_matrix(az_el_roll)
%
% Makes a rotation matrix using Peter Cho's conventions, from a vector of 
% [az; el; roll] in radians.
%
% Ethan Phelps, 2012-05

az=az_el_roll(1);
el=az_el_roll(2);
roll=az_el_roll(3);

Rz=rotation_of_frame_about_vector([0;0;1],az);
Ry=rotation_of_frame_about_vector([0;1;0],-el);
Rx=rotation_of_frame_about_vector([1;0;0],roll);

swap_matrix=[
    -1, 0,  0;
    0,  0,  1;
    0,  1,  0;
    ];

bdl_R_utm=swap_matrix*Rx*Ry*Rz;

utm_R_bdl=bdl_R_utm';
return

function az_el_roll=make_peters_euler_angles(utm_R_bdl)
% function az_el_roll=make_peters_euler_angles(utm_R_bdl)
%
% Makes a vector [az; el; roll] in radians, from a rotation matrix, using 
% Peter Cho's conventions.  See make_peters_rotation_matrix.m
%
% Ethan Phelps, 2012-05

R=utm_R_bdl;

se=-R(3,1);
ce=sqrt(1-se^2); % assumes convention that -pi/2 <= e <= pi/2
sa=-R(2,1)/ce;
ca=-R(1,1)/ce;
sr=R(3,3)/ce;
cr=R(3,2)/ce;

az_el_roll=[
    atan2(sa,ca);
    atan2(se,ce);
    atan2(sr,cr);
    ];
return

%{
% here's a script and its output, that helped with the derivation:

syms a e r real
utm_R_bdl=make_peters_rotation_matrix([a;e;r])

utm_R_bdl =
 
[ -cos(a)*cos(e),   sin(a)*sin(r) - cos(a)*cos(r)*sin(e), - sin(a)*cos(r) - cos(a)*sin(e)*sin(r)]
[ -cos(e)*sin(a), - cos(a)*sin(r) - sin(a)*cos(r)*sin(e),   cos(a)*cos(r) - sin(a)*sin(e)*sin(r)]
[        -sin(e),                          cos(e)*cos(r),                          cos(e)*sin(r)]
  
%}
function ecef_A_bdl=make_affine_xform_from_registration_data(reg,earth,signed_utm_zone)
% function ecef_A_bdl=make_affine_xform_from_registration_data(reg,earth,signed_utm_zone)
%
% Converts registration data in Peter's format into an affine transform 
% matrix that converts from bundler-space into ECEF.  
%
% Inputs:
% reg - structure of registration params with the following fields:
%           (units are degrees and meters here)
%     fitted_world_to_bundler_distance_ratio
%                      bundler_translation_X
%                      bundler_translation_Y
%                      bundler_translation_Z
%                                  global_az
%                                  global_el
%                                global_roll
%                  bundler_rotation_origin_X
%                  bundler_rotation_origin_Y
%                  bundler_rotation_origin_Z
% earth - structure of earth params from make_earth.m
% signed_utm_zone - the UTM zone number, positive for northern hemisphere, 
%       and negative for southern hemisphere
%
% Outputs:
% ecef_A_bdl - an affine transform matrix from bundler-space to ECEF
%
% Ethan Phelps, 2012-05

s=reg.fitted_world_to_bundler_distance_ratio;
bt=[
    reg.bundler_translation_X;
    reg.bundler_translation_Y;
    reg.bundler_translation_Z;
    ];
aer=(pi/180)*[
    reg.global_az;
    reg.global_el;
    reg.global_roll;
    ];
bro=[
    reg.bundler_rotation_origin_X;
    reg.bundler_rotation_origin_Y;
    reg.bundler_rotation_origin_Z;
    ];

utm_R_bdl=make_peters_rotation_matrix(reg.global_az,reg.global_el,reg.global_roll);

% based on Karl's code which seems to work, though it doesn't match Peter's
% description ??
utm_A_bdl=[
    s*utm_R_bdl,    utm_R_bdl*(bt-bro)+bro;
    [0,0,0],        1;
    ];

ecef_A_bdl=make_ecef_affine_from_utm_affine(utm_A_bdl,signed_utm_zone,earth);
return

%{
% for the 2317 dataset:
reg = 

    fitted_world_to_bundler_distance_ratio: 11.2648221644
                     bundler_translation_X: 328141.302781
                     bundler_translation_Y: 4692067.27943
                     bundler_translation_Z: 18.7822026982
                                 global_az: -159.785505829
                                 global_el: 1.14926469438
                               global_roll: -16.5751038749
                 bundler_rotation_origin_X: 328212.210605
                 bundler_rotation_origin_Y: 4692025.66432
                 bundler_rotation_origin_Z: 36.1552629968
%}

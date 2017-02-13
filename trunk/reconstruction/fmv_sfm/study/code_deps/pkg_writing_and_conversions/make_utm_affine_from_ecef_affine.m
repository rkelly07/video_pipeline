function utm_A_other=make_utm_affine_from_ecef_affine(ecef_A_other,signed_utm_zone,earth)
% function utm_A_other=make_utm_affine_from_ecef_affine(ecef_A_other,signed_utm_zone,earth)
%
% Converts an “affine transform to ECEF” into an “affine transform to UTM”.
% Important:  this linearizes around the origin of the other-frame.
%
% Ethan Phelps, 2012-05

% 1. make perturbations from the other-frame origin (in ECEF coords)
% 2. transform to UTM
% 3. use procrustes to find the transform (could use least squares instead)
% 4. construct an affine matrix from the transform
% 5. combine affine transforms to get result

ecef0=ecef_A_other(1:3,4);
temp_ecef=bsxfun(@plus,ecef0,[eye(3),-eye(3)]);

temp_llh=ecr2llh(temp_ecef,earth);
temp_utm=llh2utm(temp_llh,signed_utm_zone,earth);

[d,z,transform]=procrustes(temp_utm',temp_ecef','Scaling',false);

utm_A_ecef=[
    transform.b*transform.T',   mean(transform.c,1)';
    [0,0,0],                    1;
    ];

utm_A_other=utm_A_ecef*ecef_A_other;
return

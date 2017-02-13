function ecef_A_other=make_ecef_affine_from_utm_affine(utm_A_other,signed_utm_zone,earth)
% function ecef_A_other=make_ecef_affine_from_utm_affine(utm_A_other,signed_utm_zone,earth)
%
% Converts an “affine transform to UTM” into an “affine transform to ECEF”.
% Important:  this linearizes around the origin of the other-frame.
%
% Ethan Phelps, 2012-05

% 1. make perturbations from the other-frame origin (in UTM coords)
% 2. transform to ECEF
% 3. use procrustes to find the transform (could use least squares instead)
% 4. construct an affine matrix from the transform
% 5. combine affine transforms to get result

utm0=utm_A_other(1:3,4);
temp_utm=bsxfun(@plus,utm0,[eye(3),-eye(3)]);

temp_llh=utm2llh(temp_utm,signed_utm_zone,earth);
temp_ecef=llh2ecr(temp_llh,earth);

[d,z,transform]=procrustes(temp_ecef',temp_utm','Scaling',false);

ecef_A_utm=[
    transform.b*transform.T',   mean(transform.c,1)';
    [0,0,0],                    1;
    ];

ecef_A_other=ecef_A_utm*utm_A_other;
return

function write_utm_pkg_file(pkg_filepath,photo_filepath,photo_ID,f,aspect_ratio,ecef_A_cam,signed_utm_zone,earth)
% function write_utm_pkg_file(pkg_filepath,photo_filepath,photo_ID,f,aspect_ratio,ecef_A_cam,signed_utm_zone,earth)
%
% Converts data and writes a .pkg file to describe one camera.  
%
% Inputs:
% pkg_filepath - location to write the file to
% photo_filepath - (partial) path to the relevant photo
% photo_ID - photo ID number
% f - focal length (units?)
% aspect_ratio - ratio of # horizontal pixels to # vertical pixels
% ecef_A_cam - affine transform matrix from camera coordinates to ECEF
% signed_utm_zone - UTM zone number, negative if southern hemisphere
% earth - structure of earth parameters from make_earth.m
%
% Outputs:
% a file written to pkg_filepath, that looks like this:
%
% ./IMG_3005-2.rd.jpg
% --photo_ID 1962
% --Uaxis_focal_length -1.35334
% --Vaxis_focal_length -1.35334
% --U0 0.66667
% --V0 0.50000
% --relative_az 170.80902
% --relative_el 5.53512
% --relative_roll 3.30612
% --camera_x_posn 328120.92450
% --camera_y_posn 4691875.19507
% --camera_z_posn 3.84369
% --frustum_sidelength 11.26482
% --downrange_distance -1
%
% Ethan Phelps, 2012-05

utm_A_cam=make_utm_affine_from_ecef_affine(ecef_A_cam,signed_utm_zone,earth);

utm0=utm_A_cam(1:3,4);
utm_R_cam=utm_A_cam(1:3,1:3);

az_el_roll=make_peters_euler_angles(utm_R_cam);

% still need to know photo_filepath, focal lengths, u0, v0,
% frustum_sidelength, and downrange_distance

param.photo_ID=photo_ID;
param.Uaxis_focal_length=f;
param.Vaxis_focal_length=f;
param.U0=0.5*aspect_ratio;
param.V0=0.5;
param.relative_az=az_el_roll(1)*180/pi;
param.relative_el=az_el_roll(2)*180/pi;
param.relative_roll=az_el_roll(3)*180/pi;
param.camera_x_posn=utm0(1);
param.camera_y_posn=utm0(2);
param.camera_z_posn=utm0(3);
param.frustum_sidelength=10;
param.downrange_distance=-1;

field=fieldnames(param);

% write file
fid=fopen(pkg_filepath,'w');
% fprintf(fid,'%s\n','pkg');
% fprintf(fid,'%s\n','-------');
fprintf(fid,'%s\n',photo_filepath);
for k=1:length(field)
    if any(k==[1,13])
        str=['--',field{k},' %d\n'];
    else
        str=['--',field{k},' %0.5f\n']; % looks like Peter uses 5 decimal places
    end
    fprintf(fid,str,param.(field{k}));
end
fclose(fid);
return

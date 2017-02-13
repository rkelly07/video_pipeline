function res=read_bundler_file(filename)
fid = fopen(filename);
a=fscanf(fid,'# Bundle file v0.3\n %d %d\n');
num_cameras=a(1);
num_pts=a(2);
get_points=false;
res.cameras={};
res.points={};
for i = 1:num_cameras
    [res.cameras{i},fid]=read_camera(fid);
    if (mod(i,1000)==1)
        fprintf('.');
    end
end
fprintf('\n');
if (get_points)
for i = 1:num_pts
    res.points{i}=read_point(fid);
    if (mod(i,100000)==1)
        fprintf('.');
    end
end
end
fprintf('\n');
fclose(fid);
end

function [camera,fid]=read_camera(fid)
l=fgetl(fid);
% disp(l);
a=sscanf(l,'%f %f %f',3);
camera.focal_length=a(1);
camera.ks=a(2:3);
l=fgetl(fid);
a1=sscanf(l,'%f %f %f',3);
l=fgetl(fid);
a2=sscanf(l,'%f %f %f',3);
l=fgetl(fid);
a3=sscanf(l,'%f %f %f',3);

camera.R=reshape([a1(:);a2(:);a3(:)],[3 3]);
l=fgetl(fid);
a=sscanf(l,'%f %f %f',3);
camera.t=reshape(a,[3 1]);
end
function point=read_point(fid)
point=[];
end


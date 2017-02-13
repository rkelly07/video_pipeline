addpath('\\division10\Group102\SIGMA\Software\nvmProcessing\quaternions');
addpath('\\division10\Group102\SIGMA\Software\nvmProcessing');
addpath('\\division10\Group102\SIGMA\Software\file_converters');

%infilename = '\\Division10\Group102\SIGMA\Data\fenway_smallset\vSfM_output\fenway_smallset.nvm';
infilename = '\\Division10\Group102\SIGMA\Data\stata\cloud.nvm';

% load transform (from some mysterious source)
load '\\Division10\Group102\SIGMA\Data\stata\xform_nvm2bnd.mat' ; xform1 = xform;
load '\\Division10\Group102\SIGMA\Data\stata\xform_bnd2utm.mat' ; xform2 = xform;
clear xform;

s1 = xform1.b;
R1 = xform1.T';
t1 = mean(xform1.c,1)';

s2 = xform2.b;
R2 = xform2.T';
t2 = mean(xform2.c,1)';

% combine 2 xforms into 1
% T2(T1(X)) = T2(s1*R1*X+t1) = (s2s1)*(R2R1)*X + (s2*R2*t1 + t2)
s = s2*s1;
R = R2*R1;
t = s2*R2*t1 + t2;

% sanity check
apply_xform = @(X,s,R,t) s*R*X+t;
x = rand(3,1);
apply_xform(x,s,R,t) - apply_xform(apply_xform(x,s1,R1,t1),s2,R2,t2) % difference should be tiny



% % random transformation from world frame to bundler frame
% dth1 = 2*pi*rand();
% dth2 = 2*pi*rand();
% dth3 = 2*pi*rand();
% Rx = [1 0 0; 0 cos(dth1) -sin(dth1); 0 sin(dth1) cos(dth1)];
% Ry = [cos(dth2) 0 -sin(dth1); 0 1 0; sin(dth2) 0 cos(dth2)];
% Rz = [0 0 1; cos(dth3) -sin(dth1) 0; sin(dth3) cos(dth3) 0];
% R = Rx*Ry*Rz;
% t = 10*rand(3,1);
% s = 2*rand();


writeIt = true;
invertTransform = false;
models = transform_nvm(infilename,R,t,s,invertTransform,writeIt);




% viz
N = models{1}.points.numPoints;
X = models{1}.points.XYZ; X = X - ones(N,1)*mean(X);
C = models{1}.points.RGB ./ 255;
idxs = randperm(N,20000);
scatter3(X(idxs,1),X(idxs,2),X(idxs,3),3,C(idxs,:));
axis equal;
xlim([prctile(X(:,1),5),prctile(X(:,1),100-5)])
ylim([prctile(X(:,2),5),prctile(X(:,3),100-5)])
zlim([prctile(X(:,2),5),prctile(X(:,3),100-5)])

plyFilename = [infilename(1:end-4),'.xformd.ply'];
writePointcloudPly([models{1}.points.XYZ,models{1}.points.RGB],plyFilename);




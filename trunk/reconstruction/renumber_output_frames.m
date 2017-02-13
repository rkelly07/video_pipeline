% frameDir = 'D:\DDAGOUS\mikepark_challenge\frames';
frameDir = '\\qonos\D\DDAGOUS\mikepark_challenge\frames';
pairListFilename = 'mpc_paths.txt';

% frameDir = 'D:\DDAGOUS\puma';
% pairListFilename = 'puma_paths.txt';

% frameDir = 'D:\DDAGOUS\cam3_left\cam3_left_1fps_cropped';
% pairListFilename = 'cam3_left_paths.txt';

% frameDir = 'D:\DDAGOUS\kagaru\cam0';
% pairListFilename = 'cam0_paths.txt';

% frameDir = 'D:\DDAGOUS\kagaru\cam1';
% pairListFilename = 'cam1_paths.txt';

d = dir(fullfile(frameDir,'*.jpg'));
%d = dir(fullfile(frameDir,'*.ppm'));
filenames = {d.name}';

fid = fopen(fullfile(frameDir,pairListFilename));
data = textscan(fid, '%s%s');
fclose(fid);

f1 = data{1};
f2 = data{2};
I1 = cellfun(@(s) str2num(s(1:end-4)), f1, 'UniformOutput',true);
I2 = cellfun(@(s) str2num(s(1:end-4)), f2, 'UniformOutput',true);
assert(length(I1) == length(I2));
N = length(I1);

copyfile(fullfile(frameDir,pairListFilename),fullfile(frameDir,[pairListFilename,'.bak']));

outfid = fopen(fullfile(frameDir,pairListFilename),'wt');
for i=1:N
    fprintf(outfid,'%s %s\n',filenames{I1(i)},filenames{I2(i)});
end
fclose(outfid);

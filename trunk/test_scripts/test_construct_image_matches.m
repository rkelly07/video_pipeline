% DATA_DIR='/media/My Passport/drl_graffiti';
DATA_DIR='/home/rosman/drl_graffiti';
I=imread('img1.ppm');
profile off;profile on;
files=dir([DATA_DIR,filesep,'*.jpg']);
I=double(I)/255;
[res,template_info]=find_magic_marker(I,I,1);
%% Get initial matches
image_infos={};unmatched={};
for i = 1:numel(files)
    filename=[DATA_DIR,filesep,files(i).name];
    I2=imread(filename);
    I2=double(I2)/255;
    try
    [res,template_info]=find_magic_marker(template_info,I2,5e2);
    catch
        res.score=-1;
    end
    if (res.score>0.4) && size(res.X,1)>7
        disp(i);
        res.filename=filename;
        res.image_num=i;
        res.F=estimateFundamentalMatrix(res.X,res.Y,'Method','Norm8Point');
        image_infos{end+1}=res;
    else
        res.I2=I2;
        unmatched{end+1}=res;
    end
end

%% Extend the graph
for i = 1:numel(files)
    filename=[DATA_DIR,filesep,files(i).name];
    I=imread(filename);
    I=double(I)/255;
    for i2 = i:numel(files)
    filename=[DATA_DIR,filesep,files(i).name];
    I2=imread(filename);
    I2=double(I2)/255;
        
    end
end

% DATA_DIR='/media/My Passport/drl_graffiti';
DATA_DIR='/home/rosman/drl_graffiti';
I=imread('img1.ppm');
profile off;profile on;
files=dir([DATA_DIR,filesep,'*.jpg']);
I=double(I)/255;
[res,template_info]=find_magic_marker(I,I,1);
%%
image_infos={};bad_matches={};
included=[];
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
        % add to graph
        disp(i);
        res.filename=filename;
        
        res.F=estimateFundamentalMatrix(res.X,res.Y,'Method','Norm8Point');
        image_infos{end+1}=res;
        probs(i)=1;
        included(end+1)=i;
    else
        res.I2=I2;
        %         bad_matches{end+1}=res;
    end
end

%%
A=zeros(numel(files));
A(included,included)=1;
%%
for iter=1:numel(files)
    newly_included=[];
    for j_ = 1:numel(included)
        j=included(j_);
        filename1=[DATA_DIR,filesep,files(j).name];
        I1=imread(filename1);
        I1=double(I1)/255;
        fprintf('\n');
        for i = 1:numel(files)
            if (ismember(i,included))
                continue;
            end
            if (A(i,j)>0)
                continue;
            end
            filename2=[DATA_DIR,filesep,files(i).name];
            I2=imread(filename2);
            I2=double(I2)/255;
            try
                [res,template_info]=find_correspondence_color(I1,I2,15e1);
            catch
                res.score=-1;
            end
            if (res.score>0.4) && size(res.X,1)>7
                % add to graph
                disp(i);
                res.filename=filename;
                
                res.F=estimateFundamentalMatrix(res.X,res.Y,'Method','Norm8Point');
                imshow([I1,res.Ic2],[])
                drawnow;
                A(i,j)=0.5;
                if (~ismember(i,included))
                    newly_included(end+1)=i;
                    included(end+1)=i;
                end
            else
%                 disp([num2str(i),',',num2str(j),' - Score: ',num2str(res.score)]);
            end
        end
    end
    if (isempty(newly_included))
        break;
    else
        disp('Added ',num2str(numel(newly_included)),' images');
    end
end
function v=estimate_blur_indicators(I,scales)
I=double(rgb2gray(I));
v=[];
for i=1:numel(scales)
    scale=scales(i);
    flt1=fspecial('Gaussian',max(15,ceil(scale)*4+1),scale);flt1=sum(flt1)/sum(flt1(:));
    I1=imfilter(I,flt1,'replicate');I1=imfilter(I1,flt1','replicate');
    res=abs((I1-I));
    histogram=hist(res(:),1.5.^[0:12]);
    histogram=histogram(2:(end-1));
    v=[v;histogram(:)];
end
end
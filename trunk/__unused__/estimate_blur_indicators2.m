function v=estimate_blur_indicators2(I,scales)

I=double(rgb2gray(I));
nrm_I=std(I(:));
v=[];
for i=1:numel(scales)
    scale=scales(i);
    overall_resp=0;
    for angle=[0:22.5:80]
%     flt1=fspecial('Gaussian',max(15,ceil(scale)*4+1),scale);flt1=sum(flt1)/sum(flt1(:));
flt=zeros(ceil(scale)*2+1);
flt(ceil(end/2),ceil(end/2))=1;
flt(ceil(end),ceil(end/2))=-1;

    flt_r=imrotate(flt,angle,'loose');
    resp=imfilter(I,flt_r,'replicate');
    nhist=hist(abs(resp(:)),-nrm_I:nrm_I/10:nrm_I);
    overall_resp=overall_resp+nhist;
    end
    v=[v;overall_resp(:)];
end
end
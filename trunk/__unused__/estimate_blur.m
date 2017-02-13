function res=estimate_blur(I)
I=double(rgb2gray(I));
flt1=fspecial('Gaussian',15,4);flt1=sum(flt1)/sum(flt1(:));
flt2=fspecial('Gaussian',25,12);flt2=sum(flt2)/sum(flt2(:));
flt3=fspecial('Gaussian',15,2.5);flt3=sum(flt3)/sum(flt3(:));
I3=imfilter(I,flt3,'replicate');I3=imfilter(I3,flt3','replicate');
I1=imfilter(I,flt1,'replicate');I1=imfilter(I1,flt1','replicate');
I2=imfilter(I,flt2,'replicate');I2=imfilter(I2,flt2','replicate');
% If=fft2();
% [X,Y]=meshgrid((1:size(I,2))/size(I,2),(1:size(I,1))/size(I,1));
% mask1=max(X,Y)<0.5;
% mask2=X.^2+Y.^2<(0.1)^2;
% res=1-norm(If.*mask2)/norm(If.*mask1);
% I1=imfilter(I
res=abs((I1-I3))./abs((I2-I3));
res(isinf(res))=nan;
histogram=hist(res(:),[-5:5]'/10+1);
xx=1:length(histogram);mn=histogram(:)'*xx(:)/sum(histogram);st=sqrt(histogram(:)'*(xx(:)-mn).^2/sum(histogram));
res=st;
end
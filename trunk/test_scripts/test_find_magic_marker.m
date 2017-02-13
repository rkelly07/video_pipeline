I=imread('cameraman.tif');
I2=zeros(size(I,1)*2,size(I,2)*2,3);
I1=double(I);
for i=1:3;I(:,:,i)=I1;end
I2(1:size(I,1),1:size(I,2),:)=I;
[res,template_info]=find_magic_marker(I,I2);

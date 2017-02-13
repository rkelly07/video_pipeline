function object_hypotheses=produce_object_hypotheses(superpixels,I,radius,color_dist)
if (min(superpixels)<1)
    error('min(superpixels)<1');
end
num_colors=size(I,3);
img_std_coeff=0;
for c=1:num_colors
    Is{c}=I(:,:,c);
    img_std_coeff=img_std_coeff+var(Is{c}(:));
end
img_std_coeff=sqrt(img_std_coeff/num_colors)/5;
num_superpixels=max(superpixels(:));
for i = 1:num_superpixels
mask_i=superpixels==i;
mask1=imdilate(mask_i,strel('disk',radius));
mask2=imdilate(mask_i,strel('disk',radius*4));
mask3=mask2&~mask1;
    for c=1:num_colors
        v=Is{c};
        v1=v(mask1);
        v2=v(mask3);
        mn(c)=mean(v1(:));
        mn2(c)=mean(v2(:));
        st(c)=std(v1(:));
        st2(c)=std(v2(:));
        err(c)=((mn(c)-mn2(c))/(st(c)+st2(c)+color_dist))^2; 
    end    
    err=sqrt(sum(err)/num_colors);
    
end
end
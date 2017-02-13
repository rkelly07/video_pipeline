function merged_superpixels=update_superpixels(superpixels,I)
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
merged_superpixels=superpixels;
for i = 1:num_superpixels
    mask_i=merged_superpixels==i;
    
    if (sum(mask_i)==0)
        continue;
    end
    mask_nbr=imdilate(mask_i,strel('disk',5));
    mask_far=imdilate(mask_i,strel('disk',40)) & ~mask_nbr;
    for c=1:num_colors
        v=Is{c};
        v2=v(mask_nbr&~mask_i);
        mn(c)=mean(v(mask_i));
        mn2(c)=mean(v2(:));
        st(c)=std(v(mask_i));
        st2(c)=std(v2(:));
    end    
    st=st+img_std_coeff;
    st2=st2+img_std_coeff;
    newidxs=merged_superpixels(mask_nbr&~mask_i);
    newidxs=unique(newidxs);
    add_idx=[];
    for j_=1:numel(newidxs)
        j=newidxs(j_);
    sqr_diff=0;
    for c=1:num_colors
        v=Is{c};
        v2=v(mask_nbr&(merged_superpixels==j));
        mn_j=mean(v2);
 %       st2(c)=std(v(mask_far));
%         st=img_std_coeff;
%         st2=img_std_coeff;
        sqr_diff=sqr_diff+(mn_j-mn(c)).^2./(st(c)^2)-(mn_j-mn2(c)).^2./(st2(c)^2);
    end
        if (sqr_diff<-0.075)
            add_idx(end+1)=j;
        end
    end
    if (~isempty(add_idx))
    merged_superpixels(ismember(merged_superpixels,add_idx))=i;
    end
end
end
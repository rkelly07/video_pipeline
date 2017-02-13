function v=estimate_blur_indicators3(I,scales,invalid_mask)

if (size(I,3)>1)
    I=double(rgb2gray(I));
end
nrm_I=1.5;
v=[];
ISq=I.^2;
flt=fspecial('Gaussian',ceil(scales(end))*6+1,scales(end));
flt=sum(flt)/sum(flt(:));
ISq_flt=imfilter(ISq,flt,'replicate');
ISq_flt=imfilter(ISq_flt,flt','replicate');
I_flt=imfilter(I,flt,'replicate');
I_flt=imfilter(I_flt,flt','replicate');
edge_mask=sqrt((ISq_flt-I_flt.^2))/std(I(:))>0.1;
if (sum(edge_mask(:))/numel(I(:,:,1)))<0.01
error('running blur detector on a flat image');
end
mask_=invalid_mask|~edge_mask;
for i=1:numel(scales)
    scale=scales(i);
    overall_resp=0;
    DX=scale; %consider bluring I for the comparison
    yidx_=(1+DX):(size(I,1)-DX);
    xidx_=(1+DX):(size(I,2)-DX);
        mask=mask_(yidx_,xidx_);
    for c=1:size(I,3)
        
        Ic0=I(yidx_,xidx_,c);
        angles=[0:22.5:80];
        for angle=angles
            
            dx=ceil(cos(angle/180*pi)*DX);
            dy=ceil(sin(angle/180*pi)*DX);
            yidx=yidx_+dy;
            xidx=xidx_+dx;
            Ic=I(yidx,xidx,c);
            resp=(Ic-Ic0)./max(Ic,Ic0);
            nhist=hist(abs(resp(mask)),0:nrm_I/10:nrm_I);
            nhist=nhist/sum(nhist);
            overall_resp=overall_resp+nhist;
            
        end
        
    end
    v=[v;overall_resp(:)/numel(angles)];
end
end
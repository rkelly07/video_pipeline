function [res,v]=compute_acrf_quality(I,v0,b0)
Ix=fft(I,[],2);
Iy=fft(I,[],1);
v=[Ix(:);Iy(:)];
if (nargin>1)
res=real(v0(:)'*v(:)-b0);
else
    res=0;
end


end
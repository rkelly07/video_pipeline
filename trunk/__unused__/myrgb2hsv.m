function res=myrgb2hsv(I)
% 	float min, max, delta;
r=I(:,:,1);g=I(:,:,2);b=I(:,:,3);
% 	min = MIN( r, g, b );
% 	max = MAX( r, g, b );
sizeI1=size(I(:,:,1));
    mx2=max(I,[],3);
    mn2=min(I,[],3);
	v = mx2;				
	delta = mx2 - mn2;
    mx2valid=mx2~=0;
% 	if( mx2 != 0 )
		s(mx2valid) = delta(mx2valid) ./ mx2(mx2valid);
% 	else {
% 		// r = g = b = 0		// s = 0, v is undefined
% 		 = 0;

		h(~mx2valid) = -1;
% 		return;
% 	}
    rmax=I(:,:,1)>I(:,:,2) & I(:,:,1)>I(:,:,3);
    gmax=I(:,:,2)>I(:,:,1) & I(:,:,2)>I(:,:,3);
    bmax=~(gmax|rmax);
    h(rmax)=( g(rmax) - b(rmax) ) ./ delta(rmax);
    h(gmax)=(2 + ( b(gmax) - r(gmax) ) ./ delta(gmax));
    h(bmax)=4 + ( r(bmax) - g(bmax) ) ./ delta(bmax);
% 	if( r == max )
% 		*h = ( g - b ) / delta;		// between yellow & magenta
% 	else if( g == max )
% 		*h = 2 + ( b - r ) / delta;	// between cyan & yellow
% 	else
% 		*h = 4 + ( r - g ) / delta;	// between magenta & cyan

	h =h/6;				
	h( h < 0 )=h( h < 0 )+1;
    res(:,:,3)=v;
    res(:,:,1)=reshape(h,size(v));
    res(:,:,2)=reshape(s,size(v));
% 		*h += 360;
end
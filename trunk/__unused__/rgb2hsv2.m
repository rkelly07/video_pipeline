function h = rgb2hsv2(r)
% r=gpuArray(single(r));
  g = r(:,:,2); b = r(:,:,3); r = r(:,:,1);

v = max(max(r,g),b);
h = zeros(size(v));
s = (v - min(min(r,g),b));

z = ~s;
s = s + z;
k = (r == v);
h(k) = (g(k) - b(k))./s(k);
k = (g == v);
h(k) = 2 + (b(k) - r(k))./s(k);
k = (b == v);
h(k) = 4 + (r(k) - g(k))./s(k);
h = h/6;
k = (h < 0);
h(k) = h(k) + 1;
h=(~z).*h;

k = (v~=0);
s(k) = (~z(k)).*s(k)./v(k);
s(~v) = 0;

%     h = reshape(h,siz);
%     s = reshape(s,siz);
%     v = reshape(v,siz);
    h=cat(3,h,s,v);
    
end

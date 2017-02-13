% returns a high f value for sharper image (less blur)
function f = analyze_blur(I)

% I = gray2rgb(imread('cameraman.tif'));
% hsv = rgb2hsv(I);
% V = hsv(:,:,3);
% W = imfilter(V,fspecial('gaussian',[20 20],10),'replicate');
% figure, imshow(V)
% figure, imshow(W)
% analyze_blur(V)
% analyze_blur(W)

H = fspecial('gaussian',[9 9],10);
B = imfilter(I,H);
D_Fver = abs(I(1:end-1,:)-I(2:end,:));
D_Bver = abs(B(1:end-1,:)-B(2:end,:));
D_Fhor = abs(I(:,1:end-1)-I(:,2:end));
D_Bhor = abs(B(:,1:end-1)-B(:,2:end));
D_Fver = D_Fver(1:end-1);
D_Bver = D_Bver(1:end-1);
D_Fhor = D_Fhor(1:end-1);
D_Bhor = D_Bhor(1:end-1);
Vver = max(zeros(size(D_Fver)),D_Fver-D_Bver);
Vhor = max(zeros(size(D_Fhor)),D_Fhor-D_Bhor);
s_Fver = sum(D_Fver(:));
s_Fhor = sum(D_Fhor(:));
s_Vver = sum(Vver(:));
s_Vhor = sum(Vhor(:));
b_Fver = (s_Fver-s_Vver)/s_Fver;
b_Fhor = (s_Fhor-s_Vhor)/s_Fhor;
f = max(b_Fver,b_Fhor);
f(isnan(f)) = 0;

% invert for positive = sharper
% f = 1-f;

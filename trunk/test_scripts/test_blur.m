P = imread('blurtest.png');
Q{1} = P(:,1:360,:);
Q{2} = P(:,end-360+1:end,:);
g = fspecial('gaussian',[9 9],10);
for i = 1:2
  hsv = rgb2hsv(Q{i});
  F = hsv(:,:,3);
  B = imfilter(F,g);
  D_Fver = abs(F(1:end-1,:)-F(2:end,:));
  D_Bver = abs(B(1:end-1,:)-B(2:end,:));
  D_Fhor = abs(F(:,1:end-1)-F(:,2:end));
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
  blur_F(i) = max(b_Fver,b_Fhor);
end
figure
blur_F
subplot(121), imshow(Q{1})
subplot(122), imshow(Q{2})


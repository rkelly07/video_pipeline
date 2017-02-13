function Xc = chunk_input(X,m,n)

Xc = zeros([m/n size(X,2) n]);
for i = 1:n
  a = (i-1)*(m/n)+1;
  b = i*(m/n);
  Xc(:,:,i) = X(a:b,:);
end

function checkerboard=create_checkerboard(M,N,scale)
[X,Y]=meshgrid(1:N,1:M);
checkerboard=(-1.^(X+Y)+1)/2;
checkerboard=imresize(checkerboard,scale,'nearest');
end
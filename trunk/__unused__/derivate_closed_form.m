syms w l real;

W=[w 2*w;3 4];
A=W'*W;
D=eye(2)*l-A;
det(D);% ->
l1= ((5*w^2 - 4*w + 25)*(5*w^2 + 4*w + 25))^(1/2)/2 + (5*w^2)/2 + 25/2;
l2= (5*w^2)/2 - ((5*w^2 - 4*w + 25)*(5*w^2 + 4*w + 25))^(1/2)/2 + 25/2;
l1s=[];l2s=[];
ws=[0:0.01:5];
for w1=ws
    l1s(end+1)=limit(l1,w,w1);
    l2s(end+1)=limit(l2,w,w1);
end
clear
d1=50;d2=5000;
d3=d1+d2;
d4=100;
N=1000;
max_examples=80000;
%Create data vectors
X1=repmat(eye(d1),[1,N]);
X2=repmat(eye(d1),[1,N]);
Xp1=[X1;randn(d2,size(X1,2))];
Xp2=[X2;randn(d2,size(X2,2))];
Xn1=[X1;randn(d2,size(X1,2))];
for i=1:d1
    idx=randi([1 d1-1],[1,N]);
    idx(idx>=i)=idx(idx>=i)+1;
    idx=idx+[0:d1:(N*d1-1)];
    Xn2(:,i:d1:N*d1)=[X2(:,idx);randn(d2,size(X2,2)/d1)];
end
if (size(Xn2,2)>max_examples)
    idx=randperm(size(Xn1,2),max_examples);
    Xn1=Xn1(:,idx);
    Xn2=Xn2(:,idx);
    idx=randperm(size(Xp1,2),max_examples);
    Xp1=Xp1(:,idx);
    Xp2=Xp2(:,idx);

end
N2=size(Xp1,2);
% initial weights, normalized to [-1,1]
W0=randn(d4,d3);
W0=min(1,max(-1,W0));

siz=size(W0);
lambda=N2*0.01;
F=@(w)weight_different_cost(w,siz,Xp1,Xp2,Xn1,Xn2,lambda);

% [res,fval]=fminunc(F,W0(:),optimset('display','iter','MaxIter',50,'GradObj','on'));
% [res,fval]=fmincon(F,W0(:),[],[],[],[],-ones(size(W0(:))),ones(size(W0(:))),[],optimset('display','iter','MaxIter',100,'GradObj','on'));
proj=@(w)min(1,max(-1,w));
figure(1)
[f_out,w2,stats]=constrained_gd(F,proj,W0,struct('r',d4*N2/2,'iter',10,'outer_iter',4000,'ssize',1/N2/10,'save_history',100));
n1=1000;
figure(2);
subplot(1,2,2);plot((w2*(Xn1(:,1:n1)-Xn2(:,1:n1)))','.');axs=axis;subplot(1,2,1);plot((w2*(Xp1(:,1:n1)-Xp2(:,1:n1)))','.');axis(axs)

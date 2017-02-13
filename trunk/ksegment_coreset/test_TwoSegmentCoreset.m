X = randn(50,3);
X = [X;rand(50,3)];
t1 = 100;
t2 = size(X,1)-1+t1;
t = t1:t2;
eps = 0.1;
cs = TwoSegmentCoreset(X,t1,t2,eps);
Ws = cs.Ws;
% Ts = 1:100;
Ts = cs.Ts;
% Ws = ones(size(Ts));
% Ws = cs.Ws;
% Ts = cs.Ts;
% cs.X = x(Ts);
A = [Ws(:),Ts(:).*Ws(:)];
b = bsxfun(@times,Ws(:),cs.Xs);
p = A\b;
x2 = ones(size(t1:t2))'*p(1,:)+(t1:t2)'*p(2,:);
plot3(t1:t2,X(:,1),X(:,2),'.',cs.Ts,cs.Xs(:,1),cs.Xs(:,2),'ro',t1:t2,x2(:,1),x2(:,2),'k-');
axis image

% ------------------------------------------------
% reformatted with stylefix.py on 2014/05/17 20:27

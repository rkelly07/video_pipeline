function [cost,g]=weight_different_cost(w,siz,xp1,xp2,xn1,xn2,lambda)
%nl=@(x)x % to be used later..
W=reshape(w,siz);
% fp1=W*xp1;
% fp2=W*xp2;
% fn1=W*xn1;
% fn2=W*xn2;
dxp=xp1-xp2;
dxn=xn1-xn2;
clear xp1 xp2 xn1 xn2
dp=W*(dxp);
dn=W*(dxn);
dp1=min(abs(dp),1);
dn1=min(abs(dn),1);
ddp1=sign(dp).*(dp1<1);
ddn1=sign(dn).*(dn1<1);
clear dn dp 
cost=sum(sum(dp1))-sum(sum(dn1))+sum(abs(W(:)))*lambda;
g=ddp1*(dxp)'-ddn1*(dxn)'+lambda*sign(W); % not a true gradient..
% cost=sum(sum(dp1))-sum(sum(dn1))+sum(W(:).^2)*lambda;
% g=ddp1*(xp1-xp2)'-ddn1*(xn1-xn2)'+2*lambda*(W); % not a true gradient..
% cost=sum(sum(abs(dp)))-sum(sum(abs(dn)))+sum(abs(W(:)))*lambda;
% g=sign(dp)*(xp1-xp2)'-sign(dn)*(xn1-xn2)'+lambda*(sign(W)); % not a true gradient..
g=g(:);
end
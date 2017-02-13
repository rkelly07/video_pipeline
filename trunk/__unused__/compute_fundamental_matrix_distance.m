function res=compute_fundamental_matrix_distance(F,x1,x2)
x1_=[x1,ones(size(x1(:,1)))];
x2_=[x2,ones(size(x2(:,1)))];
Fx=F*x2_';
n=sqrt(sum(Fx(1:2,:).^2,1));
Fx=Fx./n([1 1 1],:);
res=abs(sum(x1_'.*(Fx),1));
end
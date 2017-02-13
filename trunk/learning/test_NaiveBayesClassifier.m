N=100;d=20;
X1=randn(N,d)+1;
X2=randn(N,d);
X=[X1;X2];
X1=randn(N,d)+1;
X2=randn(N,d);
% l=ones(n)
class_examples={X1,X2};
NB=NaiveBayesClassifier(class_examples);
prm=randperm(N,30);
prm2=N+randperm(N,30);
[res,ps]=NB.compute_classification(X(prm,:));
[res2,ps2]=NB.compute_classification(X(prm2,:));
disp(log([ps(1)./ps(2), ps2(1)./ps2(2)]))

X1=randn(N*100,d)+1;
X2=randn(N*100,d);
NB=NB.addExamples(1,X1);
NB=NB.addExamples(2,X2);

[res,ps]=NB.compute_classification(X(prm,:));
[res2,ps2]=NB.compute_classification(X(prm2,:));
disp(log([ps(1)./ps(2), ps2(1)./ps2(2)]))


myclear, close all, clc

load test_points
X = [PointList PointList.*2];
T = 1:length(X);
X = X(1:30,:);
T = T(1:30);

tol = 0.6;
[Xs,sample_idx] = DeadRec(X,T,tol)


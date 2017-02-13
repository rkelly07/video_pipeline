classdef TwoSegmentCoreset < handle
  % This class gets an integer n>0 and a number eps in (0,1)
  % and returns a sparse vector w = (w_1,..w_n) of weights (non-negative reals).
  % such that:
  % 1) The sparsity of w is O(log (n)/\eps)
  % 2) For every L in [n] = {1,..,n}
  % and every two real monotonic functions f:[1,..L]-->[0,..,inf) and
  % g: [L+1,..n]-->[0,inf) we have:
  % sum_{i = 1}^L f(i)+sum_{i = L+1}^n g(i) equals to
  % sum_{i = 1}^L w_i f(i)+sum_{i = L+1}^n w_i g(i)
  % up to a multiplicative error of 1 plus epilson.
  
  properties
    t1
    t2
    idx
    Ts
    Xs
    Ws
  end
  
  methods
    
    function this = TwoSegmentCoreset(X,t1,t2,eps)
      this.t1 = t1;
      this.t2 = t2;
      this.computeCoreset(X,eps)
    end
    
    function computeCoreset(this,X,eps)
      
      n = this.t2-this.t1+1;
      is = 1:n;
      s = max(4./is,4./(n-is+1));
      t = sum(s);
      cms = cumsum(s);
      b = ceil(cms/(t*eps)); % real numbers between 0 to s
      [~,B,J] = unique(b); % J is of size n and tells the bin index of each integer in b
      A = accumarray(J(:),b(:)); % sum_{i\in I_j} s_i in the tex file
      
      this.Ws = (1./s(B))'.*A; % the weight of a point is inverse to its sensitivity
      this.idx = B;
      this.Ts = this.t1-1+this.idx;
      this.Xs = X(this.idx,:);
      
    end
    
  end
  
  methods(Static)
    
    function [P,index_list] = GetTwoSegPointSet(D,tol)
      
      X = [];
      index_list = [];
      for i = 1:D.m
        tx1 = D.segments{i}.coresets('SVDSegmentCoreset').t1;
        tx2 = D.segments{i}.coresets('SVDSegmentCoreset').t2;
        Xi = SignalPointSet.LineSegmentPoints(D.segments{i}.coresets('SVDSegmentCoreset').L,tx1:tx2);
        S = TwoSegmentCoreset(Xi,tx1,tx2,tol);
        X = cat(1,X,S.Xs);
        index_list = cat(1,index_list,S.Ts);
      end
      T = D.t1:D.t2;
      index_list = index_list';
      T = T(index_list);
      P = SignalPointSet(X,T);
      
    end
    
  end
  
end

% ------------------------------------------------
% reformatted with stylefix.py on 2014/05/17 21:05

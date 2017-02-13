classdef RDPCoreset < PointSampleCoreset
  
  properties
    
    Xs
    Ws
    
  end
  
  methods
    
    function this = RDPCoreset(P,tol)
      
      this.T = (P.t1:P.t2)';
      this.d = P.d;
      this.n = P.n;
      this.t1 = P.t1;
      this.t2 = P.t2;
      
      if isa(P,'SignalPointSet')
       index_list = 1:(P.t2-P.t1+1);
      elseif isa(P,'KSegmentCoreset')
        % get the aggregate of TwoSegmentCoresets from D
        [P,index_list] = TwoSegmentCoreset.GetTwoSegPointSet(P,tol);
      else
        error('Incorrect type of P')
      end
      
      % compute coreset
      this.computeCoreset(P,index_list,tol);
      
    end
    
  end
  
  methods (Access = protected)
    
    % PointSampleCoreset interface
    function computeCoreset(this,P,index_list,tol)
      
      W = ones(1,P.n);
      
      % construct the coreset
      [this.Xs,this.Ws,this.sample_idx] = RDPCoreset.ComputeRDP(P.X,W,index_list,tol);
      
      this.X = interp1(this.T(this.sample_idx),this.Xs,this.T);
      
      this.m = length(this.sample_idx);
      
    end
    
  end
  
  %% static methods
  methods (Static)
    
    % recursive RDP function
    function [resX,resW,res_idx] = ComputeRDP(X,W,idx,tol)
      
      n = size(X,1);
      
      % recursive condition
      if n <= 2
        resX = X;
        resW = W;
        res_idx = idx;
        return
      end
      
      % compute line fitting
      p1 = [idx(1) X(1,:)];
      p2 = [idx(n) X(n,:)];
      A = [p1(1) 1; p2(1) 1];
      B = [p1(2:end); p2(2:end)];
      L = pinv(A'*A)*A'*B;
      
      % find the point with the maximum distance
      dmax = 0;
      index = 0;
      for i = 2:n-1
        p = X(i,:);
        t = idx(i);
        d = RDPCoreset.ProjectedDistance(p,t,L);
        if d > dmax
          dmax = d;
          index = i;
        end
      end
      
      % if max distance is greater than epsilon, recursively simplify
      if dmax > tol
        % recursive call
        [X1,W1,idx1] = RDPCoreset.ComputeRDP(X(1:index,:),W(1:index),idx(1:index),tol);
        [X2,W2,idx2] = RDPCoreset.ComputeRDP(X(index:n,:),W(index:n),idx(index:n),tol);
        % build the result list
        resX = [X1; X2(2:end,:)];
        resW = [W1 W2(2:end)];
        res_idx = [idx1 idx2(2:end)];
      else
        resX = X([1 n],:);
        resW = W([1 n]);
        res_idx = idx([1 n]);
      end
      
    end
    
    % find distance from p(t) to L
    function d = ProjectedDistance(p,t,L)
      
      d = norm(L(1,:)*t+L(2,:)-p,'fro');
      
      d(d<1e-10) = 0;
      
    end
    
  end
  
end


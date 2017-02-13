classdef RandomSampleCoreset < PointSampleCoreset

  methods
    
    function this = RandomSampleCoreset(P,m)
      this.computeCoreset(P,m);
    end
    
  end
  
  methods (Access = protected)
    
    % PointSampleCoreset interface
    function computeCoreset(this,P,m)
    
      % make sure number of segments does not exceed n
      m = min(m,P.n);
      
      this.T = P.T;
      this.d = P.d;
      this.n = P.n;
      this.m = m;
      this.t1 = P.t1;
      this.t2 = P.t2;
      
      % construct the coreset
      this.sample_idx = [1 sort(randperm(this.n-2,m-2)+1) this.n];
      Xs = P.X(this.sample_idx,:);
      this.X = interp1(this.T(this.sample_idx),Xs,this.T);
      
    end
    
  end
  
end


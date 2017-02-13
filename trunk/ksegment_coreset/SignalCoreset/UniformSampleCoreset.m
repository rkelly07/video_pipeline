classdef UniformSampleCoreset < PointSampleCoreset
  
  methods
    
    function this = UniformSampleCoreset(P,m)
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
      
      % mean construction:
      %   for i = 1:m
      %     xa = ceil((i-1)*this.n/m)+1;
      %     xb = ceil(i*this.n/m);
      %     this.X(xa:xb,:) = repmat(mean(P.X(xa:xb,:),1),xb-xa+1,1);
      %   end
      
      % interp construction:
      %   this.sample_idx = 1;
      %   for i = 2:m
      %     this.sample_idx(i) = ceil(i*this.n/m);
      %   end
      this.sample_idx = [1 ceil((1:m-1)*this.n/(m-1))];
      Xs = P.X(this.sample_idx,:);
      this.X = interp1(this.T(this.sample_idx),Xs,this.T);
      
    end
    
  end
  
end


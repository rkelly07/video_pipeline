classdef CholeskySegmentCoreset < AbstractKernelCoreset
  %CholeskySegmentCoreset Summary of this class goes here
  %   Detailed explanation goes here
  
  methods
    
    % constructor
    function this = CholeskySegmentCoreset(varargin)
      
      if nargin == 3
        L = varargin{1};
        t1 = varargin{2};
        t2 = varargin{3};
        this.d = size(L,2);
        this.n = t2-t1+1;
        this.t1 = t1;
        this.t2 = t2;
        
        this.computeCoreset(L,t1,t2);
        this.computeOptLine();
      end
      
    end
    
  end
  
  methods (Access = protected)
    
    % compute coreset
    function this = computeCoreset(this,L,t1,t2)
      
      % Cholesky kernel
      c1 = sqrt(((t2*(t2+1)*(2*t2+1))/6)-((t1*(t1-1)*(2*t1-1))/6));
      c2 = ((t2*(t2+1)/2)-(t1*(t1-1)/2))/c1;
      c3 = sqrt(t2-t1+1-c2^2);
      G = [c1 c2; 0 c3];
      
      u = L(1,:);
      v = L(2,:);
      H = [G G*[u;v]];
      
      [~,D,V] = svd(H);
      this.C = D*V';
      
    end
    
  end
  
end


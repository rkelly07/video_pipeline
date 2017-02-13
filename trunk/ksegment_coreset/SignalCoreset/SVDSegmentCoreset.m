classdef SVDSegmentCoreset < AbstractKernelCoreset
  %SVDSegmentCoreset Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    
    z   % dimensionality reduction parameter
    w   % energy threshold parameter
    
    d0  % reduced dimension
    cost_residual = 0
    
  end
  
  methods
    
    % constructor
    function this = SVDSegmentCoreset(varargin)
      
      input = inputParser;
      validationFcn = @(P) isa(P,'PointFunctionSet');
      input.addOptional('P',[],validationFcn);
      input.addOptional('z',[],@isnumeric);
      input.addOptional('w',[],@isnumeric);
      input.parse(varargin{:});
      
      if not(isempty(input.Results.P))
        
        P = input.Results.P;        
        this.d = P.d;
        this.d0 = this.d;
        this.n = length(P.T);
        this.t1 = min(P.T);
        this.t2 = max(P.T);
        
        if not(isempty(input.Results.z))
          this.z = input.Results.z;
        else
          this.z = P.d+2;
        end

        if not(isempty(input.Results.w))
          this.w = input.Results.w;
        else
          this.w = 1;
        end
        
        this.computeCoreset(P);
        this.computeOptLine();
        
      end
      
    end
    
    % copy coreset (OVERLOADED)
    function new = copy(this)
      
      % call base class copy
      new = copy@AbstractKernelCoreset(this);
      
      new.z = this.z;
      new.w = this.w;
      
    end
    
    function compressEnergy(this,D)

      diag_D = diag(D);
      csum = cumsum(diag_D);
      energy_threshold = this.w*csum(end);

      this.d0 = find(csum>=energy_threshold,1,'first');
      this.d0 = max(this.d0,2); % must be a line
      this.d0 = min(this.d0,length(D)); % case where D is a single value
      this.C = this.C(1:this.d0,:);

      % compute cost residual
      diag_D0 = [diag_D(1:this.d0); zeros(length(D)-this.d0,1)];
      this.cost_residual = norm(diag_D-diag_D0);
        
    end
    
    function recomputeCoreset(this)
      
      % recompute SVD
      %[~,D,V] = svds(this.C,this.z);
      [~,D,V] = svd(this.C,'econ');
      this.C = D*V';
      
      this.compressEnergy(D);
      
      this.computeOptLine();
      
    end
    
    function computeOptLine(this)
      
      % base class opt line
      computeOptLine@AbstractKernelCoreset(this);
      
      this.cost = this.cost + this.cost_residual;
      
    end
    
    function res=getNumKeypoints(obj)
      res=1;
    end
    
  end
  
  methods (Access = protected)
    
    % compute coreset
    function this = computeCoreset(this,P)
      
      %   if P.d+2 > size(P.AX,1)
      %     [~,D,V] = svd(P.AX,'econ');
      %   else
      %     [~,D,V] = svds(P.AX,P.d+2);
      %   end
            
      % compute SVD
      %[~,D,V] = svds(P.AX,this.z);
      [~,D,V] = svd(P.AX,'econ');
      this.C = D*V';
      
      this.compressEnergy(D);
      
    end
    
  end
  
end

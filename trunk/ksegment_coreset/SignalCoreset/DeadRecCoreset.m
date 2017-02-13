classdef DeadRecCoreset < PointSampleCoreset
  
  properties
    
    Xs
    Ws
    
  end
  
  methods
    
    function this = DeadRecCoreset(P,tol)
      
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
      
      % construct the coreset
      [this.Xs,this.sample_idx] = DeadRec(P.X,P.T,tol);
      
      %   this.sample_idx = sort(unique([this.sample_idx this.t2]));
      %   if length(this.sample_idx) > size(this.Xs,1)
      %     this.Xs = [this.Xs; P.X(end,:)];
      %   end
      this.sample_idx(end) = this.t2;
      
      % force to be column vector
      if isrow(this.Xs)
        this.Xs = this.Xs';
      end
      
      this.X = interp1(this.T(this.sample_idx),this.Xs,this.T);
      
      this.m = length(this.sample_idx);
      
    end
    
  end
  
end


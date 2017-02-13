classdef SourceKSegmentQuery < handle
  
  properties
    
    L
    X
    T
    endpoints
    splitpoints
    
  end
  
  %% methods
  methods
    
    function this = SourceKSegmentQuery(T,L,endpoints)
      
      this.T = T;
      this.L = L;
      this.endpoints = endpoints;
      this.splitpoints = endpoints(2:end,1);
      
      this.X = [];
      for i = 1:length(L)
        this.X = cat(1,this.X,SignalPointSet.LineSegmentPoints(L{i},this.endpoints(i,1):this.endpoints(i,2)));
      end
      
    end
    
    function plot(this,varargin)
      SignalPointSet(this.X,this.T).plot(varargin{:});
    end
    
  end
  
end

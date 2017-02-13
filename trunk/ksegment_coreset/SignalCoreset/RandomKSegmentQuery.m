classdef RandomKSegmentQuery < handle
  
  properties
    
    L
    X
    T
    endpoints
    splitpoints
    
  end
  
  %% methods
  methods
    
    function this = RandomKSegmentQuery(T,d,k)
      
      this.T = T;
      [this.X,this.L,this.endpoints] = generate_ksegment_points(T,d,k);
      
      this.splitpoints = this.endpoints(2:end,1);
      
      this.X = [];
      for i = 1:length(this.L)
        this.X = cat(1,this.X,SignalPointSet.LineSegmentPoints(this.L{i},this.endpoints(i,1):this.endpoints(i,2)));
      end
      
    end
    
    function plot(this,varargin)
      
      SignalPointSet(this.X,this.T).plot(varargin{:});
      
    end
    
  end
  
end

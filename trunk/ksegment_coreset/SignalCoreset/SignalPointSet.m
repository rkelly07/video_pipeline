classdef SignalPointSet < PointFunctionSet
  %SignalPointSet Summary of this class goes here
  %   Detailed explanation goes here
  
  %% properties
  properties (SetAccess = protected)
    
    X      % signal data
    T      % time
    d       % dimension of R^d
    t1     % start time
    t2     % end time
    AX     % Vandermonde projection of X
    
  end
  
  %% methods
  methods
    
    % SignalPointSet constructor
    % Input: 
    %   X = data [nxd] 
    %   T = time [nx1]
    function this = SignalPointSet(X,T)
      try
        T = T(:);
        assert(size(X,1)==size(T,1))
        this.M = Matrix(X);
        this.T = T;
        this.AX = [this.T ones(this.n,1) this.X];
      catch e
        error(e.identifier,e.message)
      end
    end
    
    function d = get.d(this)
      d = this.M.d;
    end
    
    function X = get.X(this)
      X = this.M.m;
    end
    
    function T = get.T(this)
      T = this.T;
    end
    
    function t1 = get.t1(this)
      t1 = min(this.T);
    end
    
    function t2 = get.t2(this)
      t2 = max(this.T);
    end
    
    function AX = get.AX(this)
      AX = this.AX;
    end
    
    % copy object
    function new = copy(this)
      try
        new = SignalPointSet(this.X,this.T);
      catch e
        error(e.identifier,e.message);
      end
    end
    
    % subset of this indexed by ind
    function new = subset(this,ind)
      try
        new = SignalPointSet(this.X(ind,:),this.T(ind));
      catch e
        error(e.identifier,e.message);
      end
    end
    
    % subset of this indexed by time
    function new = slice(this,time_ind)
      try
        [~,ind] = ismember(time_ind,this.T);
        ind = ind(ind>0);
        new = SignalPointSet(this.X(ind,:),this.T(ind));
      catch e
        error(e.identifier,e.message);
      end
    end
    
    % merge this signal with P
    function this = merge(this,P)
      try
        assert(this.d == P.d)
        new_X = [this.X; P.X];
        new_T = [this.T; P.T];
        this = SignalPointSet(new_X,new_T);
      catch e
        error(e.identifier,e.message)
      end
    end
    
    % get signal value at time t
    %   X returns the nxd signal data
    %   X(t) returns the 1xd vector of the signal data at time t
    %   X(t,i) returns the value of the ith dimension of X(t)
    function X = Xt(this,varargin)
      
      if nargin == 1
        X = this.X;
        
      elseif nargin == 2
        t = varargin{1};
        try
          assert(t>=this.t1 && t<=this.t2)
          ind = (this.T==t);
          X = this.X(ind,:);
        catch e
          error(e.identifier,e.message)
        end
        
      elseif nargin == 3
        t = varargin{1};
        i = varargin{2};
        try
          assert(t>=this.t1 && t<=this.t2)
          assert(i>0 && i<=this.d)
          ind = (this.T==t);
          X = this.X(ind,i);
        catch e
          error(e.identifier,e.message)
        end
        
      else
        dbstack
        assert(false);
      end
      
    end
    
    % compute cost from query to coreset
    function cost = ComputeQueryCost(this,Q)
      
      cost = SignalPointSet.SumSquaredDistance(this.X,Q.X);
      
    end
    
    % plot signal
    % optional:
    %   PlotStyle:      [string]
    % params:
    %   PlotDim:        [double]
    %   LineWidth:      [double]
    %   Title:          [string]
    %   Legend:         'on' | 'off'
    %   Colormap:       [string]
    function plot(this,varargin)
      p = inputParser;
      p.addOptional('PlotStyle','',@(s)ischar(s)...
        &&not(strcmpi(s,'PlotDim'))...
        &&not(strcmpi(s,'LineWidth'))...
        &&not(strcmpi(s,'Title'))...
        &&not(strcmpi(s,'Legend'))...
        &&not(strcmpi(s,'Colormap')))
      p.addParamValue('PlotDim',this.d,@isnumeric)
      p.addParamValue('LineWidth',1,@isnumeric)
      p.addParamValue('Title','',@isstr)
      p.addParamValue('Legend','on',@(x) any(validatestring(x,{'on','off'})))
      p.addParamValue('Colormap','lines',@isstr)
      p.parse(varargin{:})
      
      plot_dim = min(this.d,p.Results.PlotDim);
      plot_style = p.Results.PlotStyle;
      line_width = p.Results.LineWidth;
      title_str = p.Results.Title;
      legend_on = strcmpi(p.Results.Legend,'on');
      legend_str = {};
      
      % initialize to get correct dimension
      % then assign colormap
      colormap(lines(plot_dim));
      cmap = colormap(p.Results.Colormap);
      
      % plot
      hold on
      for i = 1:plot_dim
        if this.d == 1
          Xi = this.X;
        else
          Xi = this.X(:,i);
        end
        if ~isempty(plot_style)
          plot(this.T,Xi,plot_style,'LineWidth',line_width)
        else
          plot(this.T,Xi,'LineWidth',line_width,'Color',cmap(i,:))
        end
        legend_str = cat(1,legend_str,['X' num2str(i)]);
      end
      set(gca,'XGrid','on')
      if legend_on
        legend(legend_str)
      end
      title(title_str)
      hold off
      
    end
    
  end
  
  %% static methods
  methods (Static = true)
       
    % squared distance from P1 to P2
    function dist = SumSquaredDistance(P1,P2)
      assert(all(size(P1)==size(P2)))
      sqdist = @(X,Y)(X-Y)*(X-Y)';
      dist = sqdist(P1(:)',P2(:)');
    end
    
    % compute line segment points
    function X = LineSegmentPoints(L,T)
      d = size(L,2);
      n = length(T);
      X = repmat(L(1,:),n,1).*repmat(T(:),1,d)+repmat(L(2,:),n,1);
    end
    
    % compute segment linear cost
    function cost = LinearSegmentCost(P)

      A = P.AX(:,1:2);
      B = P.AX(:,3:end);
      
      %L = pinv(A'*A)*A'*B
      L = A\B;
      
      cost = sum(sum((A*L-B).^2));
      cost(cost<1e4*eps) = 0;
      
    end
    
    % compute segment linear cost
    function cost = LinearSegmentSubsetCost(P,ind)

      A = P.AX(ind,1:2);
      B = P.AX(ind,3:end);
      
      %L = pinv(A'*A)*A'*B
      L = A\B;
      
      cost = sum(sum((A*L-B).^2));
      cost(cost<1e4*eps) = 0;
      
    end 
    
  end
  
end


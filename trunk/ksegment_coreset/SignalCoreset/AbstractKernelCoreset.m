classdef AbstractKernelCoreset < handle
  %AbstractKernelCoreset Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (SetAccess = protected)
    
    d       % dimension R^d
    n       % num represented points
    t1      % signal start time
    t2      % signal end time
    C       % coreset
    L       % opt line
    cost    % opt line cost
    
  end
  
  %% class interface
  methods (Abstract, Access = protected)
    
    % compute coreset
    this = computeCoreset(this,coreset_alg,varargin)
    
  end
  
  %% methods
  methods
    
    % copy coreset
    function new = copy(this)
      
      % polymorphic construction
      new = feval(class(this));
      
      new.d = this.d;
      new.n = this.n;
      new.t1 = this.t1;
      new.t2 = this.t2;
      new.C = this.C;
      new.L = this.L;
      new.cost = this.cost;
      
    end
    
    % join coresets
    function new = join(this,other)
      
      % copy original coreset
      new = this.copy();
      
      new.n = new.n+other.n;
      new.t1 = min(new.t1,other.t1);
      new.t2 = max(new.t2,other.t2);
      
      % concatenate the kernels
      new.C = cat(1,new.C,other.C);
 
      % do not recompute SVD
      % do not compute opt line
      
    end
    
    function recomputeOptLine(this)
      this.computeOptLine();
    end
    
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
      colormap(lines(plot_dim))
      cmap = colormap(p.Results.Colormap);
      
      % plot
      T = (this.t1:this.t2);
      X = SignalPointSet.LineSegmentPoints(this.L,T);
      hold on
      for i = 1:plot_dim
        if this.d == 1
          Xi = X;
        else
          Xi = X(:,i);
        end
        if ~isempty(plot_style)
          plot(T,Xi,plot_style,'LineWidth',line_width)
        else
          plot(T,Xi,'LineWidth',line_width,'Color',cmap(i,:))
        end
        legend_str = cat(1,legend_str,['S' num2str(i)]);
      end
      set(gca,'XGrid','on')
      if legend_on
        legend(legend_str)
      end
      title(title_str)
      hold off
      
    end
    
    % compute opt line
    function computeOptLine(this)
      
      A = this.C(:,1:2);
      B = this.C(:,3:end);
      
      %   % solve d systems of equations for Li(t) = ai*Xi + bi:
      %   L = zeros(2,this.d);
      %   for i = 1:this.d
      %     b = B(:,i);
      %     L(:,i) = pinv(A'*A)*A'*b;
      %   end
      
      this.L = pinv(A'*A)*A'*B;
      
      %   % slow point-wise distance
      %   for t = 1:this.n
      %     Pi = this.Xt(t);
      %     Li = L(1,:).*t+L(2,:);
      %     D(t) = sum((Pi-Li).^2);
      %   end
      %   cost = sum(D)
      %
      %   % fast point-wise distance
      %   Px = this.X;
      %   Lx = SignalPointSet.LineSegmentPoints(L,this.T);
      %   sqdist = @(X,Y)(X-Y)*(X-Y)';
      %   cost = sqdist(Px(:)',Lx(:)')
      
      % frobenius norm
      this.cost = norm(A*this.L-B,'fro')^2;
      this.cost(this.cost<1e4*eps) = 0;
      
    end
    
  end
  
end


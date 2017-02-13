classdef PointSampleCoreset < handle
  %PointSampleCoreset Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    
    X     % coreset points
    T     % time
    d     % dimension R^d
    n     % number of signal points represented
    t1    % start time
    t2    % end time
    
    m     % coreset size (number of samples)
    sample_idx
    
  end
  
  %% class interface
  methods (Abstract, Access = protected)
    
    % compute coreset
    this = computeCoreset(this,P,varargin)
    
  end
  
  %% methods
  methods
    
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
      for i = 1:plot_dim
        if this.d == 1
          Xi = this.X(this.sample_idx);
        else
          Xi = this.X(this.sample_idx,i);
        end
        plot(this.T(this.sample_idx),Xi,'+','Color',cmap(i,:))
      end
      set(gca,'XGrid','on')
      if legend_on
        legend(legend_str)
      end
      title(title_str)
      hold off
      
    end
    
  end
  
end


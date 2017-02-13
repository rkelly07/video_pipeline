classdef KSegmentCoreset < handle
  % KSegmentCoreset Summary of this class goes here
    % Detailed explanation goes here
  
  properties (SetAccess = protected)
    
    d     % dimension R^d
    n     % number of signal points represented
    m     % number of segments (slices)
    t1    % start time
    t2    % end time
    keypoint_segment_lookup % map for keypoint->segment lookup
    num_keypoints;
    segments     % cell array of segments
    
  end
  
  % % methods
  methods
    
    % constructor
    function this = KSegmentCoreset()
      this.n = 0;
      this.m = 0;
      this.flushCache();
            % this.keypoint_segment_lookup = containers.Map('KeyType','double','ValueType','double');
    end
    
    % copy
    function new = copy(this)
      
      new = KSegmentCoreset();
      new.d = this.d;
      new.n = this.n;
      new.m = this.m;
      new.t1 = this.t1;
      new.t2 = this.t2;
      new.segments = cell(length(this.segments),1);
      new.flushCache();
      
            % new.keypoint_segment_lookup = containers.Map('KeyType','double','ValueType','double');
      for i = 1:length(this.segments)
        new.segments{i} = this.segments{i}.copy();
      end
      
    end
    
    function flushCache(this)
      this.keypoint_segment_lookup = containers.Map('KeyType','double','ValueType','double');
      this.num_keypoints = -1;
    end
    
    % add segment
    function addSegment(this,S)
      
      this.d = S.d;
      this.n = this.n+S.n;
      this.m = this.m+1;
      if isempty(this.t1) && isempty(this.t2)
        this.t1 = S.t1;
        this.t2 = S.t2;
      else
        this.t1 = min(this.t1,S.t1);
        this.t2 = max(this.t2,S.t2);
      end
      this.flushCache();
            % this.keypoint_segment_lookup = containers.Map('KeyType','double','ValueType','double');
      new_segment = S.copy();
      this.segments = cat(1,this.segments,{new_segment});
      
    end
    
    % return new KSegmentCoreset composed of segments xa,...,xb
    function new = subset(this,xa,xb)
      
      new = KSegmentCoreset();
      for i = xa:xb
        new.addSegment(this.segments{i});
      end
      
    end
    
    function new = subset_ind(this,ind)
      
      new = KSegmentCoreset();
      for i = ind
        new.addSegment(this.segments{i});
      end
      
    end
    
    % concatenate two ksegment coresets
    function new = join(this,D)
      
      unsorted = this.copy();
      for i = 1:D.m
        unsorted.addSegment(D.segments{i});
      end
      
      [~,ind] = sort(unsorted.T12);
      sorted = KSegmentCoreset();
      for i = 1:length(unsorted.segments)
        sorted.addSegment(unsorted.segments{ind(i,1)});
      end
      this.flushCache();
            % this.keypoint_segment_lookup = containers.Map('KeyType','double','ValueType','double');
      
      new = sorted;
      
    end
    
    function mx = totalCoresetSize(this)
      mx = 0;
      for i = 1:this.m
        mx = mx+this.segments{i}.coresets('SVDSegmentCoreset').d0;
      end
    end
    
    % return segment times in a m*2 matrix
    function T12 = T12(this)
      T12 = cell2mat(cellfun(@(D)[D.t1 D.t2],this.segments,'UniformOutput',false));
    end
    
    function res = getMaxTimepoint(obj)
      res = 0;
      for i = 1:numel(obj.segments)
        res = res+obj.segments{i}.t2-obj.segments{i}.t1;
      end
    end
    
    function i = getSegmentForKeypoint(obj,idx)
      if obj.keypoint_segment_lookup.isKey(idx);
        i = obj.keypoint_segment_lookup(idx);
      else
        res = 0;
        for i = 1:numel(obj.segments)
          res = res+obj.segments{i}.getNumKeypoints();
          if (res>=idx)
            obj.keypoint_segment_lookup(idx) = i;
            return;
          end
        end
      end
    end
    
    function [t1,t2] = getTimeForKeypoint(obj,idx)
      i = obj.getSegmentForKeypoint(idx);
      t1 = obj.segments{i}.t1;
      t2 = obj.segments{i}.t2;
    end
    
    function res = getNumKeypoints(obj)
      if (obj.num_keypoints>=0)
        res = obj.num_keypoints;
      else
        res = 0;
        for i = 1:numel(obj.segments)
          res = res+obj.segments{i}.getNumKeypoints();
        end
        obj.num_keypoints = res;
      end
    end
    
    function [cost,L] = getOptLine(obj,n1,n2)
      if (n2>obj.getNumKeypoints() || n1>n2)
        L = nan(1);
        cost = inf;
      else
        A = [];
        kp1 = 0; %counting keypoints until now
        % t = obj.segments{1}.t1;
        % n2 = numel(obj.segments);%obj.getMaxKeypoint();
        % n1 = 1;
        max_segment = numel(obj.segments);
        for i = 1:max_segment
          % i = i+1;
          % if (i<n1)
           % continue;
          % end
          s_n1 = kp1+1;
          s_n2 = kp1+obj.segments{i}.getNumKeypoints();
          % for i = n1:n2
          fully_contained = (s_n1>=n1 && s_n2<=n2);
          % segment_full_time = obj.segments{i}.getMaxKeypoint();
          intersect_n1 = max(s_n1,n1);
          intersect_n2 = min(s_n2,n2);
          if (intersect_n1>intersect_n2)
            kp1 = s_n2;
            continue;
          end
          if (obj.segments{i}.coresets.isKey('SVDSegmentCoreset')) && (fully_contained)
            % t = t+segment_full_time;
            A = [A;obj.segments{i}.coresets('SVDSegmentCoreset').C];
          elseif (obj.segments{i}.coresets.isKey('TwoSegmentCoreset'))
            CS = obj.segments{i}.coresets('TwoSegmentCoreset');
            % need to transform from t to indices
            CS2 = CS.computeCoreset(1,intersect_n1-kp1,intersect_n2-kp1);
            t = CS2.idx(:);
            w = CS2.w(:);
            V = [ones(size(t)),t,CS2.samples];
            V2 = bsxfun(@times,w(:),V);
            A = [A;V2];
            % i = n2;
          else
            warning('No appropriate coreset found');
          end
          kp1 = s_n2;
        end
        if (isempty(A))
          cost = 0;
          L = 0;
        else
          A1 = A(:,1:2);
          A2 = A(:,3:end);
          L = A1\A2;
          cost = norm(A1*L-A2,'fro').^2;
        end
      end
    end
    
    % compute total cost by merging SVD coresets
    function cost = computeTotalCost(this)
      
      cost = 0;
      if this.m > 0
        
        % general version:
        % compute total cost by merging kernel coresets
        % this uses the base class merge function
        % it works for any AbstractKernelCoreset class
          % coresets = this.segments{1}.coresets.values();
          % for j = length(coresets)
            % if isa(coresets{j},'AbstractKernelCoreset')
              % C = coresets{j};
            % end
          % end
          % for i = 2:this.m
            % coresets = this.segments{i}.coresets.values();
            % for j = length(coresets)
              % if isa(coresets{j},'AbstractKernelCoreset')
                % C = C.merge(coresets{j});
              % end
            % end
          % end
        
        C = this.segments{1}.coresets('SVDSegmentCoreset');
        for i = 2:this.m
          C = C.join(this.segments{i}.coresets('SVDSegmentCoreset'));
        end
        C.recomputeOptLine()
        cost = C.cost;
        
      end
      
    end
    
    % compute cost from query to coreset
    function cost = ComputeQueryCost(this,Q)
      
      cost = zeros(1,this.m);
      for i = 1:this.m
        
        ta = this.segments{i}.t1;
        tb = this.segments{i}.t2;
        
        % check if segment crosses a split point
        if not(isempty(Q.splitpoints(Q.splitpoints>=ta & Q.splitpoints<tb)))
          
          % there is at least one split point in Q[ta:tb]
          % = > compute the cost to the line segment points
          Li = this.segments{i}.coresets('SVDSegmentCoreset').L;
          Xi = SignalPointSet.LineSegmentPoints(Li,ta:tb);
          Xj = Q.X(ta:tb,:);
          
          cost(i) = SignalPointSet.SumSquaredDistance(Xi,Xj);
          
        else
          
          % there no split point in Q[ta:tb]
          % = > compute the zero error cost to the SVD coreset
          Ci = this.segments{i}.coresets('SVDSegmentCoreset').C;
          A = Ci(:,1:2);
          B = Ci(:,3:end);
          j = find(ta>=Q.endpoints(:,1),1,'last');
          Lj = Q.L{j};
          
          % frobenius norm
          cost(i) = norm(A*Lj-B,'fro')^2;
          
        end
        
      end
      
      cost(cost<1e4*eps) = 0;
      cost = sum(cost);
      
    end
    
    % plot ksegment coreset
    % optional:
      % PlotStyle:      [string]
    % params:
      % PlotDim:        [double]
      % LineWidth:      [double]
      % Title:          [string]
      % Legend:         'on' | 'off'
      % Colormap:       [string]
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
      
      plot_dim = p.Results.PlotDim;
      plot_style = p.Results.PlotStyle;
      line_width = p.Results.LineWidth;
      title_str = p.Results.Title;
      legend_on = strcmpi(p.Results.Legend,'on');
      legend_str = {};
      colormap_str = p.Results.Colormap;
      
      % plot signal
      hold on
      xticks = zeros(1,this.m);
      if legend_on
        for i = 1:plot_dim
          legend_str = cat(1,legend_str,['X' num2str(i)]);
        end
      end
      for i = 1:this.m
        C = this.segments{i}.coresets('SVDSegmentCoreset');
        C.plot(plot_style,'PlotDim',plot_dim,'LineWidth',line_width,'Legend','off','Colormap',colormap_str)
        if legend_on && i == 1
          legend(legend_str)
        end
        xticks(i) = this.segments{i}.t1;
      end
      xticks = sort(unique(xticks));
      set(gca,'XTick',xticks)
      set(gca,'XTickLabel',num2str((1:length(xticks))'))
      set(gca,'XGrid','on')
      title(title_str)
      hold off
      
    end
    
  end
  
end


% ------------------------------------------------
% reformatted with stylefix.py on 2014/05/17 20:54

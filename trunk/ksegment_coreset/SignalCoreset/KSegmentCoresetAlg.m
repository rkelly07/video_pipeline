classdef KSegmentCoresetAlg < handle
  %KSegmentCoresetAlg Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    
    a   % number of partitions
    b   % bicriteria log base
    c   % error parameter O(eps)
    
    z  % dimensionality reduction parameter
    w  % energy threshold parameter
    
    verbose = true
    
  end
  
  %% methods
  methods
    
    function set.verbose(this,verbose)
      this.verbose = verbose;
      pdisp('','SetVerbose',verbose)
    end
    
    % compute bicriteria for SignalPointSet P
    function cost = computePointsBicriteria(this,P)
      pdisp(' Computing points bicriteria ...')
      
      cost = 0;
      iters = 0;
      
      % iteratively remove min cost subsets
      pdisp(['  ' num2str(P.n) ' points remaining'])
      while P.n > this.a
        
        costs = zeros(1,this.a);
        
        for i = 1:this.a
          
          % partition P into b subsets
          xa = ceil((i-1)*P.n/this.a)+1;
          xb = ceil(i*P.n/this.a);
          
          % calculate cost for each subset
          costs(i) = SignalPointSet.LinearSegmentSubsetCost(P,xa:xb);
          
        end
        
        % find the best cost subset
        [min_costs,i_min] = sort(costs);
        l = max(1,floor(this.a/this.b));
        i_min = i_min(1:l);
        min_cost = sum(min_costs(1:l));
        
        % remove the min cost subset
        remove_idx = [];
        for i = i_min
          xa = ceil((i-1)*P.n/this.a)+1;
          xb = ceil(i*P.n/this.a);
          remove_idx = cat(2,remove_idx,(xa:xb));
        end
        keep_idx = setdiff(1:P.n,remove_idx);
        P = P.subset(keep_idx);
        
        % add min cost to bicriteria cost
        cost = cost + min_cost;
        
        iters = iters+1;
        pdisp(['  ' num2str(P.n) ' points remaining'])
        
      end
      
      % base case
      cost = cost + SignalPointSet.LinearSegmentCost(P);
      
      pdisp([' Completed ' num2str(iters) ' iterations'])
      
    end
    
    % Compute coreset from signal points
    % Input:  SignalPointSet P
    % Output: KSegmentCoreset D
    function D = computeCoreset(this,P)
      pdisp('Computing k-segment coreset ...')
      
      % compute bicriteria cost
      bicriteria_cost = this.computePointsBicriteria(P);
      pdisp([' bicriteria cost = ' num2str(bicriteria_cost)])
      
      % divide into slices according to cost
      slice_cost = (this.c*bicriteria_cost)/(this.a);
      pdisp([' slice cost = ' num2str(slice_cost)])
      
      D = KSegmentCoreset();
      
      ta = P.t1;
      tb = ta;
      x = 1;
      
      % iterate until the last index reaches the size of the point set
      while tb < P.t2
        
        % first do binary search to find Q with cost(Q) < slice cost
        [~,ind] = ismember((ta:P.t2),P.T);
        ind = ind(ind>0);
        Q = P.subset(ind);
        cost = SignalPointSet.LinearSegmentCost(Q);
        while cost > slice_cost
          Q = Q.subset(1:ceil(Q.n/2));
          cost = SignalPointSet.LinearSegmentCost(Q);
        end
        tb = ta+Q.n-1;
        
        % then iterate from Q t get first subset with cost(Q) >= slice cost
        while tb < P.t2 && cost < slice_cost
          [~,ind] = ismember((ta:tb+1),P.T);
          ind = ind(ind>0);
          Q = P.subset(ind);
          cost = SignalPointSet.LinearSegmentCost(Q);
          tb = tb+1;
        end
        
        % if Q is a single point then then we are done
        % if not then find the correct subset from boundary conditions
        if not(Q.n == 1)
          % cost is now >= slice_cost
          % if cost == slice_cost then use Q
          % otherwise use previous subset
          if cost > slice_cost
            Q = Q.subset(1:Q.n-1);
            tb = tb-1;
          end
        end
        
        % construct segment
        S = CoresetSegment(ta,tb);
        C = SVDSegmentCoreset(Q,this.z,this.w);
        S.addCoreset(C);
        
        % add segment to ksegment coreset
        D.addSegment(S);        
        pdisp(['  mx = ' num2str(D.m) ': [' num2str(ta) ',' num2str(tb), '], ' ...
          'nx = ' num2str(S.n) ', d0 -> ' num2str(C.d0) ', cost = ' num2str(C.cost)])
        
        % update first index and repeat
        ta = tb+1;
        x = x+1;
        
      end
      
      % total cost
      total_cost = D.computeTotalCost();
      pdisp([' total cost = ' num2str(total_cost)])
      pdisp('Done!')
      
    end
    
    % compute bicriteria for KSegmentCoreset D
    function cost = computeKSegmentBicriteria(this,D)
      pdisp(' Computing ksegment bicriteria ...')
      
      cost = 0;
      iters = 0;
      
      % iteratively remove min cost subsets
      pdisp(['  ' num2str(D.m) ' segments remaining'])
      while D.m > this.a
        
        costs = zeros(1,this.a);
        
        for i = 1:this.a
          
          % find the subset time indices
          xa = ceil((i-1)*D.m/this.a)+1;
          xb = ceil(i*D.m/this.a);
          
          % compute residual subset
          Q = D.subset(xa,xb);
          
          % compute cost of each subset
          costs(i) = Q.computeTotalCost();
          
        end
        
        % find the best cost subset
        [min_costs,i_min] = sort(costs);
        l = max(1,floor(this.a/this.b));
        i_min = i_min(1:l);
        min_cost = sum(min_costs(1:l));
        
        % remove the min cost subset
        remove_idx = [];
        for i = i_min
          xa = ceil((i-1)*D.m/this.a)+1;
          xb = ceil(i*D.m/this.a);
          remove_idx = cat(2,remove_idx,(xa:xb));
        end
        keep_idx = setdiff(1:D.m,remove_idx);
        D = D.subset_ind(keep_idx);
        
        % add min cost to bicriteria cost
        cost = cost + min_cost;
        
        iters = iters+1;
        pdisp(['  ' num2str(D.m) ' segments remaining'])
        
      end
      
      % base case
      cost = cost + D.computeTotalCost();
      
      pdisp([' Completed ' num2str(iters) ' iterations'])
      
    end
    
    % Merge two KSegmentCoresets D1,D2 into a new one D.
    %   Input:    KSegmentCoresets D1,D2
    %   Output:   KSegmentCoreset D
    function D = mergedCoreset(this,D1,D2)
      pdisp('Merging coresets ...')
      pdisp([' [D1,D2]: [' num2str(D1.t1) ',' num2str(D1.t2) ' <-> ' num2str(D2.t1) ',' num2str(D2.t2) ']'])
      
      G = D1.join(D2);
      joint_cost = G.computeTotalCost();
      pdisp([' joint cost = ' num2str(joint_cost)])
      
      % compute bicriteria cost
      bicriteria_cost = this.computeKSegmentBicriteria(G);
      pdisp([' ksegment bicriteria cost = ' num2str(bicriteria_cost)])
      
      % divide into slices according to cost
      slice_cost = (this.c*bicriteria_cost)/(this.a);
      pdisp([' slice cost = ' num2str(slice_cost)])
      
      D = KSegmentCoreset();
      
      x = 1;
      
      % while there are segments remaining
      while x <= G.m
        
        % start time
        ta = G.segments{x}.t1;
        
        % check if more than one segment remaining
        if x < G.m
          
          Q0 = KSegmentCoreset();
          Q0.addSegment(G.segments{x});
          Q = Q0.copy();
          Q.addSegment(G.segments{x+1});
          cost = Q.computeTotalCost();
          
          % join coresets until cost > slice_cost
          while cost <= slice_cost && x+1 < G.m
            x = x+1;
            Q0 = Q.copy();
            Q.addSegment(G.segments{x+1});
            cost = Q.computeTotalCost();
          end
          
          % find the correct subset from boundary conditions
          % cost is now >= slice_cost
          % if cost1 == slice_cost, use Q
          % otherwise use previous subset
          if cost == slice_cost
            x = x+1;
          else
            Q = Q0;
          end
          
        else
          
          % xm was last segment
          Q = KSegmentCoreset();
          Q.addSegment(G.segments{x});
          
        end
        
        % end time
        tb = G.segments{x}.t2;
        
        % construct segment
        C = Q.segments{1}.coresets('SVDSegmentCoreset');
        for i = 2:Q.m
          C = C.join(Q.segments{i}.coresets('SVDSegmentCoreset'));
        end
        C.recomputeCoreset()
        S = CoresetSegment(ta,tb);
        S.addCoreset(C);
        
        % add segment to ksegment coreset
        D.addSegment(S);        
        pdisp(['  mx = ' num2str(D.m) ': [' num2str(ta) ',' num2str(tb), '], ' ...
          'nx = ' num2str(S.n) ', d0 -> ' num2str(C.d0) ', cost = ' num2str(C.cost)])
        
        x = x+1;
        
      end
      
      % total cost
      merged_cost = D.computeTotalCost();
      pdisp([' merged cost = ' num2str(merged_cost)])
      pdisp('Done!')
      
    end
    
    % compute residual subset of ksegment coreset
    %   Input:  D,ta,tb
    %   Output: Q = KSegmentCoreset
    function Q = residualSubset(~,D,ta,tb)
      
      Q = KSegmentCoreset();
      
      T12 = cell2mat(cellfun(@(D)[D.t1 D.t2],D.segments,'UniformOutput',false));
      
      % left residual
      r1_ind = find(T12(:,1)<ta & T12(:,2)>=ta);
      if ~isempty(r1_ind)
        C = D.segments{r1_ind}.coresets('CholeskySegmentCoreset');
        R = CholeskySegmentCoreset(C.L,ta,T12(r1_ind,2));
        S = CoresetSegment(ta,T12(r1_ind,2));
        S.addCoreset(R);
        Q.addSegment(S);
      end
      
      % complete segments
      subset_ind = find(T12(:,1)>=ta & T12(:,2)<=tb);
      for i = subset_ind'
        C = D.segments{r1_ind}.coresets('SVDSegmentCoreset');
        S = CoresetSegment(C.t1,C.t2);
        S.addCoreset(C);
        Q.addSegment(S);
      end
      
      % right residual
      r2_ind = setdiff(find(T12(:,1)<=tb & T12(:,2)>tb),r1_ind);
      if ~isempty(r2_ind)
        C = D.segments{r1_ind}.coresets('CholeskySegmentCoreset');
        R = CholeskySegmentCoreset(C.L,tb,T12(r2_ind,2));
        S = CoresetSegment(T12(r2_ind,1),tb);
        S.addCoreset(R);
        Q.addSegment(S);
      end
      
    end
    
  end
  
end


classdef TwoSegmentCoresetAlg < AbstractCoresetAlg
  % This class gets a dataset X, and EPS, as well as the start/end times it
  % pertains to, and returns a class that gives us the weights
  % (non-negative reals), and sampled data points
  % such that:
  % 1) The number of points saved is O(log (n)/\eps)
  % 2) the samples give an (1+epsilon) approximation to the function in the
  % sense that:
  % For every L in [n] = {1,..,n}
  % and every two real monotonic functions f:[1,..L]-->[0,..,inf) and
  % g: [L+1,..n]-->[0,inf) we have:
  % sum_{i = 1}^L f(i)+sum_{i = L+1}^n g(i) equals to
  % sum_{i = 1}^L w_i f(i)+sum_{i = L+1}^n w_i g(i)
  % up to a multiplicative error of 1 plus epilson.
  
  properties
    % nn
  end
  
  methods
    
    function res = getNumKeypoints(obj)
      res = numel(obj.ss);
    end

    function res = computeCoreset(obj,X,idx_start,idx_end,EPS)
      % n = obj.nn;
      n = idx_end-idx_start+1;
      is = 1:n;
      % B = [];vB = [];
      s = max(4./is,4./(n-is+1));
      t = sum(s);
      cms = cumsum(s);
      b = ceil(cms/(t*EPS)); % real numbers between 0 to s
      [~,B,J] = unique(b); % J is of size n and tells the bin index of each integer in b
      A = accumarray(J(:),b(:)); % sum_{i\in I_j} s_i in the tex file
      % cs.w = sparse(B,1,wVals);
      cs.t1 = idx_start;
      cs.t2 = idx_end;
      % the weight of a point is inverse to its sensitivity
      % cs.w = r./S;
      cs.wVals = (1./s(B))' .*A;

      cs.idx = B;
      cs.ts = idx_start-1+cs.idx;
      cs.samples = X(cs.idx,:);
      res = TwoSegmentCoreset(cs.t1,cs.t2,cs.ts,cs.wVals,cs.samples);
    end
    
  end % methods
  
end % class

% ------------------------------------------------
% reformatted with stylefix.py on 2014/06/10 11:34

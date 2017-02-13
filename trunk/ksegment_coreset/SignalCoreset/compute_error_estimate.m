% compute error estimate from costs to query
function [eps_avg,eps_std,eps_min,eps_max] = compute_error_estimate(cost_PQ,cost_DQ)

% error = abs(approx)/opt
E = abs(cost_PQ-cost_DQ)./cost_DQ;

% error(error<eps) = 0
% error(abs(approx)<eps & opt<eps) = 0
E(E<1e4*eps) = 0;
E(abs(cost_PQ-cost_DQ)<1e4*eps & cost_DQ<1e4*eps) = 0;

eps_avg = mean(E);
eps_std = std(E);
eps_min = min(E);
eps_max = max(E);

end

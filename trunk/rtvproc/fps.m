function [idx,epsilon] = fps(D,N,idx,F)

if not(exist('F','var')) || isempty(F)
    F = zeros(size(D,1),1);
end

if not(exist('idx','var')) || isempty(idx)
    D2 = D+eye(length(D))*1d12;
    dscore = min(D2);
    [~,idx] = max(dscore(:)+F(:));
    F(idx) = -inf;
else
    idx = idx(:); % to ensure shape
end
d = min(D(idx,:),[],1); % d should always be the distance from each point to the set idx (closest point)

epsilon = [max(D(idx,:))]';
% if idx contains a single seed element, we have epsilon as the sampling radius.
% Otherwise the first values of epsilon contain their maximal distance to other points
for k = 1:N-1,
    [m,i] = max(d(:)+F(:));
    F(i) = -inf;
    d = min([d; D(i,:)],[],1);
    idx = [idx; i];
    epsilon = [epsilon; m];
end

% ------------------------------------------------
% reformatted with stylefix.py on 2014/09/22 15:58

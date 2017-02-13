function [Xs,sample_idx] = DeadRec(X,T,tol)

% figure(34), clf, hold on
% cmap = colormap(lines(size(X,2)));
% for k = 1:size(X,2)
%   plot(T,X(:,k),'color',cmap(k,:)) % plot original trace
% end

% store first point
currLine = 1;
Xs(currLine,:) = X(1,:);
sample_idx(currLine) = 1;

% initial ray
p1 = X(1,:);
p2 = X(2,:);
t1 = T(1);
t2 = T(2);

for i = 3:size(X,1)
  
  px = X(i,:);
  ti = T(i);
  
  delta_t1 = t2 - t1;
  delta_t2 = ti - t1;
  s = ((delta_t2-delta_t1)/delta_t1); % time ratio
  dx = p2 - p1; % find direction
  predX = p2 + dx*s; % project original line to the end of the line
  
%   for k = 1:size(X,2)
%     % plot p1-p2 trajectory
%     plot([t1 t2],[p1(k) p2(k)],'--s','LineWidth',2,'MarkerEdgeColor','k','MarkerFaceColor',cmap(k,:),'MarkerSize',10,'color',cmap(k,:))
%     % plot p2-pi (actual curr point)
%     plot([t2 ti],[p2(k) pi(k)],'--o','LineWidth',2,'MarkerEdgeColor','k','MarkerSize',20,'color',cmap(k,:))
%   end
  
  d = sqrt(sum((px-predX).^2));
  if (d > tol)
    % store point that violates tolerance
    currLine = currLine + 1;
    Xs(currLine,:) = px;
    sample_idx(currLine) = i;
    p1 = X(i-1,:); % previous point - to get current trajectory
    p2 = X(i,:);
    t1 = T(i-1);
    t2 = T(i);
  end
  
end

% add last point
if (sample_idx(end) < size(X,1))
  currLine = currLine + 1;
  Xs(currLine,:) = X(end,:);
  sample_idx(currLine) = size(X,1);
end

% for i = 2:length(sample_idx)
%   t1 = T(sample_idx(i-1));
%   t2 = T(sample_idx(i));
%   for k = 1:size(X,2)
%     plot([t1 t2],[Xs(i-1,k) Xs(i,k)],'k-')
%   end
% end

sample_idx = T(sample_idx)';

end


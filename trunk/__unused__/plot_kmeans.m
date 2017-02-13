% plot kmeans (using only first 2 dimensions)
function plot_kmeans(X,k,idx,ctrs,varargin)

% parse input
p = inputParser;
addParamValue(p,'Title','',@isstr)
addParamValue(p,'Legend','on',@(x) any(validatestring(x,{'on','off'})))
addParamValue(p,'Colormap','hsv',@isstr)
parse(p,varargin{:});

title_str = p.Results.Title;
legend_on = strcmpi(p.Results.Legend,'on');
colormap(lines(k));
cmap = colormap(p.Results.Colormap);

hold on

% marker size
if length(X) <= 1e3
  marker_size = 12;
elseif length(X) <= 1e6
  marker_size = 6;
else
  marker_size = 1;
end

% set title
if ~isempty(title_str)
  title(title_str)
end

% set legend
if legend_on
  legend_str = {};
  for i = 1:k
    % dummy plot for nice display
    plot(inf,inf,'.','Color',cmap(i,:),'MarkerSize',16)
    legend_str = cat(2,legend_str,['cluster ' num2str(i)]);
  end
  % dummy plot for nice display
  plot(inf,inf,'kx','MarkerSize',12,'LineWidth',3)
  legend_str = cat(2,legend_str,['centroids']);
  legend(legend_str,'Location','NW')
end

% plot points
for i = 1:k
  plot(X(idx==i,1),X(idx==i,2),'.','Color',cmap(i,:),'MarkerSize',marker_size)
end

% plot centroids
plot(ctrs(:,1),ctrs(:,2),'kx','MarkerSize',10,'LineWidth',2)
plot(ctrs(:,1),ctrs(:,2),'ko','MarkerSize',10,'LineWidth',2)

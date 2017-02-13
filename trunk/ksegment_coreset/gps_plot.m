

cmap = colormap(lines(D.m));

%%
T12 = D.T12;
figure(4002)
axis([37.6 37.85 -122.47 -122.37])
hold on
for i = 1:D.m
  %subplot(4,4,i)
  X1 = X(T12(i,1):T12(i,2),1)+min_X1{1};
  X2 = X(T12(i,1):T12(i,2),2)+min_X2{1};
  for j = 1:length(X1)
    plot(X1(j),X2(j),'.','LineWidth',2,'color',cmap(i,:))
    if j > 1
      plot(X1(j-1:j),X2(j-1:j),'LineWidth',2,'color',cmap(i,:))
    end
    pause(0.1)
  end
end
grid on

xlabel('Latitude (X1)','FontSize',16)
ylabel('Longitude (X2)','FontSize',16)

%%
figure(4001)
clf
hold on
plot(T,X(:,1),'k')
plot(T,X(:,2),'k')
plot(9999,9999,'ok-','LineWidth',1.5)
legend({'X1: Latitude (top)','X2: Longitude (bottom)','Dead Reckoning segmentation'})
for i = 1:D.m
  
  Ci = D.segments{i}.coresets('SVDSegmentCoreset');
  Ti = (Ci.t1:Ci.t2);
  %Xi = SignalPointSet.LineSegmentPoints(Ci.L,Ti);
  Xi = K.X(Ti,:);

  plot(Ti,Xi(:,1),'LineWidth',1.5,'color',cmap(i,:))
  plot(Ti,Xi(:,2),'LineWidth',1.5,'color',cmap(i,:))
  
  plot(Ti(1),Xi(1,1),'o','LineWidth',3,'color',cmap(min(i,D.m-1),:))
  %plot(Ti(end),Xi(end,1),'o','LineWidth',3,'color',cmap(i,:))
  plot(Ti(1),Xi(1,2),'o','LineWidth',3,'color',cmap(min(i,D.m-1),:))
  %plot(Ti(end),Xi(end,2),'o','LineWidth',3,'color',cmap(i,:))
  
  xticks(i) = D.segments{i}.t1;
  
end

xticks = sort(unique(xticks));
set(gca,'xtick',xticks)
set(gca,'xticklabel',[])
set(gca,'xgrid','on')
set(gca,'xlim',[min(T) max(T)])
set(gca,'ytick',[])

xlabel('Time','FontSize',16)
ylabel('Latitude (top), Longitude (bottom)','FontSize',16)

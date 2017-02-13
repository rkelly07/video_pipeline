figure(1000)
clf
subplot(211)
hold on

plot(min(T0),9999,'k-')
plot(min(T0),9999,'mo-','LineWidth',3)
plot(min(T0),9999,'g^','LineWidth',4)
plot(min(T0),9999,'rv','LineWidth',4)
legend({'MTGOXUSD D1 closing price','Dead Reckoning segmentation','Local price maxima','Local price minima'},'Location','NW','FontSize',16)

% plot coreset
T0_offset = min(T0)-1;
for i = 1:D.m
  Ci = D.segments{i}.coresets('SVDSegmentCoreset');
  Ti = (Ci.t1:Ci.t2+1);
  if i == D.m
    Ti = Ti(1:end-1);
  end
  %Xi = SignalPointSet.LineSegmentPoints(Ci.L,Ti);
  Xi = K.X(Ti,:);
  plot(Ti+T0_offset,Xi,'m','LineWidth',2)
  plot(Ti(1)+T0_offset,Xi(1),'mo','LineWidth',3)
  plot(Ti(end)+T0_offset,Xi(end),'mo','LineWidth',3)
  xticks(i) = D.segments{i}.t1+T0_offset;
end

% xticks = sort(unique(xticks));
% set(gca,'xtick',xticks)
% set(gca,'xgrid','on')
% set(gca,'xlim',[datenum('2012-12-01','yyyy-mm-dd') datenum('2014-05-01','yyyy-mm-dd')])
% datetick('x','yyyy-mm','keepticks','keeplimits')

% plot signal
plot(T0,Close,'k')
plot(T0([999 1232 1244 1270]),High([999 1232 1244 1270]),'g^','LineWidth',4)
plot(T0([1005 1240 1251 1316]),Low([1005 1240 1251 1316]),'rv','LineWidth',4)

datetick('x','mmm-yyyy')
set(gca,'xlim',[datenum('2013-03-01','yyyy-mm-dd') datenum('2014-03-01','yyyy-mm-dd')])
set(gca,'xgrid','on')

title('MTGOXUSD','FontSize',16)
xlabel('Date','FontSize',16)
ylabel('Price (USD/BTC)','FontSize',16)

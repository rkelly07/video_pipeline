load gps_errors_1-126
gps_errors1 = gps_errors;
load gps_errors_128-343
gps_errors2 = gps_errors;
load gps_errors_345-373
gps_errors3 = gps_errors;
load gps_errors_376-536
gps_errors4 = gps_errors;
clear gps_errors
for i = 1:536
  if i>=1 && i<=126
    gps_errors(i,:) = gps_errors1(i,:);
  elseif i>=128 && i<=343
    gps_errors(i,:) = gps_errors2(i,:);
    % elseif i>=345 && i<=373
    % gps_errors(i,:) = gps_errors3(i,:);
    % elseif i>=376 && i<=536
    % gps_errors(i,:) = gps_errors4(i,:);
  end
end
gps_errors = [gps_errors1(1:126,:); gps_errors2(128:343,:)]%; gps_errors3(345:373,:); gps_errors4(376:536,:)];

figure(9999)
clf, hold on

num_taxis_plot = 50;

cmap = colormap(lines(7));
for i = [1,2,3,4,6]
  
  XX = gps_errors(:,i);
  XE = cell2mat(XX(1:num_taxis_plot));
  plot(9999,9999,'LineWidth',4,'color',cmap(i,:))
  
end

legend({'k-segment coreset (mean and std)','Uniform sample coreset','Random sample coreset','RDP on points','Dead Reckoning on points'},'FontSize',16)
set(gca,'xlim',[0 num_taxis_plot+1])
set(gca,'ylim',[-0.01 0.2])

for i = [1,2,3,4,6]
  
  XX = gps_errors(:,i);
  XE = cell2mat(XX(1:num_taxis_plot));
  
  if i == 1
    errorbar(1:size(XE,1),XE(:,1),XE(:,2),'x','color',cmap(i,:))
    plot(1:size(XE,1),XE(:,1),'LineWidth',2,'color',cmap(i,:))
  else
    plot(1:size(XE,1),XE(:,1),'LineWidth',1,'color',cmap(i,:))
  end
  
end


xlabel('Taxi ID','FontSize',16)
ylabel('coreset error','FontSize',16)


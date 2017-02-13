% myclear, close all, clc
figure(1), clf
hold on

X1 = [0.05 0.05 0.02];
X2 = 1;

% load coreset_pr50x
% P(1,:) = precision;
% R(1,:) = recall;
load coreset_pr100x
P(1,:) = [precision 0.015997];
R(1,:) = [recall 1];
load coreset_pr150x
P(2,:) = [precision 0.015997];
R(2,:) = [recall 1];
load coreset_pr200x
P(3,:) = [precision 0.015997];
R(3,:) = [recall 1];
% load coreset_pr300
% P(3,:) = precision;
% R(3,:) = recall;
% load coreset_pr400
% P(5,:) = precision;
% R(5,:) = recall;
cmap = lines(3);
for i = 1:3
  xind1 = find(R(i,:)>X1(i));
  xind2 = find(R(i,:)<=X2);
  ind = intersect(xind1,xind2);
  plot(R(i,ind),P(i,ind),'-','color',cmap(i,:),'LineWidth',4)
end

%%

% load uniform_pr50x
% P(1,:) = precision;
% R(1,:) = recall;
load uniform_pr100x
P(1,:) = [precision 0.015997];
R(1,:) = [recall 1];
load uniform_pr150x
P(2,:) = [precision 0.015997];
R(2,:) = [recall 1];
load uniform_pr200x
P(3,:) = [precision 0.015997];
R(3,:) = [recall 1];
% load uniform_pr300
% P(3,:) = precision;
% R(3,:) = recall;
% load uniform_pr400
% P(5,:) = precision;
% R(5,:) = recall;
for i = 1:3
  xind1 = find(R(i,:)>X1(i));
  xind2 = find(R(i,:)<=X2);
  ind = intersect(xind1,xind2);
  plot(R(i,ind),P(i,ind),'--','color',cmap(i,:),'LineWidth',2)
end

xlabel('Recall','FontSize',16)
ylabel('Precision','FontSize',16)

set(gca,'ygrid','on')
axis([0 0.8 0 0.7])
line([0 1],[0.015997 0.015997],'LineWidth',2,'Color','black')

legend({'L = 100 (coreset)','L = 150 (coreset)','L = 200 (coreset)','L* = 100 (uniform)','L* = 150 (uniform)','L* = 200 (uniform)','Ground-truth baseline'},'FontSize',16)


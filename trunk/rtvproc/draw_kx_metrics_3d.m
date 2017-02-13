function draw_keyframe_metrics_3d(Kx_sel_idx,D,w,M,f,subplot_idx1,subplot_idx2)

num_candidate_frames = length(f);
num_metrics = length(w);

%% ------------------------------------------------------------------------------------------------
clf
hold on
Dx = D;
% for i = 1:num_candidate_frames
%     for j = 1:num_candidate_frames
%         if i < j
%             Dx(i,j) = nan;
%         end
%     end
% end
if num_candidate_frames > 1
    surf(Dx)
    plot3([1 1],[1 2],Dx(1:2,1),'k')
end
% stem3(1:num_candidate_frames,1:num_candidate_frames,Dx,'k')
plot3(1:num_candidate_frames,1:num_candidate_frames,zeros(1,num_candidate_frames),'k')
colormap(summer)
% view([-15 75])
view([-25 75])
axis([0 num_candidate_frames+1 0 num_candidate_frames+1])
set(gca,'xtick',1:num_candidate_frames)
set(gca,'ytick',1:num_candidate_frames)
kx_colors = lines(num_metrics);
for i = 1:num_metrics
    fi = w(i).*M(i,:);
    plot3(num_candidate_frames*ones(1,num_candidate_frames),1:num_candidate_frames,fi,'x-','color',kx_colors(i,:),'LineWidth',1)
end
plot3(num_candidate_frames*ones(1,num_candidate_frames),1:num_candidate_frames,f,'bo-','LineWidth',2)
stem3(num_candidate_frames*ones(1,num_candidate_frames),1:num_candidate_frames,f,'b-','LineWidth',2)
% plot3(num_candidate_frames*ones(1,length(Kx_sel_idx)),Kx_sel_idx,f(Kx_sel_idx),'^k','LineWidth',3,'MarkerSize',15)

% set(gca,'ZLim',[0 0.02])
% 
% i = 1;
% di = Dx(1,:);
% next_i = find((di+f)==max(di+f))
% plot3(i*ones(1,num_candidate_frames),1:num_candidate_frames,di+f,'bo-','LineWidth',2)
% plot3(i,next_i,di(next_i)+f(next_i),'^k','LineWidth',3,'MarkerSize',15,'MarkerFaceColor','k')
% set(gca,'ZLim',[0 0.02])
% 
% i = next_i;
% di = Dx(i,:);
% next_i = find((di+f)==max(di+f))
% plot3(i*ones(1,num_candidate_frames),1:num_candidate_frames,di+f,'bo-','LineWidth',2)
% plot3(i,next_i,di(next_i)+f(next_i),'^k','LineWidth',3,'MarkerSize',15,'MarkerFaceColor','k')
% set(gca,'ZLim',[0 0.02])
% 
% i = next_i;
% di = Dx(i,:);
% next_i = find((di+f)==max(di+f))
% plot3(i*ones(1,num_candidate_frames),1:num_candidate_frames,di+f,'bo-','LineWidth',2)
% plot3(i,next_i,di(next_i)+f(next_i),'^k','LineWidth',3,'MarkerSize',15,'MarkerFaceColor','k')

return


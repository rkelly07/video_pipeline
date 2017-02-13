function draw_keyframe_metrics_3d(Kx_sel_idx,D,w,M,f,subplot_idx1,subplot_idx2)

num_candidate_frames = length(f);
num_metrics = length(w);

%% ------------------------------------------------------------------------------------------------
h_axis = subplot(subplot_idx3);
title('Distance matrix D and relevance score f','FontSize',16)
cla(h_axis)
hold on
Dx = D;
for i = 1:num_candidate_frames
    for j = 1:num_candidate_frames
        if i < j
            Dx(i,j) = nan;
        end
    end
end
if num_candidate_frames > 1
    surf(Dx)
    plot3([1 1],[1 2],Dx(1:2,1),'k')
end
stem3(1:num_candidate_frames,1:num_candidate_frames,Dx,'k')
plot3(1:num_candidate_frames,1:num_candidate_frames,zeros(1,num_candidate_frames),'k')
view([-15 75])
axis([0 num_candidate_frames+0.99 0 num_candidate_frames+0.99])
set(gca,'xtick',1:num_candidate_frames)
set(gca,'ytick',1:num_candidate_frames)
kx_colors = lines(num_metrics);
for i = 1:num_metrics
    fi = w(i).*M(i,:);
    plot3(1:18,ones(1,18)-3,fi,'x-','color',kx_colors(i,:),'linewidth',1)
end
plot3(1:18,ones(1,18)-3,f,'k-','linewidth',2)
stem3(1:18,ones(1,18)-3,f,'k-','linewidth',2)
plot3(Kx_sel_idx,ones(1,length(Kx_sel_idx)),f(Kx_sel_idx),'ok','linewidth',4)

return


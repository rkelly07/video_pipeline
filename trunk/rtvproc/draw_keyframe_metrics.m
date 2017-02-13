function draw_keyframe_metrics(Kx_sel_idx,D,w,M,f,subplot_idx1,subplot_idx2)

num_candidate_frames = length(f);
num_metrics = length(w);

%% ------------------------------------------------------------------------------------------------
h_axis = subplot(subplot_idx1);
title('Distance matrix D','FontSize',16)
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
    plot3([num_candidate_frames-1 num_candidate_frames],[num_candidate_frames num_candidate_frames],Dx(end,end-1:end),'k')
    plot3(1:num_candidate_frames,ones(1,num_candidate_frames),zeros(1,num_candidate_frames),'k')
    plot3(ones(1,num_candidate_frames)*num_candidate_frames,1:num_candidate_frames,zeros(1,num_candidate_frames),'k')
end
stem3(1:num_candidate_frames,1:num_candidate_frames,Dx,'k')
plot3(1:num_candidate_frames,1:num_candidate_frames,zeros(1,num_candidate_frames),'k')
view([0 90])
axis([0 num_candidate_frames+0.99 0 num_candidate_frames+0.99])
set(gca,'xtick',1:num_candidate_frames)
set(gca,'ytick',1:num_candidate_frames)
colormap(summer)

%% ------------------------------------------------------------------------------------------------
h_axis = subplot(subplot_idx2);
title('Relevance score f*','FontSize',16)
cla(h_axis)
hold on
kx_colors = lines(num_metrics);
% dummy plots for legend
for i = 1:num_metrics
    plot(-1,0,'x','color',kx_colors(i,:),'linewidth',2)
end
plot(f,'k-','linewidth',2)
legend_str = cellstr([[repmat('f',num_metrics,1) num2str((1:num_metrics)')]; 'f*']);
legend(legend_str,'FontSize',12)
for i = 1:num_metrics
    fi = w(i).*M(i,:);
    plot(fi,'x-','color',kx_colors(i,:),'linewidth',1)
end
plot(f,'k-','linewidth',2)
ylims = [0 1];
if not(all(isinf(f))) &&  max(f(not(isinf(f)))) > 0
    ylims = [0 max(f(not(isinf(f))))*1.2];
end
axis([0 num_candidate_frames+1 ylims]) %+ceil(num_candidate_frames/3)
set(gca,'xtick',1:num_candidate_frames)
plot(Kx_sel_idx,f(Kx_sel_idx),'ok','linewidth',4)

%%
return



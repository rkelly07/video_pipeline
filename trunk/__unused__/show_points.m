% imshow([I,tracklets.old_I],[]);;for i = 1:num_current_trackpoints;if (epi_scores(i)>2);continue;end;hold on;h1=plot([newcorners(i,1) tracklets.current_trackpoints(i2,1)+size(I,2)],[newcorners(i,2) tracklets.current_trackpoints(i2,2)],'r-');set([h1],'LineWidth',3);drawnow;pause(0.4);end

% close all;
% imshow([I,tracklets.old_I],[]);
% iidxss=find(valid_idx);
% for i = 1:numel(tracklets.track_indices);
% % for i = 31:34
%     if (epi_scores(iidxss(i))>2);continue;end;
%     i2=find(tracklets.old_indices==tracklets.track_indices(i));
%     if (isempty(i2)) continue;end; 
%     hold on;h1=plot([tracklets.current_trackpoints(i,1) tracklets.old_trackpoints(i2,1)+size(I,2)],[tracklets.current_trackpoints(i,2) tracklets.old_trackpoints(i2,2)],'r-');
%     set([h1],'LineWidth',3);drawnow;pause(0.3);
% end
%     

% close all;
% figure(1);
% subplot(111);
imshow([I,tracklets.old_I],[]);
% iidxss=find(valid_idx);
hold on;
for i = 1:numel(tracklets.track_indices);
% for i = 31:34
%     if (epi_scores(iidxss(i))>2);continue;end;
    i2=find(tracklets.old_indices==tracklets.track_indices(i));
%     i2=i;
    if (isempty(i2)) continue;end; 
    h1=plot([tracklets.current_trackpoints.Location(i,1) tracklets.old_trackpoints.Location(i2,1)+size(I,2)],[tracklets.current_trackpoints.Location(i,2) tracklets.old_trackpoints.Location(i2,2)],'r-');
    set([h1],'LineWidth',3);
    if (mod(i,1000)==0)
    drawnow;
    end
end
hold off    
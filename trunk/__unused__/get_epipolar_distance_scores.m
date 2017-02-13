function [epi_scores,F,dis]=get_epipolar_distance_scores(newcorners,oldcorners,options)
idx1=find(~isnan(newcorners(:,1))& ~isnan(oldcorners(:,1)));
idx2=idx1;
for i=1:3
try
[F,inlier_idx,status]= estimateFundamentalMatrix(newcorners(idx1,:),oldcorners(idx2,:),'Method','RANSAC','DistanceThreshold',options.tracker.epipolar_scale,'NumTrials',3000);
dis=compute_fundamental_matrix_distance(F',newcorners,oldcorners);
dis2=compute_fundamental_matrix_distance(F,oldcorners,newcorners);
dis=(dis+dis2)/2;
inlier_idx=dis<2;
if (status>0)
end
break;
catch
end
end
epi_scores=inf(size(newcorners(:,1)));
epi_scores(idx1(inlier_idx(:)))=0;
end
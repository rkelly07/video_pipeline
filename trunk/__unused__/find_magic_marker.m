function [res,template_info]=find_magic_marker(template_info,I,RANSAC_ATTEMPTS)
if (~isstruct(template_info))
    template=template_info;
    template_info=[];
    template_info.sig=3;
    template_info.template_hsv=rgb2hsv(template);
    template_info.template_v=template_info.template_hsv(:,:,3);
    template_info.P = detectSURFFeatures(template_info.template_v,'NumOctaves',4,'MetricThreshold',500);
    template_info.P=suppressNonMaximas(template_info.P,10);
    [template_info.F,template_info.P] = extractFeatures(template_info.template_v,template_info.P);
    template_info.I=template;
    template_info.If=template_info.I;
    template_info.flt=fspecial('Gaussian',ceil(template_info.sig)*4+1,template_info.sig);
    template_info.flt=sum(template_info.flt)/sum(template_info.flt);
    template_info.If=imfilter(template_info.If,template_info.flt,'replicate');
    template_info.If=imfilter(template_info.If,template_info.flt','replicate');
    for c=1:size(template_info.I,3)
        v=double(template_info.If(:,:,c));
    template_info.In(:,:,c)=(v-mean(v(:)))/std(v(:));
    end

end
res=[];
res.score=-inf;
thresh=30; % pixels threshold
min_thresh=0.95;
I_hsv=rgb2hsv(I);
I_v=I_hsv(:,:,3);
% I_v=double(I_v)/255;
if (RANSAC_ATTEMPTS>0)
P = detectSURFFeatures(I_v,'MetricThreshold',500,'NumOctaves',4);
P = suppressNonMaximas(P,10);
[F,P] = extractFeatures(I_v,P);
[idx_pairs,match_metric]= matchFeatures(template_info.F,F,'MatchThreshold',10); %#ok
% RANSAC_ATTEMPTS=1e2;
[X,Y]=meshgrid(1:size(template_info.I,2),1:size(template_info.I,1));
end
% Ic=[];
% for c=1:size(I,3)
%     Ic(:,:,c)=interp2(I(:,:,c),X,Y);
% end
maxscore=-inf;
for attempt=1:RANSAC_ATTEMPTS
    if (mod(attempt,ceil(RANSAC_ATTEMPTS/100))==0)
        fprintf('.');
    end
    % [fRANSAC,inliers] = estimateFundamentalMatrix(matched_pts1,matched_pts2,'Method', 'MSAC', 'NumTrials', 3000, 'DistanceThreshold', options.tracker.distance_threshold);%#ok
    pairs_idxs=randperm(size(idx_pairs,1));
%     pairs_idxs=pairs_idxs(1:3);
    pairs_idxs=pairs_idxs(1:4);
    pairs_idxs=idx_pairs(pairs_idxs,:);
    try
        warning off
    TFORM = cp2tform(double(P.Location(pairs_idxs(:,2),:)), double(template_info.P.Location(pairs_idxs(:,1),:)),'projective');
%     TFORM = cp2tform(double(P.Location(pairs_idxs(:,2),:)), double(template_info.P.Location(pairs_idxs(:,1),:)),'affine');
    warning on
    catch
        continue;
    end
    if (max(abs(det(TFORM.tdata.T)),abs(1/det(TFORM.tdata.T)))>400) || any(diag(TFORM.tdata.T(1:2,1:2))<0)|| cond(TFORM.tdata.T(1:2,1:2))>20
        continue;
    end
    Ximage=double(P.Location(idx_pairs(:,2),:));
    Yimage=double(template_info.P.Location(idx_pairs(:,1),:));
    [xm, ym] = tformfwd(TFORM, Ximage(:,1), Ximage(:,2));
    dist=sqrt(sum(([xm,ym]-Yimage).^2,2));
    outliers=dist>thresh;
    if (mean(outliers)>0.8)|| sum(~outliers)<6
        continue;
    end
    outliers2=dist>thresh/2;
    TFORM2 = cp2tform(Ximage(~outliers2,:), Yimage(~outliers2,:) ,'projective');
    Ic=imtransform(I,(TFORM2),'XData',[1 size(template_info.I,2)],'YData',[1 size(template_info.I,1)],'FillValues',nan);
%     Ic3=imtransform(I(:,:,1),(TFORM2),'XData',[1 size(template_info.I,2)],'YData',[1 size(template_info.I,1)],'FillValues',nan);
    Ic3=double(~isnan(Ic(:,:,1)));
    Ic(isnan(Ic))=0;
    valid_perc=sum(~isnan(Ic3(:)))/numel(Ic3);
    Ic=double(Ic);
    Ic2=[];
    for c=1:size(I,3)
    v=double(interp2(Ic(:,:,c),X,Y));
    Ic2(:,:,c)=(v-mean(v(:)))/std(v(:));
    end
    Ic2=imfilter(Ic2,template_info.flt,'replicate');
    Ic2=imfilter(Ic2,template_info.flt','replicate');
    score=(template_info.In(:)'*Ic2(:))/numel(Ic2(:));
    if (score>maxscore)
        maxscore=score;
        
%         tformpairs_idx(:,1)
        res.matches=idx_pairs(~outliers,:);
        res.tform=TFORM;
        res.score=score/max(0.8,valid_perc);
        res.valid_perc=valid_perc;
        res.X=Ximage(~outliers2,:);
        res.Y=Yimage(~outliers2,:);
        res.Ic2=Ic2;
        if (score>min_thresh)
            break;
        end
    end
    
end
end
function validated=validate_ncc_backwards(I1,I2,x1,x2,options)
validated=true(size(x1(:,1)));
[dX,dY]=meshgrid(-options.tracker.template_scale:options.tracker.template_scale);
newcorners=[];
num_current_trackpoints=size(x1,1);
for i = 1:num_current_trackpoints
    x1_=x1(i,1);y1_=x1(i,2);
    X1=x2(i,1)+dX;Y1=x2(i,2)+dY;
    template=[];
    for d=1:size(I1,3)
        template(:,:,d)=interp2(I2(:,:,d),X1,Y1);
    end
    templates{i}=template;
    X1=x1(i,1)+(-options.tracker.search_window_scale:options.tracker.search_window_scale);
    Y1=x1(i,2)+(-options.tracker.search_window_scale:options.tracker.search_window_scale);
    % %                 if (min(X1(:))<1 || min(Y1(:))<1||max(X1(:))>size(I,2)||max(Y1(:))>size(I,1))
    % %                     newcorners(i,:)=nan;
    % %                     continue;
    % %                 end
    %         search_window=I1(Y1,X1);
    search_window=[];
    INF=1e12;
    for d=1:size(I1,3);
        search_window(:,:,d)=interp2(I1(:,:,d),X1(:),Y1(:)','nearest',INF);
    end
    template=templates{i};
    score_img=0;
    for d=1:size(I1,3);
        score_img=score_img+normxcorr2(template(:,:,d),search_window(:,:,d));
    end
    [match_scores(i),ii]=max(score_img(:));
    match_scores(i)=match_scores(i)/3;
    [y2_,x2_]=ind2sub(size(score_img),ii);
    x1b(i,1)=x2_+x1_-options.tracker.search_window_scale-options.tracker.template_scale-1;
    x1b(i,2)=y2_+y1_-options.tracker.search_window_scale-options.tracker.template_scale-1;
%     newcorners(i,:)=x1b;
    
end
validated=validated & sum((x1b-x1).^2,2)<3;
end


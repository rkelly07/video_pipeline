close all
% overall number of points. More points - more even initial points in the
% view
N1=10000;
% points shown in the view
N2=100;
% points actually selection
N3=10;
%
WRITE_VIDEO=0;

X=randn(N1,2)*5;
X=X(X(:,1)>-10,:);
X=X(X(:,1)<10,:);
X=X(X(:,2)>-10,:);
X=X(X(:,2)<10,:);

D=pdist2(X,X);
idx=fps(D,N2,1);
X=X(idx,:);
D=pdist2(X,X);
idxs{1}=fps(D,N3,1);
[xx,yy]=meshgrid(linspace(min(X(:)),max(X(:)),1000));
ff=(exp(-((xx+5).^2+(yy+5).^2)/400)+exp(-((xx-5).^2+(yy-5).^2)/400))*2000;
f=exp(-sum((X+5).^2,2)/200)*11+exp(-sum((X-5).^2,2)/200)*12;
idxs{2}=fps(D,N3,1,f);
for ii=1:2
    if (WRITE_VIDEO)
        filename=['FPS_example_',num2str(ii),'.avi'];
        writerObj = VideoWriter(filename);
        writerObj.FrameRate=10;
        open(writerObj);
    end
    %     hold off;
    figure;
    axes
    axis off
    idx=idxs{ii};
    cla
    H=1.1;
    plot3(X(:,1),X(:,2),X(:,2)*0+H,'k.');
%     
    set(gcf,'Color',[1 1 1]);
    axis off
    
    hold on;
        h=surf(xx,yy,ones(size(xx)),ff);
    if (ii==2)
        set(h,'AlphaData',0.5,'FaceAlpha',0.5)
    else
        set(h,'AlphaData',0,'FaceAlpha',0)
    end
    shading interp
    hold on;
    
    plot3(X(:,1),X(:,2),X(:,2)*0+H,'k.');
    hold off
    
    axis off
    campos([0 0 10 ]);
    drawnow;
    for i = 1:6
        hold on
        h=plot3(X(idx(i),1),X(idx(i),2),X(idx(i),2)*0+H,'ko');
        set(h,'MarkerFaceColor',[0 0 0]);
        if i == 1
            h=plot3(X(idx(i),1),X(idx(i),2),X(idx(i),2)*0+H,'bo','MarkerSize',20);
        end
        if i > 1
%             line([X(idx(i-1),1) X(idx(i),1)],[X(idx(i-1),2) X(idx(i),2)],'LineWidth',2,'Color','b')
            h2=mArrow3([X(idx(i-1),1),X(idx(i-1),2),X(idx(i-1),2)*0+H],[X(idx(i),1),X(idx(i),2),X(idx(i),2)*0+H]);
            set(h2,'FaceColor',[0 0 1]);
        end
        %     plot(X(idx(i),1),X(idx(i),2),'o');
        hold off
        drawnow;
        if (WRITE_VIDEO)
            frame = getframe;
            writeVideo(writerObj,frame);
        end
        pause(0.1);
    end
    if (WRITE_VIDEO)
        close(writerObj);
    end
end
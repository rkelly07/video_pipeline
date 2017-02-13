function video_writer = show_video_segmentation(video_stream,data,processed_idx,idx,filename,shift,end_frame)

figure(100)
if (exist('filename','var')==0)
  filename=[];
end

imwrite(data,jet(64),'temp.png','png');
rgb_data = ind2rgb(imread('temp.png'),jet(64));
rgb_data = rgb_data(:,1:end_frame,:);

step=1;

if (~isempty(filename))
  video_writer=VideoWriter(filename);
  video_writer.FrameRate=10;
  video_writer.open();
  % pos=get(gcf,'Position');pos(3)=1024;pos(4)=768;set(gcf,'Position',pos)
end
% figure;
didx=abs(imfilter(double(idx(:)'),[1 0 -1],'replicate'));
idx2=1+cumsum(max(didx,0));
stepsize=ceil(size(data,2)/100);
idx3=find(didx>0);

cmap0 = colormap;
cmap = colormap(hsv(10));
cmap = cmap(builtin('randperm',size(cmap,1)),:);
colormap(cmap0);
% dims = size(video_stream.get_frame(1));
cbar = ones(1,end_frame,3)*0;%204/255;
for frame = 1:end_frame
  cmap_ind = mod(idx(frame)-1,size(cmap,1))+1;
  cbar(1,frame,:) = cmap(cmap_ind,:);
  
end
B = zeros(100,size(cbar,2),size(cbar,3));
% warped_idx = ceil(end_frame*(1:dims(2))/dims(2));

for frame = 1:step:end_frame
  
  subplot(211)
  
  i2=processed_idx(frame);
  num_el=sum(idx2==idx2(frame));
  if (num_el<stepsize)
    title(['Segment #' num2str(idx(frame))],'FontName','Helvetica','FontSize',16)
    drawnow
    pause(0.5)
    continue
  end
  
  X = [rgb_data; ones(20,size(B,2),3)*204/255; B];
  image(X);
  hold on
  g = repmat(204/255,1,3);
  %   set(gca,'xcolor',g,'xtick',[])
  %   set(gca,'ycolor',g,'ytick',[])
  %   set(gcf,'color',g)
  %   set(gca,'box','off')
  axis off
  for j=1:numel(idx3)
    h=plot(idx3(j)*[1 1],[0 size(data,1)],'k-');
    set(h,'LineWidth',3);
  end
  h=plot(frame*[1 1],[0 size(data,1)],'y-');
  
  filled = frame/end_frame;
  filled_idx = 1:ceil(filled*end_frame);
  B(:,filled_idx,:) = repmat(cbar(1,filled_idx,:),[100 1 1]);
  
  set(h,'LineWidth',3);
  
  hold off
  video_stream.set_next_frame(i2+shift);
  I=video_stream.get_next_frame();
  
  title(['Segment #' num2str(idx(frame))],'FontName','Helvetica','FontSize',16)
  drawnow
  
  
  
  subplot(212)
  imshow(I,[])
  w = 10;
  cmap_ind = mod(idx(frame)-1,size(cmap,1))+1;
  rectangle('Position',[w w size(I,2)-w size(I,1)-w],'LineWidth',10,'EdgeColor',cmap(cmap_ind,:))
  
  %   subplot(3,1,3)
  %   if not(isempty(I))
  %     filled = i/end_frame;
  %     filled_idx = 1:ceil(filled*end_frame);
  %     B(1,filled_idx,:) = cbar(1,filled_idx,:);
  %
  % %     disp('------------------------')
  % %     cmap_ind = mod(idx(i)-1,size(cmap,1))+1
  % %     idx(i)
  %     image(B)
  %   end
  
  title(['Frame #' num2str(frame)],'FontName','Helvetica','FontSize',16)
  drawnow
  
  
  tic
  if (~isempty(filename))
    M = getframe(gcf);
    video_writer.writeVideo(M);
  else
      % keep constant frame rate
      pause(0.5-toc)
  end
  

end
if (~isempty(filename))
  video_writer.close();
end

% vrand=randperm(max(idx2));
% stepsize=ceil(size(data,2)/100);
% plot(medfilt1(vrand(idx2)',stepsize));
% axis([0 numel(idx),0,max(vrand)])
% subplot(10,1,1:9);
% image(data);
% axis off
% for idx_s=unique(idx2);
%     num_el=sum(idx2==idx_s);
%     mean_el=round(mean(find(idx2==idx_s)));
%     if (num_el<stepsize)
%         continue;
%     end
%     axes('position',[0.12+mean_el/size(data,2)*0.78,0.2,0.04,0.04]);axis off
%     imshow(I,[]);
% end

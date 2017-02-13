% [h,labels]=create_segmentation_figure(video_stream,ts,processed_idx,data)
% ts - the segmentation times, in coordinates in data
% processed_idx - the map from data points to frames in the video stream
function [h,labs]=create_segmentation_figure(video_stream,ts,processed_idx,data)
data2=(data-quantile(data(:),0.1))/(quantile(data(:),0.9)-quantile(data(:),0.1));
data2=max(0,min(1,data2))*60;
close all;image(data2)
labs=zeros(size(data2(1,:)));
min_interval=quantile(ts(2:end)-ts(1:(end-1)),0.6)/size(data,2);
for i = 1:numel(ts);
    try
        x=ts(i);labs(round(x))=1;hold on;h=plot(x*[1 1],[1 size(data2,1)],'k-');set(h,'LineWidth',3);hold off;
    catch
    end
end
axs=axis;

dx=axs(2)-axs(1);
dy=axs(4)-axs(3);
axs=axis;axs(4)=axs(4)*1.6;axis(axs);
MIN_SEGMENT_FOR_ICON=0.07*dx;
dxx=min(dy,dx);
img_sz=min_interval*2;
cnt=0;
% rectangle('Position',[dx*-0.01,dy*-0.01,dx*1.01,dy*1.01]);
prev_x=0;
for i = 1:(numel(ts)-1);
    try
        x=round((ts(i)+ts(i+1))/2);
        width=(ts(i+1)-ts(i))/(ts(end)-ts(1));
        if ((x-prev_x)>MIN_SEGMENT_FOR_ICON & x<(dx-MIN_SEGMENT_FOR_ICON))
            prev_x=x;
        I=video_stream.get_frame(processed_idx(x));
I=I(57:999,300:1070,:);        
        hold on;
% %         plot(x*[1;1],[dy*1.01,dy*1.3],'k-','LineWidth',2);
        arrow([x dy*1.01],[x dy*1.15],'Length',10,'TipAngle',10,'Width',1);
        imagesc(x+[-img_sz img_sz]*dx,1.4*dy+[-img_sz img_sz]*dy*4, I);
        rectangle('Position',[x-img_sz*dx, 1.4*dy-img_sz*dy*4,2*img_sz*dx,2*img_sz*dy*4]);
        hold off;
        cnt=cnt+1;
        end
        
    catch
    end
    
end

labs=cumsum(labs);
xlabel('Time frames')
ylabel('Visual words (projected unto low EV)')

end
function pts=view_multiview_datastream(data,video_streams,samples,t_start,t_end)
pts=[];
figure(1);
image(data);colormap jet
while(1)
    figure(1)
    drawnow;
    [coords,ycoords,button]=ginput(1);
    figure(2);
    if (isempty(coords)) || button>1
        return;
    end
    s=ceil(ycoords/size(data,1)*numel(video_streams));
    t=max(1,min(ceil(coords(1))));
    pts(end+1)=t;
%     frm=ceil(t_start(s)+samples(s,t)/size(samples,2)*(t_end(s)-t_start(s)));
    frm=ceil(samples(s,t));
    disp([num2str(s),':',num2str(frm)]);
try
    I=video_streams{s}.get_frame(uint32(frm));
catch
    disp(['frm =',num2str(frm)]);
end
imshow(I,[]);
    title([num2str(s),':',num2str(frm)]);
    drawnow;
end
end
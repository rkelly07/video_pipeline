function show_video_datastream(video_stream,data,processed_idx,idx)
figure;
subplot(10,1,10);
didx=(imfilter(double(idx(:)'),[1 0 -1],'replicate'));
idx2=1+cumsum(max(didx,0));
vrand=randperm(max(idx2));
stepsize=ceil(size(data,2)/100);
plot(medfilt1(vrand(idx2)',stepsize));
axis([0 numel(idx),0,max(vrand)])
subplot(10,1,1:9);
image(data);
axis off
for idx_s=unique(idx2);
    num_el=sum(idx2==idx_s);
    mean_el=round(mean(find(idx2==idx_s)));
    if (num_el<stepsize)
        continue;
    end
    axes('position',[0.12+mean_el/size(data,2)*0.78,0.2,0.04,0.04]);axis off
    video_stream.set_next_frame(processed_idx(mean_el));
    I=video_stream.get_next_frame();
    imshow(I,[]);
end
end
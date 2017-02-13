
num_frames = 400;
image_diff = zeros(num_frames,1);
hist_diff = zeros(num_frames,1);
Icurr = video_stream.get_frame(1);
for i = 2:num_frames
	Iprev = Icurr;
	Icurr = video_stream.get_frame(i);
	Gprev = double(rgb2gray(Iprev));
	Gcurr = double(rgb2gray(Icurr));
	Gcurr=Gcurr+median(Gprev(:)-Gcurr(:));
	image_diff(i,:) = norm(Gprev-Gcurr)/norm(Gcurr);
	hist_diff(i,:) = sum(abs(imhist(Gcurr)-imhist(Gprev)));
	figure(1)
	subplot(331), image(Iprev)
	subplot(332), image(Icurr)
	title(num2str(i))
	subplot(3,3,4:6)
	plot(image_diff,'r')
	subplot(3,3,7:9)
	plot(hist_diff)
end
function res=annotate_video_classification(video_filename,invalid_mask,step_size,features_function)
% create video stream
start_frame=1;
video_stream = VideoStream(video_filename,'StartFrame',start_frame);
oldI=0;
% read next frame
ind=0;
denom=0;
vs=[];l=[];
disp('Press = for positive, - for negative, 0 to avoid classification, any other key to quit');
while video_stream.IsActive
    for i = 1:step_size
    [I,curr_frame_idx] = video_stream.get_next_frame();
    end
    I=double(I)/255;
    ind=ind+abs(rgb2gray(I)<0.01);
    denom=denom+1;
    if (norm(I(:)-oldI(:))<100)
        continue;
    end
    warning('off','images:initSize:adjustingMag')
    imshow(I,[]);drawnow;
    warning('on','images:initSize:adjustingMag')
    v=features_function(I,invalid_mask);
%     v=1;
    waitforbuttonpress;
    k=get(gcf,'CurrentCharacter');
    if (k=='=')||(k=='+')
        vs(end+1,:)=v;
        l(end+1)=1;
    elseif (k=='-')
        vs(end+1,:)=v;
        l(end+1)=-1;
    elseif ~(k=='0')
        break;
    end
    oldI=I;
%     disp(k);
end
res.vs=vs;
res.l=l;

end
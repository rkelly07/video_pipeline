% image_url='http://images.opentopia.com/cams/9792/big.jpg';
% image_url='http://217.17.220.110/jpg/image.jpg';
%image_url='http://192.168.0.3/snapshot.cgi?user=user&pwd=user';
image_url='http://drlipcam.csail.mit.edu/snapshot.cgi?user=user&pwd=user';
image_url2='http://drlipcam2.csail.mit.edu/image/jpeg.cgi';
result_file=[];
MAX_FRAMES=3600*5*24;
cnt2=0;
file_cnt=0;
imgNo = 0;
% DATA_DIR_NAME='/data/vision/fisher/data1/rosman';
DATA_DIR_NAME='./';

% 'true' to save images, 'false' for avi
takeStills = false;
for cnt=1:MAX_FRAMES
    pause(0.2)
    cnt2=cnt2+1;
    if (cnt2>20000) || isempty(result_file)
        if (file_cnt>file_cnt_init)
            vid_obj.close();
            vid_obj2.close();
        end
        cnt2=0;
        file_cnt=file_cnt+1;
        result_file=[DATA_DIR_NAME,'webcam_',num2str(file_cnt),'.avi'];
        result_file2=[DATA_DIR_NAME,'webcam2_',num2str(file_cnt),'.avi'];
        vid_obj=VideoWriter(result_file,'Motion JPEG AVI');
        vid_obj.FrameRate=5;
        vid_obj.Quality=20;
        vid_obj.open();
        vid_obj2=VideoWriter(result_file2,'Motion JPEG AVI');
        vid_obj2.FrameRate=5;
        vid_obj2.Quality=20;
        vid_obj2.open();
        
        
    end
    tic
    img=imread(image_url);
    img2=imread(image_url2);
    
    toc
    try
    subplot(121);imshow(img,[]);
    subplot(122);imshow(img2,[]);
    drawnow;
    catch
    end
    if takeStills
      %vid_obj.writeVideo(img);
      %vid_obj2.writeVideo(img2);
      imgNo=imgNo+1;
      %imwrite(img,['data\picA' num2str(imgNo)], 'bmp');
      %imwrite(img2,['data\picB' num2str(imgNo) ], 'bmp');
      %pause;
    end
end
vid_obj.close();
vid_obj2.close();


INITIAL_VIDEO=400;DIM=300;
    N=2000;
    N2=2000;
t_start=[100;43;110];
t_finish=[2060;2000;7453];
data1=load('data/video1_results.mat');
data2=load('data/video2_results.mat');
data3=load('data/video3_results.mat');
clusters1={[240   363   501],[953        1047        1111],[1711        1770        1884]};
clusters2={[411   425   379],[517   472   514   546]};
clusters3={[   3704        3526        3329        3151],[1812        1687        1545        1812        1937],[5257        5364        5471],[6880        6916        6970]};
data1=compute_processed_bow(data1,INITIAL_VIDEO,DIM,clusters1);
data2=compute_processed_bow(data2,INITIAL_VIDEO,DIM,clusters2);
data3=compute_processed_bow(data3,INITIAL_VIDEO,DIM,clusters3);

    [video1_corrected,samples1]=correct_coordinates(data1.ts,t_start(1),t_finish(1),N);
    [video2_corrected,samples2]=correct_coordinates(data2.ts,t_start(2),t_finish(2),N);
    [video3_corrected,samples3]=correct_coordinates(data3.ts,t_start(3),t_finish(3),N);
    clusters1=[];clusters2=[];clusters3=[];
    data1.filled_bow=spline(data1.processed_frame_idx,data1.data2,samples1);
    data2.filled_bow=spline(data2.processed_frame_idx(1:size(data2.bags_of_words,1)),data2.data2,samples2);
    data3.filled_bow=spline(data3.processed_frame_idx(1:size(data3.bags_of_words,1)),data3.data2,samples3);
    ts=unique([video1_corrected,video2_corrected,video3_corrected]);
    
    labs=zeros(N,1);
    img=[data1.filled_bow/std(data1.filled_bow(:));data2.filled_bow/std(data2.filled_bow(:));data3.filled_bow/std(data3.filled_bow(:))]*1e2;
    map2=colormap('jet');
    map2=((map2)+2)/3;
    image(img);colormap(map2)
    LINE_WIDTH=1.5;
%     clr=eye(3);
    clr=zeros(3);
    vids={video1_corrected,video2_corrected,video3_corrected};
    for vid_i=1:numel(vids)
        vid=vids{vid_i};
for i = 1:numel(vid);try;x=vid(i);labs(round(x))=1;hold on;h=plot(x*[1 1],[1 size(img,1)],'-');set(h,'LineWidth',LINE_WIDTH,'Color',clr(vid_i,:));hold off;catch;end;end    
    end
sumy=0;
STREAM_WIDTH=5;
% clr2=zeros(3);
clr2=eye(3);
hold on;h=rectangle('Position',[0, sumy+STREAM_WIDTH/2,size(img,2),size(data1.data2,1)-STREAM_WIDTH]);hold off;set(h,'EdgeColor',clr2(1,:),'LineWidth',STREAM_WIDTH,'LineStyle','-.');sumy=sumy+size(data1.data2,1);
hold on;h=rectangle('Position',[0, sumy+STREAM_WIDTH/2,size(img,2),size(data2.data2,1)-STREAM_WIDTH]);hold off;set(h,'EdgeColor',clr2(2,:),'LineWidth',STREAM_WIDTH,'LineStyle','-.');sumy=sumy+size(data2.data2,1);
hold on;h=rectangle('Position',[0, sumy+STREAM_WIDTH/2,size(img,2),size(data3.data2,1)-STREAM_WIDTH]);hold off;set(h,'EdgeColor',clr2(3,:),'LineWidth',STREAM_WIDTH,'LineStyle','-.');sumy=sumy+size(data3.data2,1);

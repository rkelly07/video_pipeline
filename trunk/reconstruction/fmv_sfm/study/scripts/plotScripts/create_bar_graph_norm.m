function create_bar_graph_norm

% function to create a bar graph illustrating the processing times of reconstructions

clear all;
addpath '/data/study/stats';
stats = read_stats( 'stats__25-Apr-2014_16-58-30.txt');


gpu0_stats = stats( [stats.nGPU] == 0 );
gpu1_stats = stats( [stats.nGPU] == 1 );
gpu2_stats = stats( [stats.nGPU] == 2 );

plot_type  = 'norm_by_sparse_recon';  % norm, norm_by_mpix, norm_by_sparse_recon, norm_by_sparse_recon_inv


switch plot_type
    
    case 'norm'
         t_total0   = [gpu0_stats.t_sift] + [gpu0_stats.t_match] + [gpu0_stats.t_sparse];
         t_total1   = [gpu1_stats.t_sift] + [gpu1_stats.t_match] + [gpu1_stats.t_sparse];
         t_total2   = [gpu2_stats.t_sift] + [gpu2_stats.t_match] + [gpu2_stats.t_sparse];   

         title_str  = 'Normalized Relative Processing Time';
         ylabel_str = 'Fraction of Processing Time';
         ymax       = 1.5;

    case 'norm_by_mpix'
        res0      = [gpu0_stats.res];                                                       %#ok<*UNRCH>
        pixW_0    = res0(1:2:end);
        pixH_0    = res0(2:2:end);

        res1      = [gpu1_stats.res];
        pixW_1    = res1(1:2:end);
        pixH_1    = res1(2:2:end);

        res2      = [gpu2_stats.res];
        pixW_2    = res2(1:2:end);
        pixH_2    = res2(2:2:end);

        t_total0  = [gpu0_stats.nFrames].* pixW_0 .* pixH_0 * 1.e-6;  %[gpu0_stats.nFrames]; 
        t_total1  = [gpu1_stats.nFrames].* pixW_1 .* pixH_1 * 1.e-6;  %[gpu1_stats.nFrames];
        t_total2  = [gpu2_stats.nFrames].* pixW_2 .* pixH_2 * 1.e-6;  %[gpu2_stats.nFrames];   
        
        title_str  = 'Relative Processing Time';
        ylabel_str = 'Seconds Per MegaPixels';
        ymax       = 6;
        
    case 'norm_by_sparse_recon'
         t_total0   = [gpu0_stats.reconPts] * 1.e-2;
         t_total1   = [gpu1_stats.reconPts] * 1.e-2;
         t_total2   = [gpu2_stats.reconPts] * 1.e-2;   

         title_str  = 'Normalized Relative Processing Time';
         ylabel_str = 'Seconds Per Hundred Reconstructed Points';
         ymax       =  15;     
         
         
     case 'norm_by_sparse_recon_inv'
         t_total0   = [gpu0_stats.reconPts] * 1.e-3;
         t_total1   = [gpu1_stats.reconPts] * 1.e-3;
         t_total2   = [gpu2_stats.reconPts] * 1.e-3;   

         title_str  = 'Normalized Relative Processing Time';
         ylabel_str = 'Reconstructed Kilo-Points per Second';
         ymax       =  10;           
        
end



% Apply normalization
t_sift0 = [gpu0_stats.t_sift]./t_total0;       % sparse
t_sift1 = [gpu1_stats.t_sift]./t_total1;
t_sift2 = [gpu2_stats.t_sift]./t_total2;


t_match0 = [gpu0_stats.t_match]./t_total0;     % sparse
t_match1 = [gpu1_stats.t_match]./t_total1;
t_match2 = [gpu2_stats.t_match]./t_total2;


t_sparse0 = [gpu0_stats.t_sparse]./t_total0;   % sparse
t_sparse1 = [gpu1_stats.t_sparse]./t_total1;
t_sparse2 = [gpu2_stats.t_sparse]./t_total2;


switch plot_type
    case 'norm_by_sparse_recon_inv'
        t_sift0 = 1./t_sift0;         
        t_sift1 = 1./t_sift1;        
        t_sift2 = 1./t_sift2;   
        
        t_match0 = 1./t_match0;         
        t_match1 = 1./t_match1;        
        t_match2 = 1./t_match2;     
        
        t_sparse0 = 1./t_sparse0;         
        t_sparse1 = 1./t_sparse1;        
        t_sparse2 = 1./t_sparse2;            
end



% Sort collection times of input frame set (changed to minutes) for the x-axis
[~, tIdx_0] = sort( [gpu0_stats.nFrames]./[gpu0_stats.fRate] ./60 );
[~, tIdx_1] = sort( [gpu1_stats.nFrames]./[gpu1_stats.fRate] ./60 );
[~, tIdx_2] = sort( [gpu2_stats.nFrames]./[gpu2_stats.fRate] ./60 );


% Sort processing times by collection size
t_sift0_sort = t_sift0(tIdx_0);       % sparse
t_sift1_sort = t_sift1(tIdx_1);
t_sift2_sort = t_sift2(tIdx_2);

t_match0_sort = t_match0(tIdx_0);     % sparse
t_match1_sort = t_match1(tIdx_1);
t_match2_sort = t_match2(tIdx_2);

t_sparse0_sort = t_sparse0(tIdx_0);   % sparse
t_sparse1_sort = t_sparse1(tIdx_1);
t_sparse2_sort = t_sparse2(tIdx_2);


% Group by SORTED frame sizes and processor
[small_frames0, med_frames0, large_frames0] = find_res(gpu0_stats(tIdx_0));
[small_frames1, med_frames1, large_frames1] = find_res(gpu1_stats(tIdx_1));
[small_frames2, med_frames2, large_frames2] = find_res(gpu2_stats(tIdx_2));


% Get final data together: grouped by number of gpus and sorted by collection time (smallest to largest) within frame size
sifts2   = [t_sift2_sort(small_frames2)   t_sift2_sort(med_frames2)   t_sift2_sort(large_frames2)]'  ;
mats2    = [t_match2_sort(small_frames2)  t_match2_sort(med_frames2)  t_match2_sort(large_frames2)]' ;
sparses2 = [t_sparse2_sort(small_frames2) t_sparse2_sort(med_frames2) t_sparse2_sort(large_frames2)]';

sifts1   = [t_sift1_sort(small_frames1)   t_sift1_sort(med_frames1)   t_sift1_sort(large_frames1)]'  ;
mats1    = [t_match1_sort(small_frames1)  t_match1_sort(med_frames1)  t_match1_sort(large_frames1)]' ;
sparses1 = [t_sparse1_sort(small_frames1) t_sparse1_sort(med_frames1) t_sparse1_sort(large_frames1)]';

sifts0   = [t_sift0_sort(small_frames0)   t_sift0_sort(med_frames0)   t_sift0_sort(large_frames0)]'  ;
mats0    = [t_match0_sort(small_frames0)  t_match0_sort(med_frames0)  t_match0_sort(large_frames0)]' ;
sparses0 = [t_sparse0_sort(small_frames0) t_sparse0_sort(med_frames0) t_sparse0_sort(large_frames0)]';

xmin = 0;
xmax = size(gpu0_stats,2) + size(gpu1_stats,2) + size(gpu2_stats,2) + 3;
ymin = 0;
%ymax defined in case statement

%..............  Start the plot  ............
figure('Position', [1200 800 1000 500]); 

bar(1:size(sifts2,1), [sifts2 mats2 sparses2], 0.5, 'stacked');
axis([xmin xmax ymin ymax]);

% if strcmp(plot_type,'norm_by_sparse_recon')
%     set(gca,'YScale', 'log');    % log scale on y-axis
% end

hold on
set(gca, 'Ticklength', [0 0]);

labels2 = {'640x480', '640x480', '640x480', '640x480', '640x480', '640x480', '1920x1080',  '1920x1080', '3840x2880', '3840x2880', ' '};
labels1 = {'640x480', '640x480', '640x480', '640x480', '640x480', '640x480', '1920x1080',  '1920x1080', '3840x2880', '3840x2880', ' '};
labels0 = {'640x480', '640x480', '640x480', '640x480', '640x480', '640x480', '3840x2880'};
xticklabel_rotate((1:29), 90, horzcat(labels2, labels1, labels0), 'Fontweight', 'Bold');

start1 = size(sifts2, 1) + 2;
start0 = size(sifts2, 1) + size(sifts1,1) + 3;

bar(start1: start1 + size(sifts1,1)-1, [sifts1 mats1 sparses1], 0.5, 'stacked');
bar(start0: start0 + size(sifts0,1)-1, [sifts0 mats0 sparses0], 0.5, 'stacked');

legend('sift', 'match', 'sparse recon','Location', 'NorthWest');

title(title_str,   'FontWeight', 'Bold', 'Fontsize', 12); 
ylabel(ylabel_str, 'FontWeight', 'Bold', 'Fontsize', 12);
xlabel('             2 GPUs                                                   1 GPU                                                     CPU only  ', ...
       'Fontweight', 'Bold', 'Fontsize', 11); 

set(gca, 'linewidth', 1.5, 'FontWeight','Bold');

hold off

end
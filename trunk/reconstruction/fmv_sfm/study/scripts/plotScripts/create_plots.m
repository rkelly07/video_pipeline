% create plots of collect time vs processing time

clear all;
addpath '/data/study/stats';
stats = read_stats( 'stats__25-Apr-2014_16-58-30.txt');
stats2 = read_stats('stats__24-Apr-2014_17-23-45.txt');

%stats = [stats stats2];

warning('off','MATLAB:legend:IgnoringExtraEntries');  % suppress message from legend 

gpu0_stats = stats( [stats.nGPU] == 0 );
gpu1_stats = stats( [stats.nGPU] == 1 );
gpu2_stats = stats( [stats.nGPU] == 2 );


% Get corresponding processing times (changed to minutes)
t_proc0 = [gpu0_stats.t_sparse_total]./60; % sparse
t_proc1 = [gpu1_stats.t_sparse_total]./60;
t_proc2 = [gpu2_stats.t_sparse_total]./60;

t_proc0_d = [gpu0_stats.t_dense]./60; % dense
t_proc1_d = [gpu1_stats.t_dense]./60;
t_proc2_d = [gpu2_stats.t_dense]./60;

nt_proc0 = [gpu0_stats.t_sparse_total]./[gpu0_stats.reconFrames]; % normalized sparse in seconds
nt_proc1 = [gpu1_stats.t_sparse_total]./[gpu1_stats.reconFrames];
nt_proc2 = [gpu2_stats.t_sparse_total]./[gpu2_stats.reconFrames];

nt_proc0_d = [gpu0_stats.t_dense]./[gpu0_stats.reconFrames]; % normalized dense in seconds
nt_proc1_d = [gpu1_stats.t_dense]./[gpu1_stats.reconFrames];
nt_proc2_d = [gpu2_stats.t_dense]./[gpu2_stats.reconFrames];


% Get quality estimate as percent
q_proc0 = 100 - 100 * ([gpu0_stats.reconFrames] - [gpu0_stats.outliers])./[gpu0_stats.nFrames];  % sparse
q_proc1 = 100 - 100 * ([gpu1_stats.reconFrames] - [gpu1_stats.outliers])./[gpu1_stats.nFrames];
q_proc2 = 100 - 100 * ([gpu2_stats.reconFrames] - [gpu2_stats.outliers])./[gpu2_stats.nFrames];


% Sort collection times of input frame set (changed to minutes) for the x-axis
[time0, tIdx_0] = sort( [gpu0_stats.nFrames]./[gpu0_stats.fRate] ./60 );
[time1, tIdx_1] = sort( [gpu1_stats.nFrames]./[gpu1_stats.fRate] ./60 );
[time2, tIdx_2] = sort( [gpu2_stats.nFrames]./[gpu2_stats.fRate] ./60 );

% Sort y-axis times
t_proc0_sort = t_proc0(tIdx_0);      % sparse
t_proc1_sort = t_proc1(tIdx_1);
t_proc2_sort = t_proc2(tIdx_2);

t_proc0_dsort = t_proc0_d(tIdx_0);   % dense
t_proc1_dsort = t_proc1_d(tIdx_1);
t_proc2_dsort = t_proc2_d(tIdx_2);

nt_proc0_sort = nt_proc0(tIdx_0);    % normalized sparse
nt_proc1_sort = nt_proc1(tIdx_1);
nt_proc2_sort = nt_proc2(tIdx_2);

nt_proc0_dsort = nt_proc0_d(tIdx_0); % normalized dense
nt_proc1_dsort = nt_proc1_d(tIdx_1);
nt_proc2_dsort = nt_proc2_d(tIdx_2);

% Sort y-axis quality of input frame set
q_proc0_sort = q_proc0(tIdx_0);      % sparse
q_proc1_sort = q_proc1(tIdx_1);
q_proc2_sort = q_proc2(tIdx_2);


% Group by SORTED frame sizes and processor
[small_frames0, med_frames0, large_frames0] = find_res(gpu0_stats(tIdx_0));
[small_frames1, med_frames1, large_frames1] = find_res(gpu1_stats(tIdx_1));
[small_frames2, med_frames2, large_frames2] = find_res(gpu2_stats(tIdx_2));



% Create benchmark line for 15 minutes
b_line_15min  = [15 15];
b_time0       = [0 ceil(time0(end))];
b_time1       = [0 ceil(time1(end))];
b_time2       = [0 ceil(time2(end))];

% Create benchmark line for 2 hours
b_line_hrs  = [120 120];


% Create benchmark line for 1 day
b_line_day   = [1440 1440];

% Create benchmark line for 1 week
b_line_week  = [10080 10080];


real_time0 = (1: .5: ceil(time0(end)));
real_time1 = (1: .5: ceil(time1(end)));
real_time2 = (1: .5: ceil(time2(end)));

sColor = rgb('DodgerBlue');
mColor = rgb('ForestGreen');
lColor = rgb('Orchid');

minuteColor = rgb('Crimson');
hourColor   = rgb('LightPink');
dayColor    = rgb('PeachPuff');
weekColor   = rgb('PapayaWhip');

%  Various graphing variables
markSz  = 7;  % marker size
xmin    = 0;
xmax    = 18;
ymin    = 1;
ymax    = 30000;

% one figure per page or 3?
three_on_one  = false;
include_dense = false;


%----------------------------------------------------------------------------------------
%----------------- 1 plot per figure: Total reconstruction time   ----------------------
if (~three_on_one)

    figure('Position', [1200 800 1000 500]); 
    
    % Make certain that all dots are graphed (for legend) -- This is totally fake
    x_test = 0;
    y_test = 0;
    if (include_dense)
        semilogy(x_test, y_test,'^', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', 'none','MarkerSize', markSz);
        hold on   
        semilogy(x_test, y_test,'^', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    else
        semilogy(x_test, y_test,'^', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
        hold on
    end
    semilogy(x_test, y_test,'^', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor,'MarkerSize', markSz);
    semilogy(x_test, y_test,'^', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor,'MarkerSize', markSz);
    
    semilogy(x_test, y_test,'o', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    semilogy(x_test, y_test,'o', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor,'MarkerSize', markSz);
    semilogy(x_test, y_test,'o', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor,'MarkerSize', markSz);
    
    semilogy(x_test, y_test,'s', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    semilogy(x_test, y_test,'s', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor,'MarkerSize', markSz);
    semilogy(x_test, y_test,'s', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor,'MarkerSize', markSz);
    %       ... for dense ....
    if (include_dense)
        semilogy(x_test, y_test,'^', 'MarkerEdgeColor', 'none', 'MarkerFaceColor', 'none','MarkerSize', markSz);
        semilogy(x_test, y_test,'^', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', 'none','MarkerSize', markSz);
        semilogy(x_test, y_test,'^', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', 'none','MarkerSize', markSz);
        semilogy(x_test, y_test,'^', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', 'none','MarkerSize', markSz);

        semilogy(x_test, y_test,'o', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', 'none','MarkerSize', markSz);
        semilogy(x_test, y_test,'o', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', 'none','MarkerSize', markSz);
        semilogy(x_test, y_test,'o', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', 'none','MarkerSize', markSz);

        semilogy(x_test, y_test,'s', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', 'none','MarkerSize', markSz);
        semilogy(x_test, y_test,'s', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', 'none','MarkerSize', markSz);
        semilogy(x_test, y_test,'s', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', 'none','MarkerSize', markSz);    
    end

    % --- Start Useful plotting:  First do sparse ----
    %  plot 2 gpus
    h1 = semilogy(time2(small_frames2), t_proc2_sort(small_frames2),'^', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    axis([xmin xmax ymin ymax]);

    %hold on
    h2 = semilogy(time2(med_frames2),   t_proc2_sort(med_frames2),  '^', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor, 'MarkerSize', markSz);
    h3 = semilogy(time2(large_frames2), t_proc2_sort(large_frames2),'^', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor, 'MarkerSize', markSz);
    
    % one gpu
    h4 = semilogy(time1(small_frames1), t_proc1_sort(small_frames1),'o', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor, 'MarkerSize', markSz);
    h5 = semilogy(time1(med_frames1),   t_proc1_sort(med_frames1),  'o', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor, 'MarkerSize', markSz);
    h6 = semilogy(time1(large_frames1), t_proc1_sort(large_frames1),'o', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor, 'MarkerSize', markSz);
    
    % cpu only
    h7 = semilogy(time0(small_frames0), t_proc0_sort(small_frames0),'s', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    h8 = semilogy(time0(med_frames0),   t_proc0_sort(med_frames0),  's', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor, 'MarkerSize', markSz);
    h9 = semilogy(time0(large_frames0), t_proc0_sort(large_frames0),'s', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor, 'MarkerSize', markSz);
    
    
    % --- Next do dense ----
    if (include_dense)
        %  plot 2 gpus
        h11 = semilogy(time2(small_frames2), t_proc2_dsort(small_frames2),'^', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', 'none','MarkerSize', markSz);
        h21 = semilogy(time2(med_frames2),   t_proc2_dsort(med_frames2),  '^', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', 'none', 'MarkerSize', markSz);
        h31 = semilogy(time2(large_frames2), t_proc2_dsort(large_frames2),'^', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', 'none', 'MarkerSize', markSz);

        % one gpu
        h41 = semilogy(time1(small_frames1), t_proc1_dsort(small_frames1),'o', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', 'none', 'MarkerSize', markSz);
        h51 = semilogy(time1(med_frames1),   t_proc1_dsort(med_frames1),  'o', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', 'none', 'MarkerSize', markSz);
        h61 = semilogy(time1(large_frames1), t_proc1_dsort(large_frames1),'o', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', 'none', 'MarkerSize', markSz);

        % cpu only
        h71 = semilogy(time0(small_frames0), t_proc0_dsort(small_frames0),'s', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', 'none','MarkerSize', markSz);
        h81 = semilogy(time0(med_frames0),   t_proc0_dsort(med_frames0),  's', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', 'none', 'MarkerSize', markSz);
        h91 = semilogy(time0(large_frames0), t_proc0_dsort(large_frames0),'s', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', 'none', 'MarkerSize', markSz);
    end
    
    % --- Benchmark lines ----    
    semilogy(real_time2, real_time2,   'k',   'Linewidth', 2);
    semilogy(b_time2,    b_line_15min, '--',  'Linewidth', 2, 'Color', minuteColor);
    semilogy(b_time2,    b_line_hrs,   '--',  'Linewidth', 2, 'Color', hourColor  );
    semilogy(b_time2,    b_line_day,   '--',  'Linewidth', 2, 'Color', dayColor   );
    semilogy(b_time2,    b_line_week,  '--',  'Linewidth', 2, 'Color', weekColor   );
    
    % ---- Legend and labels ----
    if (include_dense)
        hLeg   = legend('Sparse Legend',                                                   ...
                        '2 GPUs; 640 x 480', '2 GPUs; 1920 x 1080', '2 GPUs; 3840 x 2880', ...
                        '1 GPUs; 640 x 480', '1 GPU;  1920 x 1080', '1 GPU;  3840 x 2880', ...
                        'CPU;    640 x 480', 'CPU;    1920 x 1080', 'CPU;    3840 x 2880', ...
                        'Dense Legend',                                                    ...
                        '2 GPUs; 640 x 480', '2 GPUs; 1920 x 1080', '2 GPUs; 3840 x 2880', ...
                        '1 GPUs; 640 x 480', '1 GPU;  1920 x 1080', '1 GPU;  3840 x 2880', ...
                        'CPU;    640 x 480', 'CPU;    1920 x 1080', 'CPU;    3840 x 2880', ...                       
                        'Location', 'NorthWestOutside');
    else
        hLeg   = legend('2 GPUs; 640 x 480', '2 GPUs; 1920 x 1080', '2 GPUs; 3840 x 2880', ...
                        '1 GPUs; 640 x 480', '1 GPU;  1920 x 1080', '1 GPU;  3840 x 2880', ...
                        'CPU;    640 x 480', 'CPU;    1920 x 1080', 'CPU;    3840 x 2880', ...
                        'Location', 'NorthWestOutside');
    end
    htext  = findobj(get(hLeg, 'children'), 'type', 'text');
    set(htext, 'fontweight', 'bold');

    
    xlabel('Collection Time (min)', 'FontWeight', 'Bold', 'FontSize', 10 );
    ylabel('Processing Time (min)', 'FontWeight', 'Bold', 'FontSize', 10 );
 
    if (include_dense)
         title('Sparse and Dense Reconstruction', 'FontWeight', 'Bold', 'FontSize', 12) ;
    else
        title('Sparse Reconstruction', 'FontWeight', 'Bold', 'FontSize', 12) ;
    end
    
    set(gca, 'linewidth', 1.5, 'FontWeight','Bold');

    % ... annotate dashed lines .....
    annotation('textbox',[.32 .26 .1 .1 ], 'String', '15 min',  'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.32 .42 .1 .1 ], 'String', '2 hours', 'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.32 .62 .1 .1 ], 'String', '1 day',  'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.32 .77 .1 .1 ], 'String', '1 week', 'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.32 .1 .1 .1 ], 'String', 'real time',   'LineStyle','none', 'FontWeight', 'Bold');
    %annotation('textbox',[.16 .1 .1 .1 ], 'String', 'real time',   'LineStyle','none', 'FontWeight', 'Bold');
    
    % ... put the markers back to the top ...
    uistack(h9, 'top');
    uistack(h8, 'top');
    uistack(h7, 'top');
    uistack(h6, 'top');
    uistack(h5, 'top');
    uistack(h4, 'top');
    uistack(h3, 'top');
    uistack(h2, 'top');
    uistack(h1, 'top');
    
    if (include_dense) 
        uistack(h91, 'top');
        uistack(h81, 'top');
        uistack(h71, 'top');
        uistack(h61, 'top');
        uistack(h51, 'top');
        uistack(h41, 'top');
        uistack(h31, 'top');
        uistack(h21, 'top');
        uistack(h11, 'top');
    end

    hold off
end



%----------------------------------------------------------------------------------------
%----------------- 1 plot per figure: Normalized reconstruction time   ----------------------
if (~three_on_one)

    figure('Position', [1200 800 1000 500]); 

    % --- Start Useful plotting:  First do sparse ----
    %  plot 2 gpus
    %axis([xmin xmax ymin ymax]);
    % ... Fake curves for legend ....
    semilogy(x_test, y_test,'^', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    hold on
    
    semilogy(x_test, y_test,'^', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor,'MarkerSize', markSz);
    semilogy(x_test, y_test,'^', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor,'MarkerSize', markSz);
    
    semilogy(x_test, y_test,'o', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    semilogy(x_test, y_test,'o', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor,'MarkerSize', markSz);
    semilogy(x_test, y_test,'o', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor,'MarkerSize', markSz);
    
    semilogy(x_test, y_test,'s', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    semilogy(x_test, y_test,'s', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor,'MarkerSize', markSz);
    semilogy(x_test, y_test,'s', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor,'MarkerSize', markSz);
    
    % ... Curves we care about ....
    h1 = semilogy(time2(small_frames2), nt_proc2_sort(small_frames2),'^', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    h2 = semilogy(time2(med_frames2),   nt_proc2_sort(med_frames2),  '^', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor, 'MarkerSize', markSz);
    h3 = semilogy(time2(large_frames2), nt_proc2_sort(large_frames2),'^', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor, 'MarkerSize', markSz);
    
    % one gpu
    h4 = semilogy(time1(small_frames1), nt_proc1_sort(small_frames1),'o', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor, 'MarkerSize', markSz);
    h5 = semilogy(time1(med_frames1),   nt_proc1_sort(med_frames1),  'o', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor, 'MarkerSize', markSz);
    h6 = semilogy(time1(large_frames1), nt_proc1_sort(large_frames1),'o', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor, 'MarkerSize', markSz);
    
    % cpu only
    h7 = semilogy(time0(small_frames0), nt_proc0_sort(small_frames0),'s', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    h8 = semilogy(time0(med_frames0),   nt_proc0_sort(med_frames0),  's', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor, 'MarkerSize', markSz);
    h9 = semilogy(time0(large_frames0), nt_proc0_sort(large_frames0),'s', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor, 'MarkerSize', markSz);
    
    % ... Legend ....
    hLeg   = legend('2 GPUs; 640 x 480', '2 GPUs; 1920 x 1080', '2 GPUs; 3840 x 2880', ...
                    '1 GPUs; 640 x 480', '1 GPU;  1920 x 1080', '1 GPU;  3840 x 2880', ...
                    'CPU;    640 x 480', 'CPU;    1920 x 1080', 'CPU;    3840 x 2880', ...
                    'Location', 'NorthWestOutside');
    
    htext  = findobj(get(hLeg, 'children'), 'type', 'text');
    set(htext, 'fontweight', 'bold');
    
    % ... put the markers back to the top ...
    uistack(h9, 'top');
    uistack(h8, 'top');
    uistack(h7, 'top');
    uistack(h6, 'top');
    uistack(h5, 'top');
    uistack(h4, 'top');
    uistack(h3, 'top');
    uistack(h2, 'top');
    uistack(h1, 'top');
    
    
    % .... Labels ....
    
    set(gca, 'linewidth', 1.5, 'FontWeight','Bold');
    
    xlabel('Collection Time (min)', 'FontWeight', 'Bold', 'FontSize', 12 );
    ylabel('Normalized Processing Time (sec/frame)', 'FontWeight', 'Bold', 'FontSize', 12 );
    title('Normalized Sparse Reconstruction', 'FontWeight', 'Bold', 'FontSize', 12) ;
    
    hold off
 end



%----------------------------------------------------------------------------------------
%----------------- 1 plot per figure: Quality vs Collection time   ----------------------
if (~three_on_one)
    
    high_q  = [1 1];
    good_q  = [10 10];
    low_q   = [30 30];
    b_time0       = [0 ceil(time0(end))];
    
    
    figure('Position', [1200 800 1000 500]); 

    % --- Start Useful plotting:  First do sparse ----
    %  plot 2 gpus
   
    % ... Fake curves for legend ....
    x_test = -1;
    y_test =  0;
    semilogy(x_test, y_test,'^', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    axis([xmin xmax 0 120]);
    set(gca,'YDir','reverse');
    
    hold on
    
    semilogy(x_test, y_test,'^', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor,'MarkerSize', markSz);
    semilogy(x_test, y_test,'^', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor,'MarkerSize', markSz);
    
    semilogy(x_test, y_test,'o', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    semilogy(x_test, y_test,'o', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor,'MarkerSize', markSz);
    semilogy(x_test, y_test,'o', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor,'MarkerSize', markSz);
    
    semilogy(x_test, y_test,'s', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    semilogy(x_test, y_test,'s', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor,'MarkerSize', markSz);
    semilogy(x_test, y_test,'s', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor,'MarkerSize', markSz);
    
    % ... Curves we care about ....
    h1 = semilogy(time2(small_frames2), q_proc2_sort(small_frames2),'^', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    h2 = semilogy(time2(med_frames2),   q_proc2_sort(med_frames2),  '^', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor, 'MarkerSize', markSz);
    h3 = semilogy(time2(large_frames2), q_proc2_sort(large_frames2),'^', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor, 'MarkerSize', markSz);
    
    % one gpu
    h4 = semilogy(time1(small_frames1), q_proc1_sort(small_frames1),'o', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor, 'MarkerSize', markSz);
    h5 = semilogy(time1(med_frames1),   q_proc1_sort(med_frames1),  'o', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor, 'MarkerSize', markSz);
    h6 = semilogy(time1(large_frames1), q_proc1_sort(large_frames1),'o', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor, 'MarkerSize', markSz);
    
    % cpu only
    h7 = semilogy(time0(small_frames0), q_proc0_sort(small_frames0),'s', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    h8 = semilogy(time0(med_frames0),   q_proc0_sort(med_frames0),  's', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor, 'MarkerSize', markSz);
    h9 = semilogy(time0(large_frames0), q_proc0_sort(large_frames0),'s', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor, 'MarkerSize', markSz);

    %..... Quality lines ....
    semilogy(b_time2,    high_q, '--',  'Linewidth', 2, 'Color', minuteColor);
    semilogy(b_time2,    good_q, '--',  'Linewidth', 2, 'Color', hourColor  );
    semilogy(b_time2,    low_q,  '--',  'Linewidth', 2, 'Color', dayColor   );
    
    annotation('textbox',[.32 .708 .1 .032 ], 'String', 'high quality',  'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.32 .418 .1 .032 ], 'String', 'good quality',  'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.32 .28 .1 .032 ], 'String', '70 % ',         'LineStyle','none', 'FontWeight', 'Bold');
    
    
    % ... Legend ....
    hLeg   = legend('2 GPUs; 640 x 480', '2 GPUs; 1920 x 1080', '2 GPUs; 3840 x 2880', ...
                    '1 GPUs; 640 x 480', '1 GPU;  1920 x 1080', '1 GPU;  3840 x 2880', ...
                    'CPU;    640 x 480', 'CPU;    1920 x 1080', 'CPU;    3840 x 2880', ...
                    'Location', 'NorthWestOutside');
    
    htext  = findobj(get(hLeg, 'children'), 'type', 'text');
    set(htext, 'fontweight', 'bold');
    
    % ... put the markers back to the top ...
    uistack(h9, 'top');
    uistack(h8, 'top');
    uistack(h7, 'top');
    uistack(h6, 'top');
    uistack(h5, 'top');
    uistack(h4, 'top');
    uistack(h3, 'top');
    uistack(h2, 'top');
    uistack(h1, 'top');
    
   
    % .... Labels ....
    set(gca, 'linewidth', 1.5, 'FontWeight','Bold');
    
    xlabel('Collection Time (min)', 'FontWeight', 'Bold', 'FontSize', 12 );
    ylabel('Quality (% frames used)', 'FontWeight', 'Bold', 'FontSize', 12 );
    title('Quality of Sparse Reconstruction', 'FontWeight', 'Bold', 'FontSize', 12) ;
    
    
    set(gca,'yticklabel',num2str(100-10.^str2num(get(gca,'yticklabel'))));      %#ok<ST2NM>
  
    
    hold off
end







%--------------------------------------------------------------------------------------------
%--------------------------------------  3 plots per figure  --------------------------------

if (three_on_one)

    %---------------- Sparse Reconstructions --------------------------------
    %------------------------------------------------------------------------

    % -------- Set up figure to have 3 subplots -------

    figure('Position',[100, 100, 800, 1200]);               %#ok<*UNRCH>

    % --------  Plot 2 gpu case  ----------------
    subplot(3, 1, 1 );


    h1 = semilogy(time2(small_frames2), t_proc2_sort(small_frames2),'^', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    axis([xmin xmax ymin ymax]);

    hold on
    h2 = semilogy(time2(med_frames2),   t_proc2_sort(med_frames2),  '^', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor, 'MarkerSize', markSz);
    h3 = semilogy(time2(large_frames2), t_proc2_sort(large_frames2),'^', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor, 'MarkerSize', markSz);

    semilogy(real_time2, real_time2,   'k',   'Linewidth', 2);
    semilogy(b_time2,    b_line_15min, '--',  'Linewidth', 2, 'Color', minuteColor);
    semilogy(b_time2,    b_line_hrs,   '--',  'Linewidth', 2, 'Color', hourColor  );
    semilogy(b_time2,    b_line_day,   '--',  'Linewidth', 2, 'Color', dayColor   );

    hLeg   = legend('640 x 480', '1920 x 1080', '3840 x 2880', 'Location', 'NorthWest');
    htext  = findobj(get(hLeg, 'children'), 'type', 'text');
    set(htext, 'fontweight', 'bold');

    xlabel('Collection Time (min)', 'FontWeight', 'Bold', 'FontSize', 10 );
    ylabel('Processing Time (min)', 'FontWeight', 'Bold', 'FontSize', 10 );
    title('Sparse Reconstruction: 2 GPUs ',   'FontWeight', 'Bold', 'FontSize', 12) ;

    set(gca, 'linewidth', 1.5, 'FontWeight','Bold');

    % ... annotate dashed lines .....
    annotation('textbox',[.3 .685 .1 .1 ], 'String', '15 min',  'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.3 .735 .1 .1 ], 'String', '2 hours', 'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.3 .793 .1 .1 ], 'String', '1 day',   'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.17 .64 .1 .1 ], 'String', 'real time',   'LineStyle','none', 'FontWeight', 'Bold');

    % ... put the markers back to the top ...
    uistack(h3, 'top');
    uistack(h2, 'top');
    uistack(h1, 'top');

    hold off


    %hfig2 = figure(2);
    % --------  Plot 1 gpu case  ----------------
    subplot(3, 1, 2 );

    h1 = semilogy(time1(small_frames1), t_proc1_sort(small_frames1),'^', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor, 'MarkerSize', markSz);
    axis([xmin xmax ymin ymax]);

    hold on
    h2 = semilogy(time1(med_frames1),   t_proc1_sort(med_frames1),  '^', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor, 'MarkerSize', markSz);
    h3 = semilogy(time1(large_frames1), t_proc1_sort(large_frames1),'^', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor, 'MarkerSize', markSz);

    semilogy(real_time1, real_time1,   'k',  'Linewidth', 2);
    semilogy(b_time1,    b_line_15min, '--', 'Linewidth', 2, 'Color', minuteColor );
    semilogy(b_time1,    b_line_hrs,   '--', 'Linewidth', 2, 'Color', hourColor   );
    semilogy(b_time1,    b_line_day,   '--', 'Linewidth', 2, 'Color', dayColor    );

    hLeg   = legend('640 x 480', '1920 x 1080', '3840 x 2880', 'Location', 'NorthWest');
    htext  = findobj(get(hLeg, 'children'), 'type', 'text');
    set(htext, 'fontweight', 'bold');

    xlabel('Collection Time (min)', 'FontWeight', 'Bold', 'FontSize', 10 );
    ylabel('Processing Time (min)', 'FontWeight', 'Bold', 'FontSize', 10 );
    title('Sparse Reconstruction: 1 GPU ',    'FontWeight', 'Bold', 'FontSize', 12 );

    set(gca, 'linewidth', 1.5, 'FontWeight','Bold');

    % ... annotate dashed lines .....
    annotation('textbox',[.3 .386 .1 .1 ], 'String', '15 min',  'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.3 .435 .1 .1 ], 'String', '2 hours', 'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.3 .492 .1 .1 ], 'String', '1 day',   'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.17 .34 .1 .1 ], 'String', 'real time',   'LineStyle','none', 'FontWeight', 'Bold');

    % ... put the markers back to the top ...
    uistack(h3, 'top');
    uistack(h2, 'top');
    uistack(h1, 'top');

    hold off


    %hfig3 = figure(3);
    % --------  Plot 0 gpu case  ----------------
    subplot(3, 1, 3 ); 

    h1 = semilogy(time0(small_frames0), t_proc0_sort(small_frames0),'^', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    axis([xmin xmax ymin ymax]);

    hold on
    h2 = semilogy(time0(med_frames0),   t_proc0_sort(med_frames0),  '^', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor, 'MarkerSize', markSz);
    h3 = semilogy(time0(large_frames0), t_proc0_sort(large_frames0),'^', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor, 'MarkerSize', markSz);

    semilogy(real_time0, real_time0,   'k',   'Linewidth', 2 );
    semilogy(b_time0,    b_line_15min, '--',  'Linewidth', 2, 'Color', minuteColor );
    semilogy(b_time0,    b_line_hrs,   '--',  'Linewidth', 2, 'Color', hourColor   );
    semilogy(b_time0,    b_line_day,   '--',  'Linewidth', 2, 'Color', dayColor    );

    if (~isempty( time0(med_frames0) ) && ~isempty( time0(large_frames0)) )
        hLeg   = legend('640 x 480', '1920 x 1080', '3840 x 2880', 'Location', 'NorthWest');
    end
    if (isempty( time0(med_frames0) ) && isempty( time0(large_frames0)) )
        hLeg   = legend('640 x 480', 'Location', 'NorthWest');
    end
    if (isempty( time0(med_frames0) ) && ~isempty( time0(large_frames0)) )
        hLeg   = legend('640 x 480', '3840 x 2880', 'Location', 'NorthWest');
    end
    if (~isempty( time0(med_frames0) ) && isempty( time0(large_frames0)) )
        hLeg   = legend('640 x 480', '1920 x 1080', 'Location', 'NorthWest');
    end


    htext  = findobj(get(hLeg, 'children'), 'type', 'text');
    set(htext, 'fontweight', 'bold');

    xlabel('Collection Time (min)', 'FontWeight', 'Bold', 'FontSize', 10 );
    ylabel('Processing Time (min)', 'FontWeight', 'Bold', 'FontSize', 10 );
    title('Sparse Reconstruction: CPU only ', 'FontWeight', 'Bold', 'FontSize', 12 );

    set(gca, 'linewidth', 1.5, 'FontWeight','Bold');

    % ... annotate dashed lines .....
    annotation('textbox',[.3 .088 .1 .1 ], 'String', '15 min',  'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.3 .136 .1 .1 ], 'String', '2 hours', 'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.3 .194 .1 .1 ], 'String', '1 day',   'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.17 .043 .1 .1 ], 'String', 'real time',   'LineStyle','none', 'FontWeight', 'Bold');


    % ... put the markers back to the top ...
    uistack(h3, 'top');
    uistack(h2, 'top');
    uistack(h1, 'top');

    hold off

    %---------------- Dense Reconstructions --------------------------------
    %------------------------------------------------------------------------

    % -------- Set up figure to have 3 subplots -------

    hfig1 = figure('Position',[100, 100, 800, 1200]);

    % --------  Plot 2 gpu case  ----------------
    subplot(3, 1, 1 );


    h1 = semilogy(time2(small_frames2), t_proc2_dsort(small_frames2),'^', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    axis([xmin xmax ymin ymax]);

    hold on
    h2 = semilogy(time2(med_frames2),   t_proc2_dsort(med_frames2),  '^', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor, 'MarkerSize', markSz);
    h3 = semilogy(time2(large_frames2), t_proc2_dsort(large_frames2),'^', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor, 'MarkerSize', markSz);

    semilogy(real_time2, real_time2,   'k',   'Linewidth', 2);
    semilogy(b_time2,    b_line_15min, '--',  'Linewidth', 2, 'Color', minuteColor);
    semilogy(b_time2,    b_line_hrs,   '--',  'Linewidth', 2, 'Color', hourColor  );
    semilogy(b_time2,    b_line_day,   '--',  'Linewidth', 2, 'Color', dayColor   );

    hLeg   = legend('640 x 480', '1920 x 1080', '3840 x 2880', 'Location', 'NorthWest');
    htext  = findobj(get(hLeg, 'children'), 'type', 'text');
    set(htext, 'fontweight', 'bold');

    xlabel('Collection Time (min)', 'FontWeight', 'Bold', 'FontSize', 10 );
    ylabel('Processing Time (min)', 'FontWeight', 'Bold', 'FontSize', 10 );
    title('Dense Reconstruction: 2 GPUs ',   'FontWeight', 'Bold', 'FontSize', 12) ;

    set(gca, 'linewidth', 1.5, 'FontWeight','Bold');

    % ... annotate dashed lines .....
    annotation('textbox',[.3 .685 .1 .1 ], 'String', '15 min',  'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.3 .735 .1 .1 ], 'String', '2 hours', 'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.3 .793 .1 .1 ], 'String', '1 day',   'LineStyle','none', 'FontWeight', 'Bold');

    % ... put the markers back to the top ...
    uistack(h3, 'top');
    uistack(h2, 'top');
    uistack(h1, 'top');

    hold off


    %hfig2 = figure(2);
    % --------  Plot 1 gpu case  ----------------
    subplot(3, 1, 2 );

    h1 = semilogy(time1(small_frames1), t_proc1_dsort(small_frames1),'^', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor, 'MarkerSize', markSz);
    axis([xmin xmax ymin ymax]);

    hold on
    h2 = semilogy(time1(med_frames1),   t_proc1_dsort(med_frames1),  '^', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor, 'MarkerSize', markSz);
    h3 = semilogy(time1(large_frames1), t_proc1_dsort(large_frames1),'^', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor, 'MarkerSize', markSz);

    semilogy(real_time1, real_time1,   'k',  'Linewidth', 2);
    semilogy(b_time1,    b_line_15min, '--', 'Linewidth', 2, 'Color', minuteColor );
    semilogy(b_time1,    b_line_hrs,   '--', 'Linewidth', 2, 'Color', hourColor   );
    semilogy(b_time1,    b_line_day,   '--', 'Linewidth', 2, 'Color', dayColor    );

    hLeg   = legend('640 x 480', '1920 x 1080', '3840 x 2880', 'Location', 'NorthWest');
    htext  = findobj(get(hLeg, 'children'), 'type', 'text');
    set(htext, 'fontweight', 'bold');

    xlabel('Collection Time (min)', 'FontWeight', 'Bold', 'FontSize', 10 );
    ylabel('Processing Time (min)', 'FontWeight', 'Bold', 'FontSize', 10 );
    title('Dense Reconstruction: 1 GPU ',    'FontWeight', 'Bold', 'FontSize', 12 );

    set(gca, 'linewidth', 1.5, 'FontWeight','Bold');

    % ... annotate dashed lines .....
    annotation('textbox',[.3 .386 .1 .1 ], 'String', '15 min',  'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.3 .435 .1 .1 ], 'String', '2 hours', 'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.3 .492 .1 .1 ], 'String', '1 day',   'LineStyle','none', 'FontWeight', 'Bold');

    % ... put the markers back to the top ...
    uistack(h3, 'top');
    uistack(h2, 'top');
    uistack(h1, 'top');

    hold off


    %hfig3 = figure(3);
    % --------  Plot 0 gpu case  ----------------
    subplot(3, 1, 3 );


    h1 = semilogy(time0(small_frames0), t_proc0_dsort(small_frames0),'^', 'MarkerEdgeColor', sColor, 'MarkerFaceColor', sColor,'MarkerSize', markSz);
    axis([xmin xmax ymin ymax]);

    hold on
    h2 = semilogy(time0(med_frames0),   t_proc0_dsort(med_frames0),  '^', 'MarkerEdgeColor', mColor, 'MarkerFaceColor', mColor, 'MarkerSize', markSz);
    h3 = semilogy(time0(large_frames0), t_proc0_dsort(large_frames0),'^', 'MarkerEdgeColor', lColor, 'MarkerFaceColor', lColor, 'MarkerSize', markSz);

    semilogy(real_time0, real_time0,   'k',   'Linewidth', 2 );
    semilogy(b_time0,    b_line_15min, '--',  'Linewidth', 2, 'Color', minuteColor );
    semilogy(b_time0,    b_line_hrs,   '--',  'Linewidth', 2, 'Color', hourColor   );
    semilogy(b_time0,    b_line_day,   '--',  'Linewidth', 2, 'Color', dayColor    );

    if (~isempty( time0(med_frames0) ) && ~isempty( time0(large_frames0)) )
        hLeg   = legend('640 x 480', '1920 x 1080', '3840 x 2880', 'Location', 'NorthWest');
    end
    if (isempty( time0(med_frames0) ) && isempty( time0(large_frames0)) )
        hLeg   = legend('640 x 480', 'Location', 'NorthWest');
    end
    if (isempty( time0(med_frames0) ) && ~isempty( time0(large_frames0)) )
        hLeg   = legend('640 x 480', '3840 x 2880', 'Location', 'NorthWest');
    end
    if (~isempty( time0(med_frames0) ) && isempty( time0(large_frames0)) )
        hLeg   = legend('640 x 480', '1920 x 1080', 'Location', 'NorthWest');
    end


    htext  = findobj(get(hLeg, 'children'), 'type', 'text');
    set(htext, 'fontweight', 'bold');

    xlabel('Collection Time (min)', 'FontWeight', 'Bold', 'FontSize', 10 );
    ylabel('Processing Time (min)', 'FontWeight', 'Bold', 'FontSize', 10 );
    title('Dense Reconstruction: CPU only ', 'FontWeight', 'Bold', 'FontSize', 12 );

    set(gca, 'linewidth', 1.5, 'FontWeight','Bold');

    % ... annotate dashed lines .....
    annotation('textbox',[.3 .088 .1 .1 ], 'String', '15 min',  'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.3 .136 .1 .1 ], 'String', '2 hours', 'LineStyle','none', 'FontWeight', 'Bold');
    annotation('textbox',[.3 .194 .1 .1 ], 'String', '1 day',   'LineStyle','none', 'FontWeight', 'Bold');



    % ... put the markers back to the top ...
    uistack(h3, 'top');
    uistack(h2, 'top');
    uistack(h1, 'top');

    hold off
end


return



%                     '2 GPUs; 640 x 480', '2 GPUs; 1920 x 1080', '2 GPUs; 3840 x 2880', ... 
%                     '1 GPUs; 640 x 480', '1 GPU;  1920 x 1080', '1 GPU;  3840 x 2880', ... 
%                     'CPU;    640 x 480', 'CPU;    1920 x 1080', 'CPU;    3840 x 2880', ...   


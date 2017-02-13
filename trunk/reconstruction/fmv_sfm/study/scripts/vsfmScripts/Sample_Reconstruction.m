%....................................................
%
%  Sample_Reconstruction
%
%  Script to enable VSFM pair-wise reconstruction
%  in a batch mode
%
%  variable recon_type: 1 = sparse + dense + gcp
%                       2 = sparse + gcp only
%                       3 = sparse only
%.....................................................

addpath('/data/study/scripts/nvmProcessing');
addpath('/data/study/scripts/vsfmScripts');

% ..... Number of batches of files (useful for varying # gpus) ...
num_batches = 1;  %3;

num_gpus    = zeros(num_batches, 1);
num_gpus(1) = 2;
num_gpus(2) = 1;
num_gpus(3) = 0;

%...... Number of files to reconstruct  ......
num_files = 1;  %10;


in_dir           = cell(num_files, 1);
in_truth_file    = cell(num_files, 1);
recon_type       = cell(num_files, 1);
mode_type        = cell(num_files, 1);
frame_rate       = cell(num_files, 1);

out_dir_top      = cell(num_files, 1);
out_dir_sparse   = cell(num_files, 1);
out_dir_dense    = cell(num_files, 1);

jpeg_step        = cell(num_files,1);
seq_match        = cell(num_files, 1);

in_dirX          = cell(num_files, 1);
in_truth_fileX   = cell(num_files, 1);
out_dir_topX     = cell(num_files, 1);

%...... User Input: jpg data file directory(ies) per num_files and type of reconstruction .....
in_dir{3} = fullfile('puma_Sep13_2013_YPG',          'subset');               %  jpg data file directory
in_dir{2} = fullfile('puma_April24_Day1_flt1',       'subset');               %  jpg data file directory
in_dir{1} = fullfile('puma_April24_Day1_flt1',       'map_mode_subset');      %  jpg data file directory
in_dir{4} = fullfile('puma_April24_Day1_flt1',       'human_subset');         %  jpg data file directory
in_dir{5} = fullfile('puma_April25_CampEdwards_Day2_flt3', 'subset');         %  jpg data file directory
in_dir{6} = fullfile('puma_May30_CampEdwards_Day1_flt2',   'subset');         %  jpg data file directory
in_dir{7} = fullfile('bryce3_cam3');                                          %  jpg data file directory
in_dir{8} = fullfile('bryce3_cam2');                                          %  jpg data file directory
in_dir{9} = fullfile('bryce2_cam3');                                          %  jpg data file directory
in_dir{10}= fullfile('bryce2_cam2');                                          %  jpg data file directory
% [in_dir{:}] = deal(fullfile('puma_April24_Day1_flt1',      'map_mode_subset'));               %  jpg data file directory

%...... User Input: matching metadata truth filename per num_files ....
in_truth_file{3} = 'puma_2013_09_13_flt1_subset.gcp';
in_truth_file{2} = 'puma_April24_2013_CampEdwards_Day1_flight1.gcp';
in_truth_file{1} = 'puma_April24_2013_CampEdwards_Day1_flight1.gcp';
in_truth_file{4} = 'puma_April24_2013_CampEdwards_Day1_flight1.gcp';
in_truth_file{5} = 'puma_April25_2013_CampEdwards_Day2_flight3.gcp';
in_truth_file{6} = 'puma_May30_2013_CampEdwards_Day1_flight2.gcp';
in_truth_file{7} = 'filenames_vs_gps_coords.bryce-wideFOVsnapshots-GoPro3.txt';
in_truth_file{8} = '';
in_truth_file{9} = '';
in_truth_file{10} = '';
% [in_truth_file{:}] = deal('puma_April24_2013_CampEdwards_Day1_flight1.gcp');

%..... User Input: flight mode and reconstruction type ...
mode_type{3}   = 'target';      frame_rate{1}  = 1; %Hz
mode_type{2}   = 'target';      frame_rate{2}  = 1; %Hz
mode_type{1}   = 'map';         frame_rate{3}  = 1; %Hz
mode_type{4}   = 'target';      frame_rate{4}  = 1; %Hz
mode_type{5}   = 'target';      frame_rate{5}  = 1; %Hz
mode_type{6}   = 'target';      frame_rate{6}  = 1; %Hz
mode_type{7}   = 'target';      frame_rate{7}  = 2; %Hz
mode_type{8}   = 'map';         frame_rate{8}  = 2; %Hz
mode_type{9}   = 'target';      frame_rate{9}  = 2; %Hz
mode_type{10}  = 'map';         frame_rate{10} = 2; %Hz
%[mode_type{:}]   = deal('target');      [frame_rate{:}] = deal(30); %Hz

recon_type{1}  = 1;
recon_type{2}  = 1;
recon_type{3}  = 1; 
recon_type{4}  = 1;
recon_type{5}  = 1;
recon_type{6}  = 1;
recon_type{7}  = 2;
recon_type{8}  = 3;
recon_type{9}  = 3;
recon_type{10} = 3;
%[recon_type{:}] = deal(2);

%...... User Input: jpeg step values string (for building input text file of jpgs from directory) per num_files ......
%....... (more choices will follow in future -dtmg)  ......
jpeg_step{1}  = '1';
jpeg_step{2}  = '1';
jpeg_step{3}  = '1';
jpeg_step{4}  = '1';
jpeg_step{5}  = '1';
jpeg_step{6}  = '1';
jpeg_step{7}  = '1';
jpeg_step{8}  = '1';
jpeg_step{9}  = '1';
jpeg_step{10} = '1';
%[jpeg_step{:}] = deal('1');

%....... User Input: sequence match string values (no space in between comma and numbers)....
seq_match{1} = '5,5';
seq_match{2} = '5,5';
seq_match{3} = '5,5';
seq_match{4} = '5,5';
seq_match{5} = '5,5';
seq_match{6} = '5,5';
seq_match{7} = '5,5';
seq_match{8} = '5,5';
seq_match{9} = '5,5';
seq_match{10} = '5,5';
%[seq_match{:}] = deal('5,5');

%...... Main directories for study (on talax).......
data_dir     = fullfile('/data', 'study', 'images');
truth_dir    = fullfile('/data', 'study', 'truth');
results_dir  = fullfile('/data', 'study', 'reconstruction_results');
cache_dir    = fullfile('/data', 'study', 'reconstruction_cache');
stats_dir    = fullfile('/data', 'study', 'stats');
vsfm_bin_dir = fullfile('/opt', 'VSFM', 'vsfm', 'bin');
    
stats       = initStats(num_files, num_batches);
fname_stats_txt = fullfile(stats_dir, strcat('stats__',date, '_', datestr(now,'HH-MM-SS'), '.txt' ) );
fname_stats_mat = fullfile(stats_dir, strcat('stats__',date, '_', datestr(now,'HH-MM-SS'), '.mat' ) );

minReconCams  = 50;
maxReconTries = 100;

%=======================  Set up and perform reconstructions =================================
%=============================================================================================

for jj = 1: num_batches

    nGPU           = num_gpus(jj);
    date_filename  = strcat('__',date, '.', datestr(now,'HH-MM-SS'),'_GPU', num2str(nGPU) );


    %...... Piece together Directory names and Filenames for processing .....
    for ii = 1: num_files
        cur_out_dir         = strcat( in_dir{ii},  date_filename) ; % do this first before adding full filepath
        in_dirX{ii}         = fullfile(data_dir ,  in_dir{ii} );           
        in_truth_fileX{ii}  = fullfile(truth_dir,  in_truth_file{ii} );
        out_dir_topX{ii}    = fullfile(results_dir, cur_out_dir);
    end

   
    %.......  Run reconstruction .......
    for ii = 1: num_files
        system( horzcat('rm -rf ', cache_dir, '/* ' ) );   %  clear cache directory
        pause(4);  % try pausing for files to fully clear before reconstructing

        idx                  = (jj - 1) * num_files + ii;
        stats(idx).fname     = in_dir{ii};
        stats(idx).mode      = mode_type{ii};
        stats(idx).nGPU      = nGPU;
        stats(idx).seq_match = seq_match{ii};
        stats(idx).fRate     = frame_rate{ii}/str2double(jpeg_step{ii});   % yields an effective frame rate
 
        stats(idx) = reconstruct(in_dirX{ii},        in_truth_fileX{ii},  ...
                                 recon_type{ii},     out_dir_topX{ii},    ...
                                 cache_dir,          stats_dir,           ...
                                 jpeg_step{ii},      seq_match{ii},       ...
                                 minReconCams,       maxReconTries,       ...
                                 nGPU,               vsfm_bin_dir,      stats(idx) );
                             
        writeStats( stats(idx), fname_stats_txt );
       % if (stats(idx).reconFrames < 20 )  %!!!! temporary !!!!!!
       %     break;
       % end
    end

end

% ..... Save stats as matlab file also, under same name as ascii text stats ....
save( fname_stats_mat, 'stats' );


fprintf(' Normal Termination \n');
return



function [stats] = reconstruct(in_dir,            in_truth_file,  ...
                                recon_type,        out_dir_top,    ...
                                cache_dir,         stats_dir,      ...
                                jpeg_step,         seq_match,      ...
                                minReconCams,      maxReconTries,  ...
                                nGPU,              vsfm_bin_dir, stats)
%--------------------------------------------------------------------------                                               
% reconstruct: function to create a VSFM pairs sparse reconstruction
%
% Function will create necessary directories and run the reconstruction
%
%  Uses:  check_VSFM_init_file()
%         set_up_jpegs()
%         deconstruct_nvm()
%         create_dirs()
%--------------------------------------------------------------------------

% ...... Step 1: Verify existing directories specified by user
 no_err = exist(in_dir, 'dir');
 no_err = exist(in_truth_file, 'file') && no_err;
 no_err = exist(cache_dir, 'dir')      && no_err;
 no_err = exist(stats_dir, 'dir')      && no_err;
 
 err_check(~no_err, '.... Found error in input filename or directory name .....\n');
 
 
 % ..... Step 2: Create top-level output directory 
 [out_dir_sparse, out_dir_dense] = create_dirs(out_dir_top, recon_type);
 
 
 %..... Step 3: Create dir for reconstruction
 no_err = check_VSFM_init_file(nGPU, vsfm_bin_dir);
 err_check(~no_err, '.... Error creating VSFM initialization file for number of GPUs .....\n');

 
 %..... Step 5: Create file of jpeg image names for reconstruction
 tstart       = tic();
 images_fname = 'images_in.txt';
 [no_err, res, num_images_in] = set_up_jpegs(in_dir, out_dir_top, cache_dir, jpeg_step, images_fname);
 t_setup      = toc(tstart); 
      %...... accumulate stats info .....
 stats.res       = res;
 stats.nFrames   = num_images_in;
 stats.t_setup   = t_setup;
 
 err_check(~no_err,'.... Error copying jpg image files or creating .txt file of jpg filenames .....\n');


 %..... Step 6a: Move to reconstruction cache directory, perform sparse reconstruction
 % % VisualSFM sfm+pairs+sort ../subset1_data/images_in.txt sparse_recon.nvm @5,5   (but done in pieces)
 save_dir = pwd;
 cd(cache_dir);
 nvm_fbase     = 'sparse_recon';
 nvm_fname     = horzcat(nvm_fbase,'.nvm');
 command_str   = horzcat('VisualSFM sfm+pairs+skipsfm ', images_fname, ' ','junk.nvm',' @', seq_match);
 %command_str   = horzcat('VisualSFM sfm+pairs+sort  ', images_fname, ' ', nvm_fname, ' @', seq_match);   % original input that makes sparse recon in one call
 tstart        = tic; 
 [~,cmd_out]   = system(command_str, '-echo');                                                                                       
 
 
 % ...... Save sift and match logfile .....
 log_folder   = fullfile(vsfm_bin_dir, 'log', '*.log');
 list         = dir(log_folder);
 [~,rank]     = sort([list.datenum],'descend');
 newest_log   = list(rank(1)).name;
 no_err_last  = copyfile( fullfile(vsfm_bin_dir, 'log', newest_log), fullfile(out_dir_top,'logfile_sift_match.txt'),'f');              %#ok<NASGU>
 

 %....... Save match information as input ......
 command_str  = horzcat('VisualSFM sfm+skipsfm+exportp ', images_fname, ' ', 'my_matches.txt');
 [~,~]        = system(command_str, '-echo');                                                                                         
 t_el_sift_plus_match    = toc(tstart);
 [t_el_sift, t_el_match] = parse_log(cmd_out);

 
 nFrames = 0;
 nTries  = 0;
 
 
 % ....... Loop to try to achieve a good reconstruction, since the sift and match files exist already .....
 while (nFrames < minReconCams && nTries < maxReconTries ) 
     nTries        = nTries + 1;
     pause(3);     % this pause is necessary: seems like there's a clocktime as a seed to a random number generator
     tstart        = tic;
     command_str   = horzcat('VisualSFM sfm+import+sort ', images_fname, ' ', nvm_fname, ' ', 'my_matches.txt');
     [~,cmd_out]   = system(command_str, '-echo');
     t_el_sparse     = toc(tstart);

     fprintf('Elapsed time for sparse reconstruction: %d sec \n',t_el_sparse);
     log_info      = regexp(cmd_out,char(13), 'split');                                                                                   %#ok<NASGU>
                           % ..... accumulate stats info .....                       
     sifts           = dir('*.sift');           mats = dir('*.mat');          JPGS = dir('*.JPG');             jpgs = dir('*.jpg');
     b2Mb            = 1./1024./1024.;
     stats.sift_size = sum([sifts.bytes])*b2Mb;     stats.mat_size  = sum([mats.bytes]) * b2Mb;     stats.jpg_size  = max( sum([JPGS.bytes]), sum([jpgs.bytes])) * b2Mb;
     stats.t_sparse_total  = t_el_sift_plus_match + t_el_sparse;
     stats.t_sparse        = t_el_sparse;
     stats.t_sift          = t_el_sift;
     stats.t_match         = t_el_match;

     
      % ..... Break models apart; find number of frames and keep largest model if it uses more frames than previous attempts
     tstart = tic;
     [no_err, nFrames, ~, ~] = deconstruct_nvm(nvm_fbase, cache_dir, out_dir_top, 0);   % don't write results to a file
     err_check(~no_err,'.... Error breaking up original nvm file .....\n');
     t_el = toc(tstart);
     fprintf('Elapsed time for making single model file: %d sec \n',t_el);
     

     if (nFrames > stats.reconFrames)  % stats.reconFrames is initialized to 0; first time through always saves
     
         % ..... Step 6b: Copy the output log & nvm files from the first pass to the top reconstruction directory
         log_folder   = fullfile(vsfm_bin_dir, 'log', '*.log');
         list         = dir(log_folder);
         [~,rank]     = sort([list.datenum],'descend');
         newest_log   = list(rank(1)).name;
         no_err_last  = copyfile( fullfile(vsfm_bin_dir, 'log', newest_log), fullfile(out_dir_top,'logfile_recon_sparse.txt'),'f');            %#ok<NASGU>
         no_err_last  = copyfile( fullfile(nvm_fname), fullfile(out_dir_top, nvm_fname), 'f');                                                 %#ok<NASGU>



         % ..... Step 7: Break models apart for further reconstruction; keep only largest model
         tstart = tic;
         [no_err, nFrames, nPts, nOutliers] = deconstruct_nvm(nvm_fbase, cache_dir, out_dir_top, 1);  % this time write results to a file
         err_check(~no_err,'.... Error breaking up original nvm file .....\n');
         t_el = toc(tstart);
         fprintf('Elapsed time for making single model file: %d sec \n',t_el);

         stats.reconFrames =  nFrames;
         stats.reconPts    =  nPts;
         stats.outliers    =  nOutliers;
         stats.nTries      =  nTries;

     end
     
 end 
 
 
 
 
 % ..... Step 8a: Perform georegistration on largest only; rename .gcp file
 if (recon_type < 3)
     model_name_in  = horzcat(nvm_fbase, '_model1.nvm');
     model_name_out = horzcat(nvm_fbase, '_model1_gcp.nvm');
     gcp_name_in    = horzcat(model_name_in, '.gcp');
     no_err_last    = copyfile( in_truth_file, gcp_name_in, 'f');                                                                        %#ok<NASGU>
     command_str    = horzcat('VisualSFM sfm+loadnvm+gcp  ', model_name_in, ' ', model_name_out);
     tstart         = tic;
     [~,cmd_out]    = system(command_str, '-echo');
     t_el           = toc(tstart);
     log_info2        = regexp(cmd_out,char(13), 'split');
     [rmsErr, absErr] = trackAccuracy(log_info2);
     
     stats.rmsErr       = rmsErr;
     stats.absErr       = absErr;
     stats.t_gcp_sparse = t_el;
 
     % .... Step 8b: Copy output log & nvm files to sparse reconstruction directory
     log_folder   = fullfile(vsfm_bin_dir, 'log', '*.log');
     list         = dir(log_folder);
     [~,rank]     = sort([list.datenum],'descend');
     newest_log   = list(rank(1)).name;
     no_err_last  = copyfile( fullfile(vsfm_bin_dir, 'log', newest_log), fullfile(out_dir_sparse,'logfile_sparse_gcp.txt'),'f');         %#ok<NASGU>
     no_err_last  = copyfile( fullfile(model_name_out), fullfile(out_dir_sparse, model_name_out), 'f');                                  %#ok<NASGU>
 else
     stats.rmsErr       = 0;
     stats.absErr       = 0;
     stats.t_gcp_sparse = 0;
 end
 
 
 % ......Step 9a: Run Dense Reconstruction
 t_el_dense      = 0;
 if (recon_type < 2)
     dense_fname ='dense_recon_gcp.nvm';
     command_str = horzcat('VisualSFM sfm+loadnvm+pmvs+gcp ', model_name_in, ' ', dense_fname);  % use non-gcp nvm file as input
     tstart      = tic;
     [~,~]       = system(command_str, '-echo');
     t_el_dense  = toc(tstart);
     
     

     % .... Step 9b: Copy output log & nvm & ply files to dense reconstruction directory
     log_folder   = fullfile(vsfm_bin_dir, 'log', '*.log');
     list         = dir(log_folder);
     [~,rank]     = sort([list.datenum],'descend');
     newest_log   = list(rank(1)).name;
     no_err_last  = copyfile( fullfile(vsfm_bin_dir, 'log', newest_log), fullfile(out_dir_dense,'logfile_dense_gcp.txt'),'f');           %#ok<NASGU>
     no_err_last  = copyfile( fullfile(dense_fname), fullfile(out_dir_dense, dense_fname), 'f');                                         %#ok<NASGU>
     no_err_last  = copyfile( fullfile('*.ply'),  fullfile(out_dir_dense, '.'), 'f');                                                    %#ok<NASGU>

 end
 
 
 
 % .... Step 10: Collect final information (while in reconstruction cache directory) .....
nvms            = subdir('*.nvm');                  plys            = subdir('*.ply');
stats.nvm_size  = 0;                                stats.ply_size  = 0;

if(~isempty(nvms))
    stats.nvm_size  = sum([nvms.bytes]) * b2Mb;
end
if(~isempty(plys))
    stats.ply_size  = sum([plys.bytes]) * b2Mb;
end
stats.t_dense   = t_el_dense;

 
 % .... Return to original directory ....
 cd(save_dir);

end


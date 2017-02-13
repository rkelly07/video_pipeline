function [no_err] = check_VSFM_init_file(nGPU, vsfm_bin_dir)
 
%check_VSFM_init_file  Function to create temporary VSFM init file to run
%VisualSFM
%  
% Function will go to VisualSFM directory and:
% 1) make a temp copy of nv.ini (the input file that guides the reconstruction)
% 2) edit the temp copy to make certain the the correct number of gpu's is used
%
%==============================================================================


% ..... Step 1: Check for dir and file .... 
init_file = fullfile(vsfm_bin_dir, 'nv.ini');
no_err    = exist(vsfm_bin_dir, 'dir');
no_err    = exist(init_file, 'file') && no_err;
if (~no_err)
     fprintf('.... Found error in "nv.ini" filename or VisualSFM directory name .....\n');
     return;
end
 
% ..... Step 2: Save original copy, then open file and read in contents ....
init_file_safe = fullfile(vsfm_bin_dir, 'nv.ini.safe');
no_err = copyfile(init_file, init_file_safe, 'f'); 
if (~no_err)
    fprintf('.... Error saving safe version of nv.ini file .....\n');
    return;
end


% ..... Step 3: Edit nv.ini for line specifying number of gpus
%                  (for now use pre-edited files -dtmg)
init_file_cpu  = fullfile(vsfm_bin_dir, 'nv.ini.cpu');
init_file_gpu1 = fullfile(vsfm_bin_dir, 'nv.ini.gpu1');
init_file_gpu2 = fullfile(vsfm_bin_dir, 'nv.ini.gpu2');
if (nGPU == 0)
    no_err = copyfile(init_file_cpu, init_file);
else
    if (gpuDeviceCount >= nGPU);
     if (nGPU == 1)
        no_err = copyfile(init_file_gpu1, init_file);
     end
     if (nGPU == 2)
        no_err = copyfile(init_file_gpu2, init_file);
     end
    else % error: 
        no_err = 0;
        fprintf('...... Error: Requested %d GPUS, Found %d GPUs .......\n',nGPU, gpuDeviceCount);
        return;
    end
end
    



end


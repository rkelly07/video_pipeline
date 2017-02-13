function [out_dir_sparse, out_dir_dense] = create_dirs( out_dir_top, recon_type)

% ..... Create the directories for a reconstruction .....
if ~(exist(out_dir_top, 'dir'))
    no_err = mkdir(out_dir_top);
    err_check(~no_err, '.... Error creating top-level directory .....\n');
end

out_dir_sparse = fullfile(out_dir_top, 'sparse');
if ~( exist(out_dir_sparse, 'dir') )
    no_err         = mkdir( out_dir_sparse );
    err_check(~no_err, '.... Error creating sparse reconstruction directory .....\n');
end

% ..... If performing dense recon ....
out_dir_dense = ' ';
if (recon_type == 1 )    % revisit this! -dtmg
     out_dir_dense = fullfile(out_dir_top, 'dense');
     no_err        = mkdir( out_dir_dense );
     err_check(~no_err, '.... Error creating sparse reconstruction directory .....\n');
end

end


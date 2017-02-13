function writeStats( stats, fname_stats )

%-  Function to write stats structure to file for a batch run.
%-  Stored as ascii.

%- Note that, for now, each stats structure is saved individually immediately after
%- its reconstruction has completed
%- That is because a lot can go wrong with a 31-hour reconstruction,
%- so data loss is prevented.

if ~exist(fname_stats, 'file')
    write_header = true;
else
    write_header = false;
end


fid = fopen(fname_stats, 'at');     %- open/create file for appending in text mode

if (write_header)
  fprintf(fid,'%-45s %-12s %-12s %-12s %-12s %-12s %-12s  ...   %-12s %-12s %-12s %-12s %-12s %-12s  ...   %-12s %-12s %-12s %-12s %-12s  ...  %-12s %-12s %-12s %-12s %-12s %-12s %-12s \n\n',  ...
              'fname',       'mode',         'nGPU',          'seq_match',   'fRate Hz',      'res',          'nFrames',        ...
              'reconFrm',    'reconPts',     'nTries',        'rmsErr',      'absErr',        'outliers',                       ...
              'siftSize Mb', 'mat_size Mb',  'jpg_size Mb',   'nvm_size Mb', 'ply_size Mb',                                     ...
              't_setup(s)',  't_sift(s)',    't_match(s)',    't_sparse(s)', 't_sparse_tot',  't_gcp_sp(s)',  't_dense(s)');  
end


fprintf(fid,'%-45s %-12s %-12d %-12s %-12f [%-4d, %-4d] %-12d  ...   %-12d %-12d %-12d %-12f %-12f %-12d  ...   %-12f %-12f %-12f %-12f %-12f  ...  %-12f %-12f %-12f %-12f %-12f %-12f %-12f \n', ...
              stats.fname,       stats.mode,     stats.nGPU,         stats.seq_match,  stats.fRate,    stats.res, stats.nFrames, ...
              stats.reconFrames, stats.reconPts, stats.nTries,       stats.rmsErr,     stats.absErr,   stats.outliers,           ...
              stats.sift_size,   stats.mat_size, stats.jpg_size,     stats.nvm_size,   stats.ply_size,                           ...
              stats.t_setup,     stats.t_sift,   stats.t_match,      stats.t_sparse,   stats.t_sparse_total, stats.t_gcp_sparse, stats.t_dense );

fclose(fid);

end




function [ stats ] = initStats(nFiles, nBatches)



total = nFiles * nBatches;

% ..... Info about data set .....
stats(total).fname     = '';
stats(total).mode      = '';
stats(total).nGPU      = 0;
stats(total).seq_match = '';
stats(total).fRate     = 0;
stats(total).res       = 0;
stats(total).nFrames   = 0;

% .... Reconstruction results ....
%.................................
stats(total).reconFrames =  0;
stats(total).reconPts    =  0;
stats(total).rmsErr      =  0;
stats(total).absErr      =  0;
stats(total).outliers    =  0;
stats(total).nTries      =  0;


% .... Data footprint ....
stats(total).sift_size = 0;      
stats(total).mat_size  = 0;    
stats(total).jpg_size  = 0;
stats(total).nvm_size  = 0;         
stats(total).ply_size  = 0;


% ..... Timings .....
stats(total).t_setup   = 0;
stats(total).t_sift    = 0;
stats(total).t_match   = 0;
stats(total).t_sparse  = 0;
stats(total).t_sparse_total  = 0;
stats(total).t_gcp_sparse    = 0;
stats(total).t_dense         = 0;
end


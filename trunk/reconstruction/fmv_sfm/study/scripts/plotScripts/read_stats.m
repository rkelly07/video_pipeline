
function [stats_all] = read_stats( infile )

%infile = 'stats__25-Apr-2014_16-58-30.txt';
fid    = fopen(infile, 'r');

% initialize stats container
stats     = initStats(1,1);
nstats    = 0;


% read in top 2 lines of file (header)
textscan(fid,'%s',2,'delimiter', '\n');
stats.fname     = fscanf(fid,'%s',1);

while (~feof(fid))
    stats.mode      = fscanf(fid,'%s',1);
    stats.nGPU      = fscanf(fid,'%d',1);
    stats.seq_match = fscanf(fid,'%s',1);
    stats.fRate     = fscanf(fid,'%f',1);
    stats.res       = zeros(1,2);
    junk            = textscan(fid, '[%4d',1);
    stats.res(1)    = junk{1};
    junk            = textscan(fid, ',%4d]',1);
    stats.res(2)    = junk{1};
    stats.nFrames   = fscanf(fid, '%d',1);
    fscanf(fid,'%s',1);  % ... end first set of values 

    stats.reconFrames = fscanf(fid,'%d',1);
    stats.reconPts    = fscanf(fid,'%d',1);
    stats.nTries      = fscanf(fid,'%d',1);
    stats.rmsErr      = fscanf(fid,'%f',1);
    stats.absErr      = fscanf(fid,'%f',1);
    stats.outliers    = fscanf(fid,'%d',1);
    fscanf(fid,'%s',1);  % ... end second set of values 

    stats.sift_size   = fscanf(fid,'%f',1);
    stats.mat_size    = fscanf(fid,'%f',1);
    stats.jpg_size    = fscanf(fid,'%f',1);
    stats.nvm_size    = fscanf(fid,'%f',1);
    stats.ply_size    = fscanf(fid,'%f',1);
    fscanf(fid,'%s',1);  % ... end third set of values 

    stats.t_setup            = fscanf(fid,'%f',1);
    stats.t_sift             = fscanf(fid,'%f',1);
    stats.t_match            = fscanf(fid,'%f',1);
    stats.t_sparse           = fscanf(fid,'%f',1);
    stats.t_sparse_total     = fscanf(fid,'%f',1);
    stats.t_gcp_sparse       = fscanf(fid,'%f',1);
    stats.t_dense            = fscanf(fid,'%f',1);
    
    nstats = nstats + 1;
    stats_all(nstats) = stats;         %#ok<AGROW>
    
    stats     = initStats(1,1);
    stats.fname     = fscanf(fid,'%s',1);
end
          
fclose(fid);


return;
function res=segment_pixels(I,options)

N = size(I,1);
M = size(I,2);

% Number of superpixels coarse/fine.
N_sp=200;
N_sp2=1000;
% Number of eigenvectors.
N_ev=40;


% ncut parameters for superpixel computation
diag_length = sqrt(N*N + M*M);
par = imncut_sp;
par.int=0;
par.pb_ic=1;
par.sig_pb_ic=0.05;
par.sig_p=ceil(diag_length/50);
par.verbose=0;
par.nb_r=ceil(diag_length/60);
par.rep = -0.005;  % stability?  or proximity?
par.sample_rate=0.2;
par.nv = N_ev;
par.sp = N_sp;

[emag,ephase] = pbWrapper(I,par.pb_timing);
emag = pbThicken(emag);
par.pb_emag = emag;
par.pb_ephase = ephase;
clear emag ephase;

[Sp,Seg] = imncut_sp(I,par);
Sp2 = clusterLocations(Sp,ceil(N*M/N_sp2));

end
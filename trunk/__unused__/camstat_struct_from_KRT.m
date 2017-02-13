function camstat=camstat_struct_from_KRT(K,R,t)
camstat=[];
camstat.P=K*[R,t];
    camstat.K=K;
    camstat.R=R;
    camstat.t=t;

end
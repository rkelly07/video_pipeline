function [res,samples]=correct_coordinates(coordinates,t_start,t_finish,N)
res=(coordinates-t_start)/(t_finish-t_start)*N;
dt=(t_finish-t_start)/N;
samples=[t_start:dt:t_finish];
end
echo off
diary off
profile off
S = dbstatus;
save dbstatus S
clear
load dbstatus
dbstop(S)
delete dbstatus.mat
clear S
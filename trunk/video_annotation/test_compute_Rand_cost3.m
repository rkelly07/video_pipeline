load saved_userdata
load coreset_example D
val=saved_userdata.labels.values;
key=saved_userdata.labels.keys;
key=key{1};
t12=D.T12;
segments=t12(:,1);
score=[];
res=compute_Rand_cost(segments,{saved_userdata.labels},key);

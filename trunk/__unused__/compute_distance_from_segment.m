function res=compute_distance_from_segment(data,seg)
v=mean(data(:,seg),2);
res=sum(abs(bsxfun(@minus,data,v)).^2);
end
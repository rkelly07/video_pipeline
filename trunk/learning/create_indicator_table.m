function res=create_indicator_table(labels)
labels=labels(:);
res=[];
for i = 1:max(labels)
    res(:,i)=double(labels==i);
end
end
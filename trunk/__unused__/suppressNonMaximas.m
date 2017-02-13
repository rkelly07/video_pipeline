function P=suppressNonMaximas(P,rad)
kdtree=KDTreeSearcher(P.Location);
MAX_K=50;
nidxs=false(size(P.Location,1),1);
[idx,d]=kdtree.knnsearch(P.Location,'K',MAX_K);
for jj=1:size(P.Location,1)
    %     D=pdist2(P.Location(i:min(end,i+99),:),P.Location);
    %     [yy,idxs]=sort(D,2,'ascend');
    
    %     for j=1:size(D,2)
    %         jj=i;
    %         nb=yy(j,:)<rad;
    nb=d(jj,:)<rad;
    idxs2=idx(jj,nb);
    if numel(idxs2)==1
        nidxs(jj)=true;
    elseif max(P.Metric(idxs2(2:end)))<P.Metric(jj)||(max(P.Metric(idxs2(2:end)))==P.Metric(jj) && jj<min(idxs2(2:end)))
        nidxs(jj)=true;
    end
end
% end
nidxs=find(nidxs);
P=P(nidxs);
end
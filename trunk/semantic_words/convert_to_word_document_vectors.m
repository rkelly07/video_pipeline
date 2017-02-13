function [ws,ds]=convert_to_word_document_vectors(count_mtx,scale)
T=size(count_mtx,2);
K=size(count_mtx,1);
ws=[];
ds=[];
for t = 1:T
    for k=1:K
        count=round(count_mtx(k,t)*scale);
        if (count>0)
        ws=cat(1,ws,k*ones(count,1));
        ds=cat(1,ds,t*ones(count,1));
        end
    end
end
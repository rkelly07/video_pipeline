% I=randn(256,256,3);

% flt=fspecial('Gaussian',51,5);
% flt=sum(flt)/sum(flt(:));
% I=imfilter(I,flt,'replicate');
profile off;profile on
Is_good={};
Is_good{end+1}=coreset_tree.Data{1}.Keyframes{1};
Is_good{end+1}=coreset_tree.Data{1}.Keyframes{1};
Is_good{end+1}=coreset_tree.Data{2}.Keyframes{1};
Is_good{end+1}=coreset_tree.Data{100}.Keyframes{1};
Is_good{end+1}=coreset_tree.Data{110}.Keyframes{1};
Is_good{end+1}=coreset_tree.Data{40}.Keyframes{9};
Is_bad={};
Is_bad{end+1}=coreset_tree.Data{6}.Keyframes{2};
Is_bad{end+1}=coreset_tree.Data{6}.Keyframes{5};
Is_bad{end+1}=coreset_tree.Data{2}.Keyframes{5};
Is_bad{end+1}=coreset_tree.Data{10}.Keyframes{1};
Is_bad{end+1}=coreset_tree.Data{30}.Keyframes{5};
res=[];
for test=1:30
    vs_good=[];vs_bad=[];
    Is_good={Is_good{randperm(numel(Is_good))}};
    Is_bad={Is_bad{randperm(numel(Is_bad))}};
    for i=1:numel(Is_good)
        I=Is_good{i};
        [f,v]=compute_acrf_quality(I);
        vs_good(:,end+1)=v(:);
    end
    for i=1:numel(Is_bad)
        I=Is_bad{i};
        [f,v]=compute_acrf_quality(I);
        vs_bad(:,end+1)=v(:);
    end
    idx_good_train=1:(min(numel(Is_good)-1,ceil(numel(Is_good)*0.7)));
    idx_good_test=setdiff(1:(numel(Is_good)),idx_good_train);
    idx_bad_train=1:(min(numel(Is_bad)-1,ceil(numel(Is_bad)*0.7)));
    idx_bad_test=setdiff(1:(numel(Is_bad)),idx_bad_train);
    v1=conj(mean(vs_good(:,idx_good_train),2));
    v2=conj(mean(vs_bad(:,idx_bad_train),2));
    v=(v1-v2);v=v/norm(v);
    b=(mean(real(v(:)'*[vs_good]))+mean(real(v(:)'*[vs_bad])))/2;
    res1=[];
    for i=idx_good_test
        I=Is_good{i};
        [res1(end+1),~]=compute_acrf_quality(I,v,b);
    end
    for i=idx_bad_test
        I=Is_bad{i};
        [res1(end+1),~]=compute_acrf_quality(I,v,b);
    end
    res(end+1,:)=res1;
end
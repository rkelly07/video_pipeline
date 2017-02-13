% demonstrate complexity of the two main parts of FABMAP
sizes = 10;%[5 10 20 50 100 200 500 1000 2000];
times = [];
times2 = [];
for i = 1:numel(sizes)
    if (numel(times)>=i)
        continue;
    end
    hst2 = single(abs(randn(sizes(i),5000))+1);
    hst2 = hst2.*double(hst2<mean(hst2(:))*2);
    hst = bsxfun(@rdivide,hst2,sum(hst2,2));
    hst = single(hst);
    tic
    tree = mex_openfabmap('create_tree',hst);
    times(i) = toc;
    num_sample_entries = min(sizes(i),5);
        % idx = unique(ceil(1:size(hst2,1)/num_sample_entries:size(hst2,1)));
    idx = 1:num_sample_entries;
    tic
    res = mex_openfabmap('localize',tree,hst,hst(idx,:),[0.01, 0.001]);
    times2(i) = toc;
    disp([sizes(i), times(i),times2(i)]);
    loglog(sizes(1:numel(times)),times,sizes(1:numel(times)),times2);
    legend('Chow-Liu','FabMap Comparison')
    drawnow;
end

% ------------------------------------------------
% reformatted with stylefix.py on 2015/07/29 10:03

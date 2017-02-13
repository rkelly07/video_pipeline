function res = compare_page_closure(page,example,comparison_measure,tree)
res.costs = [];
switch(lower(comparison_measure))
    case 'l2'
        for i = 1:numel(page)
            res.costs(i) = norm(example.desc(:)-page{i}.desc(:));
        end
    case 'l2norm'
        for i = 1:numel(page)
            res.costs(i) = norm(example.desc(:)-page{i}.desc(:))/sqrt(norm(example.desc(:))*norm(page{i}.desc(:))+0.01);
        end
    case 'chowliu'
        
        example_desc = example.desc./sum(example.desc(:));
        example_desc(example_desc<0) = 0;
        example_desc = single(example_desc);
        
        page_desc = [];
        for i = 1:numel(page)
            page_desc(i,:)  = page{i}.desc;
        end
        page_desc = bsxfun(@rdivide,page_desc,sum(page_desc,2));
        page_desc(page_desc<0) = 0;
        page_desc = single(page_desc);
        
        log_probs = mex_openfabmap('localize',tree,page_desc,example_desc,[0.01 0.001]);
        for i = 1:numel(page)
            res.costs(i) = -log_probs(i);
        end
        res.costs
        %rel_costs = (res.costs-min(res.costs))./max(res.costs-min(res.costs))
%         
%         for i = 1:numel(page)
%             L2costs(i) = norm(example.desc(:)-page{i}.desc(:))/sqrt(norm(example.desc(:))*norm(page{i}.desc(:))+0.01);
%         end
%         L2costs
%         
%         keyboard
        
end
    
end
% ------------------------------------------------
% reformatted with stylefix.py on 2015/07/29 10:03

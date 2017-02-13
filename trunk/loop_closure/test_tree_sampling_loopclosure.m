% myclear, clc, clf

% if (~exist('keyframes','var'))
%     if (false)
%         load /media/UNTITLED/onboard_3/flight_results results
%         nodes = results.coreset_tree_data.nodes;
%         keyframes = results.coreset_tree_data.key_idx;
%         keyframe_images = coreset_tree_data.keyframes;
%         desc = coreset_tree_data.desc_coeff;
%         init_node = 55;
%     else
%         % load /home/rosman/Downloads/coreset_tree_data_75486.mat
%         load /media/rosman/LinuxUDF/Boston3/BostonTour3_720p_coreset_tree_356491_120_0506035512.mat
%         video_filename = '/media/rosman/LinuxUDF/BostonTour3.mp4';
%
%         % load /media/rosman/LinuxUDF/Boston3/BostonTour3_720p_coreset_results_356491_120_0506035512.mat
%         nodes = coreset_tree.Nodes;
%         init_node = find_last_node(coreset_tree);
%     end
% end

% TODO: mikhail
video_filename = '/Users/mikhail/MIT/DATA/idiary/source/stills/xstills.mp4';
load results/xstills_coreset_tree_369_20_0806131953.mat
load xstills_fabmap_tree_0811115840.mat
nodes = coreset_tree.Nodes;
last_node = find_last_leaf(coreset_tree);

%%
res = sample_tree(coreset_tree.Nodes,last_node,0.9);
additional_data = [];
additional_data.tree_nodes = nodes;
additional_data.init_node = last_node;
% comparison_measure = 'l2norm';
comparison_measure = 'ChowLiu';
example_num = last_node;
example_num2 = 1;
min_thresh = 10;
min_thresh2 = 0.5;

example = [];
example.num = coreset_tree.Data{example_num}.KeyframeAbsIdx(example_num2);
example.img = coreset_tree.Data{example_num}.Keyframes{example_num2};
example.desc = coreset_tree.Data{example_num}.Descriptors(example_num2,:);

%%
ts = [];
full_times = {};
num_pages = [];

% desc_dim = 66;
% VQ_dim = 10000;
% % load VQ
% load /scratch/rosman/persistent/d10000.mat;
% VQ = single(descriptor_representatives{1}(:,1:66));
% VW = ones(size(VQ(1,:)));

% TODO: mikhail
% load boston/d5000
load VQ_BostonTour3_30x_720p.mat
VQ_dim = size(VQ,1);
desc_dim = size(VQ,2);

h = mex_video_processing('init',video_filename,'SURF',VQ,VQ_dim,0,[640 480]);
keyframes = {};
desc = {};
keyframe_images = {};
for i = 1:numel(coreset_tree.Data)
    keyframes{i} = coreset_tree.Data{i}.KeyframeAbsIdx;
    nidx = coreset_tree.Data{i}.KeyframeAbsIdx;
    nidx2 = ceil((nidx(2:end)+nidx(1:(end-1)))/2);
    nidx = unique([nidx(:)',nidx2(:)']);
    ndesc = [];
    nkeyframes = {};
    desc{i} = coreset_tree.Data{i}.Descriptors;
    keyframe_images{i} = coreset_tree.Data{i}.Keyframes;
end
mex_video_processing('deinit',h);
results.minidxs = {};
results.images = {};
results.costs = {};
results.minpages = {};
results.timing = [];

%%
for attempts = 1:20
    example_num = max(randperm(numel(coreset_tree.Nodes),4));
    example_num2 = randperm(size(coreset_tree.Data{example_num}.Descriptors,1),1);
    %example = [];
    example.desc = coreset_tree.Data{example_num}.Descriptors(example_num2,:);
    example.img = coreset_tree.Data{example_num}.Keyframes{example_num2};
    example.num = coreset_tree.Data{example_num}.KeyframeAbsIdx(example_num2);
    minidxs = (example_num2);
    minpages = (example_num);
    images = {example.img};
    costs = (0);
    
    idxs = [];
    mincost = inf;
    lc = LoopClosure;
    lc.populate_tree_data(coreset_tree.Nodes,keyframes,desc,keyframe_images);
    fulltime = [];
    costs_hists{attempts} = [];
    t1 = cputime;
    for t = 1:2000
        lc.advance_timer();
        [page,idx] = lc.swap_random_page('tree',additional_data);
        if (ismember(idx,idxs))
            continue;
        end
        
        idxs(end+1) = idx;
        
        % TODO: mikhail
        %res = compare_page_closure(page,example,comparison_measure);
        res = compare_page_closure(page,example,comparison_measure,tree);
        
        % [yy,ii] = min(res.costs);
        img_nums = randperm(numel(res.costs));
        for ii = img_nums
            yy = res.costs(ii);
            if (yy<mincost)
                minidx = ii;
                minpage = idx;
                img = page{ii}.img;
                mincost = yy;
                if (mincost<min_thresh)
                    minidxs(end+1) = minidx;
                    minpages(end+1) = minpage;
                    images{end+1} = img;
                    costs(end+1) = mincost;
                    fulltime(end+1) = t;
                    break;
                end
            end
            costs_hists{attempts}(end+1) = mincost;
        end
        if 1%(mod(attempts,20)==1)
            disp(['Attempt: ',num2str(attempts),', Turn: ',num2str(t), ...
                ' searched: ',num2str(numel(idxs)),', cost: ',num2str(mincost)]);
        end
        should_break = false;
        if (mincost<min_thresh2)
            should_break = true;
        end
        
        if (mod(t,10)==1)
            subplot(2,3,1);imshow(img,[]);
            subplot(2,3,2);imshow(example.img,[]);
            
            subplot(2,3,4);plot(costs_hists{attempts});
            drawnow;
        end
        if (should_break)
            break;
        end
        % res = lc.getFrame(idx,1);
    end
    t2 = cputime;
    results.timing(end+1) = t2-t1;
    results.images{end+1} = images;
    results.minidxs{end+1} = minidxs;
    results.costs{end+1} = costs;
    results.minpages{end+1} = minpages;
    full_times{end+1} = fulltime;
    ts(end+1) = t;
    num_pages(end+1) = numel(idxs);
    
    if 1%(mod(attempts-1,20)==0 && attempts>1)
        
        disp(['mean(num_pages) = ',num2str(mean(num_pages)),' +/- ',num2str(std(num_pages)), ...
            ', avg timing: ',num2str(mean(results.timing)),' +/- ',num2str(std(results.timing))]);
    end
end

%%

% figure
subplot(2,3,5)
mlen = 0;
for i = 1:numel(costs_hists)
    mlen = max(mlen,numel(costs_hists{i}));
end
avgcosts = zeros(mlen,1);
wcosts = zeros(mlen,1);
axes
hold on;
for i = 1:numel(costs_hists)
    v = costs_hists{i}(:);
    if (~isempty(v))
        v((end+1):mlen) = v(end);
        avgcosts(1:mlen) = avgcosts(1:mlen)+v(:);
        wcosts(1:mlen) = wcosts(1:mlen)+1;
    end
    if (mod(i,10)==1)
        plot(1:numel(costs_hists{i}),costs_hists{i},'o-');
    end
end
hold off


% figure
subplot(2,3,6)
th = 10;
mask = wcosts>th;
avgcosts(mask) = avgcosts(mask)./wcosts(mask);
plot(avgcosts(wcosts>th));


% TODO: mikhail
% collage = [];
% for i = 1:10
%     uids = (results.minpages{i}*1e5+results.minidxs{i});
%     [uuids,ia,ic] = unique(uids);
%     ucosts = results.costs{i}(ia);
%     [~,sia] = sort(ucosts);
%     ia = ia(sia);
%     collage = cat(1,collage,draw_collage({results.images{i}{[1 ia(:)']}},[1 1+min(3,numel(ia))]));
% end
% figure
% imshow(collage/255,[])


% collage = draw_collage(images,[1 5]);
% imshow(collage/255,[]);
%

% ------------------------------------------------
% reformatted with stylefix.py on 2015/07/29 10:02


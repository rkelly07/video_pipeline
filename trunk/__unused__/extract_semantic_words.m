% rcnn_model = rcnn_load_model(rcnn_model_file, use_gpu);
function res=extract_semantic_words(im,verbose)
if (exist('verbose','var')==0)
    verbose=false;
end
% rcnn_model_file = '/home/rosman/rcnn/data/rcnn_models/voc_2012/rcnn_model_finetuned.mat';
rcnn_model_file = '/home/rosman/rcnn/data/rcnn_models/ilsvrc2013/rcnn_model.mat';
rcnn_dir='/home/rosman/rcnn';
% im = imread('/home/rosman/Pictures/Davis_Square.png');
use_gpu=true;
res=[];
dr=pwd;
cd(rcnn_dir)
global rcnn_model
if (isempty(rcnn_model))
rcnn_model = rcnn_load_model(rcnn_model_file, use_gpu);
end
cd(dr)
num_classes=numel(rcnn_model.classes);
res.hist=zeros(num_classes,1);
thresh = -1;
% thresh2=0;
thresh2=-1;
dets = rcnn_detect(im, rcnn_model, thresh);
all_dets = [];
for i = 1:length(dets)
    all_dets = cat(1, all_dets, ...
        [i * ones(size(dets{i}, 1), 1) dets{i}]);
end
[~, ord] = sort(all_dets(:,end), 'descend');
if (verbose)
    for i = 1:length(ord)
        score = all_dets(ord(i), end);
        if score < 0
            break;
        end
        cls = rcnn_model.classes{all_dets(ord(i), 1)};
        showboxes(im, all_dets(ord(i), 2:5));
        title(sprintf('det #%d: %s score = %.3f', ...
            i, cls, score));
        drawnow;
        pause;
    end
end
[~, ord] = sort(all_dets(:,end), 'descend');
for i = 1:length(ord)
    score = all_dets(ord(i), end);
    if score < thresh2
        break;
    end
    cls = rcnn_model.classes{all_dets(ord(i), 1)};
    res.hist(all_dets(ord(i), 1))=res.hist(all_dets(ord(i), 1))+1;
end
res.dets=all_dets;
end

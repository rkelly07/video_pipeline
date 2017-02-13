% [B2,semantic_state,detections]=get_semantic_words_vector(I,model,semantic_state)
% Inputs:
% I - the image
% model - the model to be used for detection. 
% semantic state - the state / detections from previous frame
% Outputs:
% B2 - a semantic words vector
% semantic_state - the "state" of the current frame, used for tracking, etc
% detections - the detections themselves, label/coordinates
% 
function [B2,semantic_state,detections]=get_semantic_words_vector(I,model,semantic_state)
%Draw the image


switch lower(model.type)
    case 'rcnn'
tmpdir=pwd;
cd(model.rcnn_path);
old_dets=[];
if (~isfield(semantic_state,'previous_det'))
    semantic_state.previous_det=[];
    semantic_state.previous_valid_det=[];
if (~(exist('rcnn_detect')))
   fprintf('Cannot access function or file rcnn_detect. Make sure you add rcnn folder to the project path'); 
end
dets = rcnn_detect(I, model.rcnn_model,model.thresh);
all_dets = [];
for i = 1:length(dets)
  all_dets = cat(1, all_dets, ...
      [i * ones(size(dets{i}, 1), 1) dets{i}]);
end
else
    old_dets = rcnn_detect(I, model.rcnn_model,model.thresh,semantic_state.previous_valid_det(:,2:5));
all_old_dets = [];
for i = 1:length(old_dets)
  all_old_dets = cat(1, all_old_dets, ...
      [i * ones(size(old_dets{i}, 1), 1) old_dets{i}]);
end
dets = rcnn_detect(I, model.rcnn_model,model.thresh);
all_dets = [];
for i = 1:length(dets)
  all_dets = cat(1, all_dets, ...
      [i * ones(size(dets{i}, 1), 1) dets{i}]);
end
if isempty(all_dets)
    all_dets=all_old_dets;
elseif isempty(all_old_dets)
    all_dets=all_dets;%#ok
else
all_dets=merge_rcnn_dets(all_dets,all_old_dets,model,I);
end


end
fprintf('combined detections: %d\n',size(all_dets,1));
semantic_state.previous_det=all_dets;
semantic_state.previous_valid_det=all_dets(all_dets(:,end)>model.thresh2,:);
[~, ord] = sort(all_dets(:,end), 'descend');

% Draw the detections
%{
h = figure;
for i = 1:length(ord)
  score = all_dets(ord(i), end);
  if score < 0
    break;
  end
  cls = model.rcnn_model.classes{all_dets(ord(i), 1)};

  try
      showboxes(I, all_dets(ord(i), 2:5));
  catch e
      warning(e.identifier, 'Error using showboxes');
  end
  title(sprintf('det #%d: %s score = %.3f', ...
      i, cls, score));
  drawnow;
  pause(0.1);
end

fprintf('No more detection with score >= 0\n');
close(h);
% Finish drawing detections
%}
idx=all_dets(:,end)>model.thresh2;
B2=zeros(model.dim,1);
for i=1:numel(idx);if (idx(i));B2(all_dets(i,1))=B2(all_dets(i,1))+1;end;end
cd(tmpdir)
detections=all_dets(idx,:);

    case 'fast-rcnn'
        tmpdir=pwd;
        cd([model.fast_rcnn_path '/matlab']);
        startup
        
        old_dets=[];

        if (~isfield(semantic_state,'previous_det'))
            semantic_state.previous_det=[];
            semantic_state.previous_valid_det=[];
            if (~(exist('fast_rcnn_im_detect')))
               fprintf('Cannot access function or file fast_rcnn_im_detect. Make sure you add fast-rcnn folder to the project path'); 
            end
            dets = fast_rcnn_im_detect(model.fast_rcnn_model, I);
            all_dets = [];
            for i = 1:length(dets)
              all_dets = cat(1, all_dets, ...
                  [i * ones(size(dets{i}, 1), 1) dets{i}]);
            end
        else
            old_dets = fast_rcnn_im_detect(model.fast_rcnn_model,I,semantic_state.previous_valid_det(:,2:5));
            all_old_dets = [];
            for i = 1:length(old_dets)
              all_old_dets = cat(1, all_old_dets, ...
                  [i * ones(size(old_dets{i}, 1), 1) old_dets{i}]);
            end
            dets = fast_rcnn_im_detect(model.fast_rcnn_model,I, boxes);
            all_dets = [];
            for i = 1:length(dets)
              all_dets = cat(1, all_dets, ...
                  [i * ones(size(dets{i}, 1), 1) dets{i}]);
            end
            if isempty(all_dets)
                all_dets=all_old_dets;
            elseif isempty(all_old_dets)
                all_dets=all_dets;%#ok
            else
            all_dets=merge_rcnn_dets(all_dets,all_old_dets,model,I);
            end
        end
        fprintf('combined detections: %d\n',size(all_dets,1));
        semantic_state.previous_det=all_dets;
        semantic_state.previous_valid_det=all_dets(all_dets(:,end)>model.thresh2,:);
        [~, ord] = sort(all_dets(:,end), 'descend');

        
% Draw the detections

h = figure;
for i = 1:length(ord)
  score = all_dets(ord(i), end);
  if score < 0
    break;
  end
  cls = model.fast_rcnn_model.classes{all_dets(ord(i), 1)};
  showboxes(I, all_dets(ord(i), 2:5));
  title(sprintf('det #%d: %s score = %.3f', ...
      i, cls, score));
  drawnow;
  pause(0.1);
end
close(h);
% Finish drawing detections
fprintf('No more detection with score >= 0\n');
idx=all_dets(:,end)>model.thresh2;
B2=zeros(model.dim,1);
for i=1:numel(idx);if (idx(i));B2(all_dets(i,1))=B2(all_dets(i,1))+1;end;end
cd(tmpdir)
detections=all_dets(idx,:);
        
        
case 'places'
[scores, maxlabel] = matcaffe_places(double(I), true);
B2=scores(:)*model.coefficient;
detections={};
    case 'lsda'
        try
[B2,detections]=detect10k_vector(model.rcnn_model, model.rcnn_feat, I);
        catch
% cd(model.rcnn_path)
  startup          
[B2,detections]=detect10k_vector(model.rcnn_model, model.rcnn_feat, I);
        end
end
end

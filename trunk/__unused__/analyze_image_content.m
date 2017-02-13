% prev_img - for motion estimation
function img_desc = analyze_image_content(timestamp,img,prev_img,desc,level,old_img_desc)
if (exist('level','var')==0)
    level = 0;
end

% Read a video frame and run the detector.
% videoFileReader = vision.VideoFileReader('visionface.avi');
% videoFrame = step(videoFileReader);

% Draw the returned bounding box around the detected face.
% videoOut = insertObjectAnnotation(videoFrame,'rectangle',bbox,'Face');
% figure, imshow(videoOut), title('Detected face');
if (exist('old_img_desc','var')==0)
    img_desc = [];
else
    img_desc = old_img_desc;
    
end
img_desc.face_bboxes = [];
if (isfield(img_desc,'motionInfo')==0)
    img_desc.motionInfo = [];
end
% img_desc.face_bboxes = [];
if (isempty(timestamp))
    img_desc.timestamp = old_img_desc.timestamp;
else
    img_desc.timestamp = timestamp;
end
img_desc.analysis_importance = 0;
img_desc.motion_importance = 0;
try
    if (level>0)
        faceDetector = vision.CascadeObjectDetector();
        img_desc.face_bboxes = step(faceDetector, img);
        img_desc.num_faces = 0;
        if (~isempty(img_desc.face_bboxes))
            img_desc.num_faces = size(img_desc.face_bboxes,1);
            % TODO: handle distribution
        end
        % use runObjectness
        % optic flow
        if (~isempty(prev_img))
            alpha = 0.012;
            ratio = 0.75;
            minWidth = 20;
            nOuterFPIterations = 7;
            nInnerFPIterations = 1;
            nSORIterations = 30;
            
            para = [alpha,ratio,minWidth,nOuterFPIterations,nInnerFPIterations,nSORIterations];
            
            % this is the core part of calling the mexed dll file for computing optical flow
            % it also returns the time that is needed for two-frame estimation
            
            % [vx,vy,warpI2] = Coarse2FineTwoFrames(img,prev_img,para);
            [vx,vy,warpI2] = Coarse2FineTwoFrames(img(1:2:end,1:2:end,:),prev_img(1:2:end,1:2:end,:),para);
            vx = imresize(vx,size(img(:,:,1)))*2;
            vy = imresize(vy,size(img(:,:,1)))*2;
            
            img_desc.med_vx = median(vx(:));
            img_desc.med_vy = median(vy(:));
            img_desc.vx2 = vx-img_desc.med_vx;img_desc.vy2 = vy-img_desc.med_vy;
            p = makeGBVSParams();
            p.useIttiKochInsteadOfGBVS = 1;
            if ~isempty(img_desc.motionInfo)
                [img_desc.gbvs,img_desc.motionInfo] = gbvs(img,p,img_desc.motionInfo);
            else
                [img_desc.gbvs,img_desc.motionInfo] = gbvs(img);
            end
            img_desc.analysis_importance = mean(img_desc.gbvs.master_map(:)>0.5);
            motion_v = mean(sqrt((vx(:)/size(img,2)).^2+(vy(:)/size(img,2)).^2));
            img_desc.motion_importance = 1/(motion_v+0.1)^2;
            % [out,img_desc.motionInfo] = gbvs(img,gbfs_param,img_desc.motionInfo)
        end
    end
catch e
    1;
end
img_desc.old_img_desc = old_img_desc;
img_desc.level = level;
img_desc.img = img;
img_desc.prev_img = prev_img;
img_desc.desc_coeff = desc;
end

% ------------------------------------------------
% reformatted with stylefix.py on 2014/09/03 16:26

% ------------------------------------------------
% reformatted with stylefix.py on 2014/09/08 12:02

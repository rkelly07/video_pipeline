function res = classify_VOC(DATADIR,min_image_num,max_image_num,OUT_DIR)

VERBOSE=false;
addpath([DATADIR,filesep,'VOC2012',filesep,'JPEGImages']);
addpath([DATADIR,filesep,'VOC2012',filesep,'Annotations']);

VOC_CLASSES = {'aeroplane','bicycle','bird','boat','bottle','bus', 'car','cat','chair', ...
    'cow','diningtable','dog','horse','motorbike','person','pottedplant','sheep','sofa', ...
    'train','tvmonitor','person.head','person.hand','person.foot'};

FILENAMES = dir([DATADIR,filesep,'VOC2012',filesep,'JPEGImages']);
FILENAMES = {FILENAMES(3:end).name};
max_image_num2=min(max_image_num,numel(FILENAMES));
out_filename=[OUT_DIR,'VOC_descriptors_',num2str(min_image_num),'_',num2str(max_image_num2)];
% init
% descriptors
D_saved={};
D = {};
d_ind = 1;
object_instance_cnt=0;
object_instance_types=[];
%%
for i = min_image_num:max_image_num2
    if (VERBOSE)
        disp(repmat('-',1,80))
    end
    filename = FILENAMES{i}(1:end-4);
    if (VERBOSE)
        disp([num2str(i) ':' filename])
    end
    
    %% get features
    img_filename = [filename '.jpg'];
    
    I = imread(img_filename);
    Ihsv = double(rgb2hsv(I));
    H = Ihsv(:,:,3);
    
    try
        imshow(I)
        title(num2str(i))
        hold on
    catch
    end
    
    % get SURF features
    % default params: threshold = 1000, num octaves = 3
    P = detectSURFFeatures(H,'MetricThreshold',100);
    [F,P] = extractFeatures(H,P);
    positions=P.Location;
    num_features = size(F,1);
    if (VERBOSE)
        disp(['num features = ' num2str(num_features)])
    end
    
    %% get annotated classes
    xml_filename = [filename '.xml'];
    
    % create xml structure
    xml_struct = parseXML(xml_filename);
    
    % find all "object" items
    objects = xml_struct.Children(ismember({xml_struct.Children.Name},'object'));
    
    % for person class only, find all "part" items
    parts = struct([]);
    for j = 1:length(objects)
        parts = objects(j).Children(ismember({objects(j).Children.Name},'part'));
        
        % prepend parent class name to all parts
        class_name = get_class_name(objects(j));
        for k = 1:length(parts)
            parts(k).Children(ismember({parts(k).Children.Name},'name')).Children.Data = ...
                [class_name '.' get_class_name(parts(k))];
        end
        
    end
    
    % store all objects in single object
    objects = cat(2,objects,parts);
    
    num_objects = length(objects);
    if (VERBOSE)
        disp(['num objects = ' num2str(num_objects)])
    end
    
    %% save classified features
    
    % extend classified descriptor cell array
    D = cat(1,D,cell(num_features,1));
    is_background=true(1,size(P,1));
    % iterate over each class to determine the class of the descriptor
    for c = 1:length(objects)
        
        colormap = hsv(length(objects));
        
        object = objects(c);
        class_name = get_class_name(object);
        class_number=find(ismember(VOC_CLASSES,class_name));
        [xmin,ymin,xmax,ymax] = get_bnd_box(object);
        
        try
            % plot bounding box
            rectangle('Position',[xmin,ymin,(xmax-xmin),(ymax-ymin)],'EdgeColor',colormap(c,:))
        catch
        end
        found_descriptors_for_object=false;
        feature_in_object=false(size(P,1),1);
        for feature_ind = 1:size(P,1)
            
            % init current descriptor
            curr_descriptor = struct;
            curr_descriptor.ImageIndex = i;
            curr_descriptor.Descriptor = F(feature_ind,:);
            curr_descriptor.Class = 0;
            curr_descriptor.ClassName = 'NONE';
            curr_descriptor.RelativePosition = [];
            curr_descriptor.UniqueID=0;
%             p = P(feature_ind).Location;
            x = positions(feature_ind,1);
            y = positions(feature_ind,2);
            
            % descriptor is in bounding box
            if x>=xmin && x<=xmax && y>=ymin && y<=ymax
                curr_descriptor.Class = class_number;
                curr_descriptor.ClassName = class_name;
                is_background(feature_ind)=false;
                if (~found_descriptors_for_object)
                    found_descriptors_for_object=true;
                    object_instance_cnt=object_instance_cnt+1;
                    object_instance_types(object_instance_cnt)=curr_descriptor.Class;
                end
                curr_descriptor.UniqueID=object_instance_cnt;
                x_rel = (x-xmin)/(xmax-xmin);
                y_rel = (y-ymin)/(ymax-ymin);
                curr_descriptor.RelativePosition = [x_rel y_rel];
                feature_in_object(feature_ind)=true;
                
            end
            
            % push descriptor  to list
            if (curr_descriptor.Class~=0 || c==length(objects))
            D{d_ind} = curr_descriptor;
            d_ind = d_ind+1;
            end
            
        end
        try
            % plot feature
            plot(positions(feature_in_object,1),positions(feature_in_object,2),'x','Color',colormap(c,:))
        catch
        end
        
    end
    if (d_ind>10000) || i==max_image_num
        D_saved={D_saved{:},D{:}};
        D={};
        d_ind=1;
    end
    if (mod(i,5)==0)
        disp([num2str(numel(D_saved)+d_ind),' descriptors']);
    end
    % remove empty cells
    %     empty_cells = cellfun(@isempty,D);
    %     D(empty_cells) = [];
    if (mod(i,30000)==0) || i==max_image_num
        
        D_saved={D_saved{:},D{:}};
        D={};
        d_ind=1;
        try
            save('-v7.3',out_filename,'D_saved');
        catch
        end
    end
    try
        hold off;
        drawnow
    catch
    end
end
D_saved={D_saved{:},D{:}};
res.D=D_saved;
res.object_instance_types=object_instance_types;
if (VERBOSE)
    disp('Done!')
end


function name = get_class_name(object)

name = object.Children(ismember({object.Children.Name},'name')).Children.Data;


function [xmin,ymin,xmax,ymax] = get_bnd_box(object)

bndbox = object.Children(ismember({object.Children.Name},'bndbox'));
xmin = str2double(bndbox.Children(ismember({bndbox.Children.Name},'xmin')).Children.Data);
ymin = str2double(bndbox.Children(ismember({bndbox.Children.Name},'ymin')).Children.Data);
xmax = str2double(bndbox.Children(ismember({bndbox.Children.Name},'xmax')).Children.Data);
ymax = str2double(bndbox.Children(ismember({bndbox.Children.Name},'ymax')).Children.Data);


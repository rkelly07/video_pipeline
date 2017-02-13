function res=collect_B3DO_BOWs(res,data_dir,num_workers,worker_id,max_image,descriptor_aggregators)
% directory_names=dir([data_dir,filesep,'Annotations']);
image_ext='png';
i=0;
save_global=false;
save_global_matrix=false;
save_bags_of_words=false;

%%
res.bows=[];res.bows_class=[];
res.descriptors=[];
res.labels=[];
intermediate_descriptors=[];
intermediate_descriptors_cnt=0;
intermediate_labels=[];
intermediate_IDs=[];
intermediate_bows=[];
intermediate_bows_class=[];
object_instance_cnt=0;
object_instance_types=[];
res.D_saved={};
finished=false;
VERBOSE=false;
USE_SPATIAL_COORDINATES=false;
if (isfield(res,'VERBOSE_IMAGE'))
    VERBOSE_IMAGE=res.VERBOSE_IMAGE;
else
    % VERBOSE_IMAGE=false;
    VERBOSE_IMAGE=true;
end
out_filename=[data_dir,filesep,'res_B3DO_',num2str(num_workers),'_',num2str(worker_id),'.mat'];
% for i_dir=1:numel(directory_names)
dir_name=[data_dir,filesep,'Annotations'];
%     if (strcmp(directory_names(i_dir).name,'.')||strcmp(directory_names(i_dir).name,'..'))
%         continue;
%     end
if exist(dir_name,'dir')
    xml_spec=[dir_name,filesep,'*.xml'];
    xml_files=dir(xml_spec);
    
    if (numel(xml_files)>0)
        for i_xml=1:numel(xml_files)
            per_file_descriptors_cnt=0;
            per_file_descriptors=[];
            per_file_labels=[];
            per_file_IDs=[];
            per_file_bows=[];
            per_file_bows_class=[];
            xml_filename=[dir_name,filesep,xml_files(i_xml).name];
            [xml_path,xml_name,xml_ext]=fileparts(xml_files(i_xml).name);
            img_spec=[data_dir,filesep,'KinectColor',filesep,xml_name,'.',image_ext];
            % for running the gathering in parallel
            prime_number=99991;
            name_simple_hash=simple_hash(img_spec,prime_number);
            if mod(name_simple_hash-1,num_workers)+1~=worker_id
                continue;
            end
            object_D_mtx=[];
            
            if exist(img_spec,'file')
                %                     if (rand(1)<0.98)
                %                         continue; % for debug only..
                %                     end
                try
                    cache_file_name=[res.cache_files_dir,filesep,'c',num2str(simple_hash(img_spec(1:5:end),99991)),num2str(simple_hash(img_spec(2:5:end),99991)),num2str(simple_hash(img_spec(3:5:end),99991)),num2str(simple_hash(img_spec(4:5:end),99991)),num2str(simple_hash(img_spec(5:5:end),99991)),'.mat'];
                catch
                end
                if (isfield(res,'cache_files_dir') && ~isempty(res.cache_files_dir) && exist(cache_file_name,'file'))
                    try
                        load(cache_file_name)
                    catch
                        continue;
                    end
                    i=i+1;
                    
                else
                    try
                        I=imread(img_spec);
                    catch
                        continue;
                    end
                    
                    % create xml structure
                    xml_struct = parseXML(xml_filename);
                    
                    % find all "object" items
                    objects = xml_struct.Children(ismember({xml_struct.Children.Name},'object'));
                    if (size(I,3)==1)
                        H=I;
                    else
                        Ihsv = double(rgb2hsv(I));
                        H = Ihsv(:,:,1);
                        V = Ihsv(:,:,3);
                    end
                    
                    % get SURF features
                    % default params: threshold = 1000, num octaves = 3
                    dense_sift=true;
                    if (dense_sift)
                        STEP=7;[xx,yy]=meshgrid(1:STEP:size(I,2),1:STEP:size(I,1));
                        [F,P] = extractFeatures(V,[xx(:),yy(:)],'Method','SURF');
                        positions=P.Location;
                    else
                        P = detectSURFFeatures(H,'MetricThreshold',100);
                        [F,P] = extractFeatures(V,P);
                        positions=P.Location;
                    end
                    %                     [F2,P2] = extractFeatures(H,P);
                    %                     [Il,Ia,Ib]=rgb2lab(I(:,:,1)
                    F2=[];
                    if (USE_SPATIAL_COORDINATES)
                    F2(:,1)=interp2(Ihsv(:,:,1),positions(:,1),positions(:,2));
                    F2(:,2)=interp2(Ihsv(:,:,2),positions(:,1),positions(:,2));
                    end
                    F=[F,F2];
                    num_features = size(F,1);
                    if (VERBOSE)
                        disp(['num features = ' num2str(num_features)])
                    end
                    i=i+1;
                    if (VERBOSE_IMAGE)
                        try
                            imshow(I)
                            title(num2str(i))
                            hold on
                        catch
                        end
                    end
                    %% get annotated classes
                    %                     xml_filename =  [DATADIR,filesep,'VOC2012',filesep,'Annotations',filesep,filename '.xml'];
                    
                    % create xml structure
                    %                     xml_struct = parseXML(xml_filename);
                    
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
                    %                     if (save_global)
                    %                         D = cat(1,D,cell(num_features,1));
                    %                     end
                    is_background=true(1,size(P,1));
                    % iterate over each class to determine the class of the descriptor
                    %                     curr_descriptor0 = struct;
                    %                     curr_descriptor0.Class = 0;
                    %                     curr_descriptor0.ClassName = 'NONE';
                    %                     curr_descriptor0.RelativePosition = [];
                    %                     curr_descriptor0.UniqueID=0;
                    %                     curr_descriptor0.ImageIndex = i;
                    
                    for c = 1:length(objects)
                        
                        
                        object = objects(c);
                        class_name = get_class_name(object);
                        %                         class_number=str2num(class_name(2:end));
                        prime_number=9973;
                        class_number=simple_hash(class_name,prime_number);
                        
                        [xmin,ymin,xmax,ymax] = get_bnd_box(object);
                        if (VERBOSE_IMAGE)
                            colormap = hsv(length(objects));
                            try
                                % plot bounding box
                                rectangle('Position',[xmin,ymin,(xmax-xmin),(ymax-ymin)],'EdgeColor',colormap(c,:))
                            catch
                            end
                        end
                        found_descriptors_for_object=false;
                        feature_in_object=false(size(P,1),1);
                        object_Ds={};
                        object_D_mtx_cnt=0;
                        xs=positions(:,1);
                        ys=positions(:,2);
                        is_inside=xs>=xmin&xs<=xmax&ys>=ymin&ys<=ymax;
                        feature_inds=find(is_inside);
                        for feature_ind_ = 1:numel(feature_inds)
                            feature_ind=feature_inds(feature_ind_);
                            % init current descriptor
                            %                             curr_descriptor=curr_descriptor0;
                            %                             curr_descriptor.Descriptor = F(feature_ind,:);
                            %             p = P(feature_ind).Location;
                            x = positions(feature_ind,1);
                            %                             if x>=xmin && x<=xmax
                            y = positions(feature_ind,2);
                            
                            % descriptor is in bounding box
                            %                                 if y>=ymin && y<=ymax
                            %                                     curr_descriptor.Class = class_number;
                            %                                     curr_descriptor.ClassName = class_name;
                            is_background(feature_ind)=false;
                            if (~found_descriptors_for_object)
                                found_descriptors_for_object=true;
                                object_instance_cnt=object_instance_cnt+1;
                                object_instance_types(object_instance_cnt)=class_number;
                            end
                            %                                     curr_descriptor.UniqueID=object_instance_cnt;
                            x_rel = (x-xmin)/(xmax-xmin);
                            y_rel = (y-ymin)/(ymax-ymin);
                            RelativePosition = [x_rel y_rel];
                            feature_in_object(feature_ind)=true;
                            %                                     object_Ds{end+1}=curr_descriptor;
                            object_D_mtx_cnt=object_D_mtx_cnt+1;
                            object_D_mtx(:,object_D_mtx_cnt)=F(feature_ind,:);
                            
                            if (save_global_matrix) || ~isempty(descriptor_aggregators)
                                if (class_number~=0 || c==length(objects))
                                    per_file_descriptors_cnt=per_file_descriptors_cnt+1;
                                    per_file_descriptors(:,per_file_descriptors_cnt)=F(feature_ind,:);
                                    per_file_labels(:,per_file_descriptors_cnt)=class_number;
                                    per_file_IDs(:,per_file_descriptors_cnt)=object_instance_cnt;
                                    
                                end
                            end
                            
                            %                                 end
                            %                             end
                            % push descriptor  to list
                            %                             if (save_global)
                            %                                 if (curr_descriptor.Class~=0 || c==length(objects))
                            %                                     D{d_ind} = curr_descriptor;
                            %                                     d_ind = d_ind+1;
                            %                                 end
                            %                             end
                            
                        end
                        if save_bags_of_words
                            [bow,bow_stats]=compute_bag_of_words(object_D_mtx(:,1:object_D_mtx_cnt),descriptor_representatives);
                            if (bow_stats.sum>5)
                                per_file_bows(:,end+1)=bow;
                                per_file_bows_class(:,end+1)=class_number;
                            end
                        end
                        if (VERBOSE_IMAGE)
                            try
                                % plot feature
                                plot(positions(feature_in_object,1),positions(feature_in_object,2),'x','Color',colormap(c,:))
                            catch
                            end
                        end
                        
                    end
                    per_file_descriptors=single(per_file_descriptors);
                    intermediate_labels=single(intermediate_labels);
                    per_file_IDs=single(per_file_IDs);
                    try
                        if (isfield(res,'cache_files_dir') && ~isempty(res.cache_files_dir))
                            %save(cache_file_name,'F','P','positions','num_features','H','xml_struct','objects','I','per_file_bows','per_file_descriptors','per_file_labels','per_file_IDs','objects');
                            save(cache_file_name,'positions','num_features','I','per_file_bows','per_file_descriptors','per_file_labels','per_file_IDs');
                        end
                    catch
                    end
                    
                end
                new_desc_idx=[1:size(per_file_descriptors,2)];
                if (~isempty(per_file_descriptors))
                    intermediate_descriptors(:,intermediate_descriptors_cnt+new_desc_idx)=per_file_descriptors;
                    intermediate_labels(:,intermediate_descriptors_cnt+new_desc_idx)=per_file_labels;
                    intermediate_IDs(:,intermediate_descriptors_cnt+new_desc_idx)=per_file_IDs;
                    intermediate_descriptors_cnt=intermediate_descriptors_cnt+numel(new_desc_idx);
                end
                if (mod(i,1200)==0)|| i>=max_image
                    disp(i)
                    if save_bags_of_words
                        res.bows=[res.bows,intermediate_bows];
                        res.bows_class=[res.bows_class,intermediate_bows_class];
                    end
                    if (save_global_matrix)
                        res.descriptors=[res.descriptors,intermediate_descriptors(:,1:intermediate_descriptors_cnt)];
                        res.labels=[res.labels,intermediate_labels(:,1:intermediate_descriptors_cnt)];
                    end
                    % Here we can insert SGD, coresets, etc
                    if (~isempty(descriptor_aggregators))
                        for aggregator_idx=1:length(descriptor_aggregators)
                            res=descriptor_aggregators{aggregator_idx}(res,intermediate_descriptors(:,1:intermediate_descriptors_cnt),intermediate_labels(:,1:intermediate_descriptors_cnt),intermediate_IDs(:,1:intermediate_descriptors_cnt));
                        end
                    end
                    %                         intermediate_descriptors=[];
                    %                         intermediate_IDs=[];
                    %                         intermediate_labels=[];
                    intermediate_descriptors_cnt=0;
                    intermediate_bows=[];
                    intermediate_bows_class=[];
                    
                end
                %                     if (save_global)
                %                         if (d_ind>20000)
                %                             res.D_saved={res.D_saved{:},D{:}};
                %                             D={};
                %                             d_ind=1;
                %                         end
                %                     end
                %     if (mod(i,5)==0)
                %         disp([num2str(numel(D_saved)+d_ind),' descriptors']);
                %     end
                % remove empty cells
                %     empty_cells = cellfun(@isempty,D);
                %     D(empty_cells) = [];
                %                     if (mod(i,15000)==0)|| i>=max_image
                %
                %                         D_saved={D_saved{:},D{:}};
                %                         D={};
                %                         d_ind=1;
                %                         try
                %                             save('-v7.3',out_filename,'D_saved','res');
                %                         catch
                %                         end
                %                         if (i>=max_image)
                %                             break;
                %                         end
                %                     end
                if (i>=max_image)
                    finished=true;
                    break;
                end
                if (VERBOSE_IMAGE)
                    try
                        hold off;
                        drawnow
                    catch
                    end
                end
            end
            if (finished)
                break;
            end
        end
        %             if (finished)
        %                 break;
        %             end
        
    end
    %         if (finished)
    %             break;
    %         end
    
end
if (~isempty(intermediate_labels))
    if (~isempty(descriptor_aggregators) && intermediate_descriptors_cnt>0)
        for aggregator_idx=1:length(descriptor_aggregators)
            res=descriptor_aggregators{aggregator_idx}(res,intermediate_descriptors(:,1:intermediate_descriptors_cnt),intermediate_labels(:,1:intermediate_descriptors_cnt),intermediate_IDs(:,1:intermediate_descriptors_cnt));
        end
    end
    
end
end
% end

function name = get_class_name(object)

name = object.Children(ismember({object.Children.Name},'name')).Children.Data;
end

function [xmin,ymin,xmax,ymax] = get_bnd_box(object)

bndbox = object.Children(ismember({object.Children.Name},'bndbox'));
xmin = str2double(bndbox.Children(ismember({bndbox.Children.Name},'xmin')).Children.Data);
ymin = str2double(bndbox.Children(ismember({bndbox.Children.Name},'ymin')).Children.Data);
xmax = str2double(bndbox.Children(ismember({bndbox.Children.Name},'xmax')).Children.Data);
ymax = str2double(bndbox.Children(ismember({bndbox.Children.Name},'ymax')).Children.Data);
end

classdef observations_db < handle
    properties
        cfg
        conn
        colnames
        tablenames
        db_version=1;
    end
    methods
        function obj=observations_db(cfg)
            obj.cfg=cfg;
            obj.colnames.app_tag_colnames.insertion={'label_id','frame','stream'};
            obj.colnames.app_label_colnames.insertion={'title','time_added','time_updated','current_version'};
            obj.colnames.app_class_mapping_colnames.insertion={'class_id','class_name'};
            obj.colnames.app_region_colnames.insertion={'frame','x1','x2','y1','y2','label_version','label_id','scene_id','confidence'};
            obj.colnames.app_scene_colnames.insertion={'path','timestamp','frames','frame_rate','width','height','time_taken','time_added','thumbnail'};
            obj.tablenames.tag_table_name='app_tag';
            obj.tablenames.label_table_name='app_label';
            obj.tablenames.region_table_name='app_region';
            obj.tablenames.scene_table_name='app_scene';
            obj.tablenames.user_selection_table_name='app_user_selection';
            
            obj.tablenames.coreset_table_name = 'app_coreset';
            obj.colnames.app_coreset_colnames.insertion={'scene_id', 'coreset_tree_path', 'coreset_results_path', 'simple_coreset_path'};
            
            %added for test
            obj.tablenames.test_table_name = 'app_test';
            obj.colnames.app_test_colnames.insertion={'text_col', 'int_col', 'float_col', 'time_col', 'next_text_col'};
            
            %synthetic_data_table
            obj.tablenames.synthetic_region_table_name = 'app_synthetic_region';
            obj.colnames.app_synthetic_region_colnames.insertion={'frame','x1', 'x2', 'y1', 'y2', 'class_id', 'confidence', 'importance', 'scene_id'};
        end
        
        function open_db(obj)
            %following line should be added in server the first time
%             javaclasspath('/home/drl-leopard/psql-connector/postgresql-9.4-1201.jdbc4.jar');
            obj.conn= database(obj.cfg.db_name',obj.cfg.username,obj.cfg.password,'Vendor','PostgreSQL','Server',obj.cfg.server);
        end
        function close_db(obj)
            close(obj.conn);
        end
        function clear_db(obj)
            exec(obj.conn,['delete from ',obj.tablenames.tag_table_name]);
            exec(obj.conn,['delete from ',obj.tablenames.label_table_name]);
            exec(obj.conn,['delete from ',obj.tablenames.region_table_name]);
            exec(obj.conn,['delete from ',obj.tablenames.scene_table_name]);
            exec(obj.conn,['delete from ',obj.tablenames.user_selection_table_name]);
        end
        function get_bow_time_vector(stream_id,frame_id)
            %..
        end
        function get_tags_for_frame(stream_id,frame_id)
            %curs = exec(conn,'select productDescription from productTable');
        end
        function str=format_time_str(obj,time)
            str=datestr(time,'yyyy-mm-dd HH:MM:SS');
        end
        function add_label(obj,label)
            table_name='app_label';
            colnames=obj.colnames.app_label_colnames.insertion;
            t=format_time_str(obj,now);
            time_added=t;
            time_updated=t;
            weights=[1];
            thresholds=[1];
            current_version=obj.db_version;
            data={label.title,time_added,time_updated,current_version};
            
            datainsert(obj.conn,table_name,colnames,data);
        end
        function add_class_name_mapping(obj,label)
            table_name='app_class_mapping';
            colnames=obj.colnames.app_class_mapping_colnames.insertion;
            t=format_time_str(obj,now);
            time_added=t;
            time_updated=t;
%             weights=[1];
%             thresholds=[1];
            current_version=obj.db_version;
            data={num2str(label.number),label.title};
            
            datainsert(obj.conn,table_name,colnames,data);
        end
        
        function set_tags_for_frame(obj,stream_id,frame_id,tag_id)
            table_name='app_tag';
            colnames=obj.colnames.app_tag_colnames.insertion;
            data={tag_id,frame_id,stream_id};
            datainsert(obj.conn,table_name,colnames,data);
        end
        
        function add_detection_frame(obj,detection)
            table_name='app_region';
            colnames=obj.colnames.app_region_colnames.insertion;
            cur=exec(obj.conn,['select id from ',obj.tablenames.label_table_name,' where title = ''',detection.label,'''']);
            cur=fetch(cur,1);
            cur2=exec(obj.conn,['select id from ',obj.tablenames.scene_table_name,' where path = ''',detection.scene_label,'''']);
            cur2=fetch(cur2,1);
            scene_id=cur2.Data{1};
            label_id=cur.Data{1};
            label_version=obj.db_version;
            data={detection.frame,detection.x1,detection.x2,detection.y1,detection.y2,label_version,label_id,scene_id,detection.confidence};
            datainsert(obj.conn,table_name,colnames,data);
        end
        
        function add_detections_from_frame(obj,detections,scene_label,frame)
            table_name='app_region';
            scene_path = scene_label(1);
            scene_timestamp = scene_label(2);
            % get label names
            scene_query = ['select id from ',obj.tablenames.scene_table_name,' where path = ''',char(scene_path),''' and timestamp=''',char(scene_timestamp),''''];
            cur2=exec(obj.conn,scene_query);
            cur2=fetch(cur2,1);
            scene_id=cur2.Data{1};
            for i = 1:size(detections,1)
                colnames=obj.colnames.app_region_colnames.insertion;
                detection_label=num2str(round(detections(i,1)));
                cur=exec(obj.conn,['select id from ',obj.tablenames.label_table_name,' where title = ''',detection_label,'''']);
                cur=fetch(cur,1);
                label_id=cur.Data{1};
                label_version=obj.db_version;
                detection=struct('x1',detections(i,2),...
                    'y1',detections(i,3),...
                    'x2',detections(i,4),...
                    'y2',detections(i,5),...
                    'frame',frame,...
                    'confidence',detections(i,6));
                data={detection.frame,detection.x1,detection.x2,detection.y1,detection.y2,label_version,label_id,scene_id,detection.confidence};
                datainsert(obj.conn,table_name,colnames,data);
            end
        end
        
        
        function add_synthetic_detections(obj, synthetic_detections,scene_label)
            table_name='app_synthetic_region';
            scene_path = scene_label(1);
            scene_timestamp = scene_label(2);
            % get label names
            scene_query = ['select id from ',obj.tablenames.scene_table_name,' where path = ''',char(scene_path),''' and timestamp=''',char(scene_timestamp),''''];
            cur2=exec(obj.conn,scene_query);
            cur2=fetch(cur2,1);
            scene_id=cur2.Data{1};   
            
            %make scene_id cell array of as many rows of detections
            [h, w] = size(synthetic_detections);
            scene_cell = cell(h,1);
            scene_cell(:) = {scene_id};
            data = [synthetic_detections scene_cell];
            col_names=obj.colnames.app_synthetic_region_colnames.insertion;
            datainsert(obj.conn,table_name,col_names,data);
        end
        
        function add_scene(obj,scene)
            table_name='app_scene';
            colnames=obj.colnames.app_scene_colnames.insertion;
            t=format_time_str(obj,now);
            time_taken=t;
            time_added=t;
            label_version=obj.db_version;
            thumbnail=' ';
            data={scene.path,scene.timestamp,scene.frames,scene.frame_rate,scene.width,scene.height,time_taken,time_added,thumbnail};
            datainsert(obj.conn,table_name,colnames,data);
        end
        
        

        
        function get_observations_for_frame(stream_id,frame_id)
        end
        
        
        function add_coreset(obj, scene_label, coreset)
            %first find scene_id
            scene_path = scene_label(1);
            scene_timestamp = scene_label(2);
            scene_query = ['select id from ',obj.tablenames.scene_table_name,' where path = ''',char(scene_path),''' and timestamp=''',char(scene_timestamp),''''];
            cur2=exec(obj.conn,scene_query);
            cur2=fetch(cur2,1);
            scene_id=cur2.Data{1};
            
            table_name = 'app_coreset';
            col_names = obj.colnames.app_coreset_colnames.insertion;
            data = {scene_id, coreset.coreset_tree_path, coreset.coreset_results_path, coreset.simple_coreset_path};
            datainsert(obj.conn, table_name, col_names, data)
        end
        
        %following function added for test. start_int is optional
        function add_data_to_test_table(obj,num_rows, start_int)
            table_name = 'app_test';
            col_names = obj.colnames.app_test_colnames.insertion;
            
            %add data every insert_freq rows
            insert_freq = 25000;
            if ~exist('start_int', 'var')
                start_int = 1;
            end
            
            if num_rows < insert_freq
                data = cell(num_rows, length(col_names));
            else
                data = cell(insert_freq, length(col_names));
            end
            num_added_rows = 0;
            for i=start_int:start_int+num_rows-1
                %generate a random text
                symbols = ['a':'z' 'A':'Z' '0':'9'];
                MAX_ST_LENGTH = 50;
                stLength = randi(MAX_ST_LENGTH);
                nums = randi(numel(symbols),[1 stLength]);
                rand_text = symbols (nums);                
                int_data = i;               
                rand_float = rand();                
                float_data = i+rand_float;           
                time = format_time_str(obj,now);
                
                next_rand_text = symbols(randi(numel(symbols),[1 stLength]));
               
                curr_data = {rand_text, int_data, float_data, time, next_rand_text};
                
                row_num = i - start_int + 1;
                data(row_num-num_added_rows, :) = curr_data;

                
                if mod(row_num, insert_freq) == 0 || row_num == num_rows
                    disp(['Adding a batch of ' int2str(size(data,1)) ' rows.']);
                    datainsert(obj.conn, table_name, col_names, data);
                    num_added_rows = num_added_rows + insert_freq;
                    disp(['Added total of ' int2str(num_added_rows) ' rows.']);
                    rows_remain = num_rows - num_added_rows;
                    if rows_remain < insert_freq
                        data = cell(rows_remain, length(col_names));
                    else
                        data = cell(insert_freq, length(col_names));
                    end                    
                end
            end
            
        end
        
        function get_rows_from_test(obj, colname, value)
            query = [obj.conn,'select * from ',obj.tablenames.test_table_name,' where ', colname, '=''', value, ''''];
            cur = exec(query);
        end
        
        
        function get_range_rows_from_test(obj, colname, value_range)
            table_name = 'app_test';
            query = ['select * from ', obj.tablenames.test_table_name,' where ', colname, ' between ', int2str(value_range(1)), ' and ', int2str(value_range(2)),''];
            curs = exec(obj.conn, query);
            curs = fetch(curs);
        end
        
    end
end
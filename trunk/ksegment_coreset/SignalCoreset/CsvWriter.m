classdef CsvWriter < handle
  %CsvWriter Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    
    Filepath;
    
    %  flush data to file when the number of rows exceeds rows_cache_size
    rows_cache_size = 1;
    
    % data to write as csv rows
    rows_cache = {};
    
  end
  
  methods
    
    function this = CsvWriter(filepath)
     
      this.Filepath = filepath;
      [pathstr,~,~] = fileparts(filepath);
      
      % create report directory
      if not(exist(pathstr,'file'))
        mkdir(pathstr)
      end
      if exist(this.Filepath,'file') ~= 2
        fid = fopen(this.Filepath,'w');
        fclose(fid);
      end
      
    end
    
    % add rows to csv file
    function addRows(this,rows)
      if not(isempty(this.rows_cache)) && size(rows,2)~=size(this.rows_cache,2)
        this.flush();
      end
      this.rows_cache = cat(1,this.rows_cache,rows);
      if size(this.rows_cache,1) >= this.rows_cache_size
        this.flush();
      end
    end
    
    % write file
    function flush(this)
      try
        report_rows = this.rows_cache
        [~,name,ext] = fileparts(this.Filepath);
        disp(['Writing to ' name ext])
        fid = fopen(this.Filepath,'a');
        for i = 1:size(report_rows,1)
          for j = 1:size(report_rows,2)
            entry = report_rows{i,j};
            if ischar(entry)
              fprintf(fid,'%s',entry);
            elseif isnumeric(entry)
              fprintf(fid,'%s',num2str(entry));
            else
              error('wrong format!')
            end
            if j < size(report_rows,2)
              fprintf(fid,',');
            else
              fprintf(fid,'\n');
            end
          end
        end
        fclose(fid);
        this.rows_cache = {};
      catch e
        warning(e.identifier,e.message)
      end
      
    end
    
    % write data to file
    function close(this)
      if not(isempty(this.rows_cache))
        this.flush();
      end
    end
    
  end
  
end



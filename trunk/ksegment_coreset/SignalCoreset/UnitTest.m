classdef UnitTest < HandleObject
  %UnitTest Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    
    tester
    tester_name
    
    test_fields = {}
    report_fields = {}
    groups
    
    SaveReport = true
    ReportFilepath
    csv_writer
    
    configs
    num_configs
    
    UseCluster = true
    
  end
  
  %% public methods
  methods (Access = public)
    
    % constructor
    function this = UnitTest(tester,report_filepath)
      
      this.tester = tester;
      this.tester_name = 'tester';
      this.ReportFilepath = report_filepath;
      
    end
    
    % set test fields from tester
    function SetTestField(this,field_name,varargin)
      p = inputParser;
      p.addOptional('values',[])
      p.addParamValue('group',0,@isnumeric)
      p.parse(varargin{:})
      values = p.Results.values;
      group = p.Results.group;
      
      tester_field_name = [this.tester_name '.' field_name];
      
      put_test_field = true;
      if not(group == 0)
        if length(this.groups) < group
          this.groups{group} = length(this.test_fields)/2+1;
        else
          put_test_field = false;
          this.groups{group} = [this.groups{group} {tester_field_name,values}];
        end
      end
      if not(isempty(values)) && put_test_field
        this.test_fields = [this.test_fields  {tester_field_name values}];
      end
      
      this.report_fields = [this.report_fields field_name];
      
    end
    
    % initialize tester
    function InitTestBench(this)
      
      this.configs = this.makeCartesianProduct();
      this.num_configs = this.configs.nCols;
      disp(['Created ' num2str(this.num_configs) ' configurations.'])
      
      % test field confirmation
      disp(repmat('- ',1,20))
      for i = 1:length(this.test_fields)
        disp(this.test_fields{i})
      end
      disp(repmat('- ',1,20))
      
    end
    
    % init cluster
    function InitCluster(this,cluster_profile)
      
      % initialize cluster
      if this.UseCluster
        attached_files = dirrec(pwd,'.m');
        init_cluster(cluster_profile,'Update','NumWorkers',this.num_configs,'AttachedFiles',attached_files);
      end
      
    end
    
    % run tests (for loop)
    function [results,output_data] = RunTests(this)
      tic
      
      % open CSV writer
      if this.SaveReport
        this.csv_writer = CsvWriter(this.ReportFilepath);
      end
      
      % print header
      header = this.getReportFields();
      this.print(header)
      
      if this.UseCluster
        
        % run on cluster:
        disp(repmat('-',1,80))
        disp(['Running ' num2str(this.num_configs) ' unit tests:'])
        spmd
          spmd_this = this;
          [report_line,results_composite,output_data_composite] = spmd_this.runConfig(labindex);
        end
        results = cell(1,this.num_configs);
        output_data = cell(1,this.num_configs);
        for c = 1:this.num_configs
          results{c} = results_composite{c};
          output_data{c} = output_data_composite{c};
          this.print(report_line{c});
        end
        disp(repmat('-',1,80))
        
      else
        
        % run local:
        results = cell(1,this.num_configs);
        output_data = cell(1,this.num_configs);
        for c = 1:this.num_configs
          disp(repmat('-',1,80))
          disp(['Running unit test #' num2str(c) ' of ' num2str(this.num_configs)])
          [report_line,results{c},output_data{c}] = this.runConfig(c);
          this.print(report_line);
        end
        disp(repmat('-',1,80))
        
      end
      
      % close CSV writer
      if this.SaveReport
        this.csv_writer.close();
      end
      
      toc
    end
    
  end
  
  %% 
  methods
    
    function [report_line,results,output_data] = runConfig(this,config_no)
      try
        this.makeTestConfig(config_no);
        start_time = tic;
        [results,output_data] = KSegmentCoresetTester.Run(config_no,this.tester);
        report_line = this.makeReportLine(results);
        test_time = toc(start_time);
        disp(['Done! Elapsed time is ' num2str(test_time/60) ' minutes.'])
      catch e
        warning(e.identifier,e.message)
        report_line = '';
      end
    end
    
    % make the test config matrix
    function configs = makeCartesianProduct(this)
      
      nFields = length(this.test_fields)/2;
      sizeCell = cell(1,nFields);
      for fieldNo = 1:nFields
        valuesVec = this.test_fields{2*fieldNo};
        sizeCell{fieldNo} = 1:length(valuesVec);
      end
      configs = Utils.setProd(sizeCell)';
      
    end
    
    % make test config (can be done in parallel)
    function makeTestConfig(this,config_no)
      
      config = this.configs.m(:,config_no);
      for i = 1:length(this.test_fields)/2
        field_name = this.test_fields{2*i-1};
        field_vec = this.test_fields{2*i};
        if iscell(field_vec)
          field_value = field_vec{config(i)};
        else
          field_value = field_vec(config(i));
        end
        Utils.setFieldValue(this,field_name,field_value);
      end
      for group = 1:length(this.groups)
        g = this.groups{group};
        mainFieldNo = g{1};
        g = g(2:end);
        for i = 1:length(g)/2
          field_name = g{2*i-1};
          field_vec = g{2*i};
          field_value = field_vec(config(mainFieldNo));
          Utils.setFieldValue(this,field_name,field_value);
        end
      end
      
    end
    
    % function result = globalTimeRatio(this)
    %   result = this.tester.totalTime/this.tester.totalTime;
    % end
    %
    % function result = globalSizeRatio(this)
    %   result = this.tester.size/this.tester.size;
    % end
    
    % print report line (to writer or console)
    function print(this,report_line)
      if this.SaveReport
        this.csv_writer.addRows(report_line);
      else
        disp(report_line)
      end
    end
    
    % get all report fields
    function fields = getReportFields(this)
      fields = cell(size(this.report_fields));
      for i = 1:length(this.report_fields)
        str = this.report_fields{i};
        ind = strfind(str,'.');
        if not(isempty(ind))
          str = str(ind(end)+1:end);
        end
        fields{i} = str;
      end
    end
    
    % make report line
    function reportLine = makeReportLine(this,results)
      reportLine = cell(1,length(this.report_fields));
      for i = 1:length(this.report_fields)
        if not(isempty(this.report_fields{i}))
          report_field_name = [this.report_fields{i}];
          field_value = Utils.getFieldValue(results,report_field_name);
          field_value = Utils.asString(field_value);
          reportLine{i} = field_value;
        else
          reportLine{i} = '';
        end
      end
    end
    
  end % methods
  
end


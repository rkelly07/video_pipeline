classdef KSegmentCoresetTester < handle
  %KSegmentCoresetTester Summary of this class goes here
  %   Detailed explanation goes here
  
  properties(SetAccess = private)
    
    UseCluster = false
    ClusterProfile = 'test1'
    
    ReportDir     = 'tests'    
    Description   = ''
    
    SaveReport  = true
    SaveData    = true
    SaveLog     = false
    
    PointSource = 'input'    % input|generate
%     InputFile = '/shared/persisted/test_blocks/block'   % input mat file
    InputFile = 'TelepresenceRobot_Video_results.mat'
    
    leaf_size = 500
    
    % number of test for each param vector
    num_tests = 1
    
    verbose = true
    
    % test params:
    
    % generated data test params:
    test_n = 10000
    test_d = 20
    test_k = 20
    test_axk % factors to multiply by k
    
    % main params:
    test_a = 50
    test_b = 2
    test_c = 0.2 % [0.5 0.2 0.1 0.05 0.02 0.01]
    
    %test_z
    test_w = 0.99
    
    % results
    m
    mx
    coreset_time
    
    D_eps_src
    U_eps_src
    R_eps_src
    
    D_eps_rnd
    U_eps_rnd
    R_eps_rnd
    D_eps_rnd_std
    U_eps_rnd_std
    R_eps_rnd_std
    
    % constants
    spread = 1.0
    
    add_gaussian_noise        = true;
    gaussian_noise_mean       = 0;
    gaussian_noise_gain       = 0.1;
    gaussian_post_spread      = false;
    
    add_salt_pepper_noise     = true;
    snp_noise_prob            = 0.02;
    snp_noise_gain            = 2;
    salt_pepper_post_spread   = false;
    
    num_queries = 10
    
    save_tree = true
        
    % tester properties
    test_bench
    
    TestName
    ReportFilepath
    DataFilepath
    LogFilepath
    
    results
    output_data
    
  end
  
  properties 
    
    % unit test fields
    n,d,k,a,b,c,w,iter
    
  end
  
  %% methods
  methods
    
    function this = KSegmentCoresetTester()
      
      timestamp = ['@' datestr(now,'mmdd-HHMM')];
      this.TestName = timestamp;
      
      this.ReportDir = ['tests',filesep,'report',this.TestName]; 
      
      % add desription
      if not(isempty(this.Description))
        this.ReportDir = [this.ReportDir,'(' this.Description ')'];
      end
      
      this.ReportFilepath = [this.ReportDir,filesep,'report',this.TestName,'.csv'];
      this.DataFilepath = [this.ReportDir,filesep,'data',this.TestName,'.mat'];
      this.LogFilepath = [this.ReportDir,filesep,'log',this.TestName,'.log'];
      
      % create report directory
      if not(exist(this.ReportDir,'dir'))
        mkdir(this.ReportDir)
      end
      
      this.test_bench = UnitTest(this,this.ReportFilepath);
      this.test_bench.UseCluster = this.UseCluster;
      this.init()
      this.setTestFields()
      this.test_bench.InitTestBench()
      this.test_bench.InitCluster(this.ClusterProfile)
      
      if this.SaveLog
        diary(this.LogFilepath)
      end
      
      [this.results,this.output_data] = this.test_bench.RunTests();
      
      if this.SaveLog
        diary off
      end
      
      matlabpool close force
      
    end
    
    % init test params and variables
    function init(this)
      
      %this.get_input_test_fields();
      
      this.test_n = 10000;
      this.test_d = 5000;
      this.test_k = 0;
      
      % maxke a/k group
      if not(isempty(this.test_axk))
        axk = repmat(this.test_axk,1,length(this.test_k));
        this.test_k = repmat(this.test_k,length(this.test_axk),1);
        this.test_k = this.test_k(:)';
        this.test_a = this.test_k.*axk;
      end
      
    end
    
    function SetTestField(this,test_field,varargin)
      this.test_bench.SetTestField(test_field,varargin{:});
    end
    
    function setTestFields(this)
      
      % parameters
      this.SetTestField('n',this.test_n)
      this.SetTestField('d',this.test_d)
      if isempty(this.test_axk)
        this.SetTestField('k',this.test_k)
        this.SetTestField('a',this.test_a)
      else
        this.SetTestField('k',this.test_k,'group',1)
        this.SetTestField('a',this.test_a,'group',1)
      end
      this.SetTestField('b',this.test_b)
      this.SetTestField('c',this.test_c)
      this.SetTestField('w',this.test_w)
      this.SetTestField('iter',1:this.num_tests)
      
      % outputs
      this.SetTestField('m')
      this.SetTestField('mx')
      this.SetTestField('coreset_time')
      
      if strcmp(this.PointSource,'generate')
        this.SetTestField('D_eps_src')
        this.SetTestField('U_eps_src')
        this.SetTestField('R_eps_src')
        
        this.SetTestField('D_eps_rnd')
        this.SetTestField('U_eps_rnd')
        this.SetTestField('R_eps_rnd')
        this.SetTestField('D_eps_rnd_std')
        this.SetTestField('U_eps_rnd_std')
        this.SetTestField('R_eps_rnd_std')
      end
      
    end
        
    % input data from file
    function get_input_test_fields(this)
      
      load(this.InputFile)
      X = bags_of_words;
      
      this.test_n = size(X,1);
      this.test_d = size(X,2);
      
      this.n = this.test_n;
      this.d = this.test_d;
      
      this.test_k = 0;
      this.test_axk = [];
      
    end
    
  end
  
  %% static methods
  methods (Static)
     
    % generate data as in test_ksegment_coreset
    function [P,Lx,x_endpoints] = GenerateData(tester)
      
      T = (1:tester.n)';
      [X,Lx,x_endpoints] = generate_ksegment_points(T,tester.d,tester.k,tester.spread);
      signal_start = x_endpoints(1,2);
      signal_end = x_endpoints(end-1,2);
      
      % add gaussian noise
      if tester.add_gaussian_noise
        G = tester.gaussian_noise_mean+tester.gaussian_noise_gain*randn(size(X));
        G(setdiff(1:size(G,1),signal_start:signal_end),:) = 0;
        X = X+G;
      end
      
      % add salt and pepper noise
      if tester.add_salt_pepper_noise
        E = ((randi((1/tester.snp_noise_prob)-1,size(X))-1)==0).*tester.snp_noise_gain.*(2*rand(size(X))-1);
        E(setdiff(1:size(E,1),signal_start:signal_end),:) = 0;
        X = X+E;
      end
      
      % create signal point set
      P = SignalPointSet(X,T);
      
    end
    
    % input data from file
    function P = InputData(tester)
      
%       filename = [tester.InputFile num2str(labindex) '.mat'];
%       load(filename)
%       X = S;
%       T = 1:size(X,1);
      
      load(tester.InputFile)
      X = bags_of_words;
      T  = processed_frame_idx;
      
      tester.n = size(X,1);
      tester.d = size(X,2);
      
      % create signal point set
      P = SignalPointSet(X,T);
      
    end

    % all tests are static
    % tester should be read-only
    function [results,output_data] = Run(test_no,tester)
      
      results.n = tester.n;
      results.d = tester.d;
      results.k = tester.k;
      results.a = tester.a;
      results.b = tester.b;
      results.c = tester.c;
      results.w = tester.w;
      results.iter = tester.iter;
      
      stream = Stream();
      stream.leafSize = min(tester.n,tester.leaf_size);
      stream.saveTree = tester.save_tree;
      if not(tester.UseCluster)
        stream.verbose = tester.verbose;
      else
        stream.verbose = false;
      end
      
      coreset_alg = KSegmentCoresetAlg();
      coreset_alg.a = tester.a;
      coreset_alg.b = tester.b;
      coreset_alg.c = tester.c;
      coreset_alg.w = tester.w;
      stream.coresetAlg = coreset_alg;
      
      % get data
      switch tester.PointSource
        case 'generate'
          [P,Lx,x_endpoints] = KSegmentCoresetTester.GenerateData(tester);
        case 'input'
          P = KSegmentCoresetTester.InputData(tester);
        otherwise
      end
        
      % compute coreset
      coreset_start_time = tic;
      stream.addPointSet(P);
      D = stream.getUnifiedCoreset();
      results.coreset_time = toc(coreset_start_time);
      results.m = D.m;
      
      % save coreset to output
      output_data.stream = stream;
      output_data.D = D;
      
      % benchmark coresets
      results.mx = D.totalCoresetSize();
      
      U = UniformSampleCoreset(P,results.mx);
      R = RandomSampleCoreset(P,results.mx);
      
      if strcmp(tester.PointSource,'generate')
        
        % source query
        Q = SourceKSegmentQuery(P.T,Lx,x_endpoints);
        cost_PQ_src = P.ComputeQueryCost(Q);
        cost_DQ_src = D.ComputeQueryCost(Q);
        cost_UQ_src = U.ComputeQueryCost(Q);
        cost_RQ_src = R.ComputeQueryCost(Q);
        
        [results.D_eps_src] = compute_error_estimate(cost_PQ_src,cost_DQ_src);
        [results.U_eps_src] = compute_error_estimate(cost_PQ_src,cost_UQ_src);
        [results.R_eps_src] = compute_error_estimate(cost_PQ_src,cost_RQ_src);
        
        % random query
        cost_PQ_rnd = zeros(1,tester.num_queries);
        cost_DQ_rnd = zeros(1,tester.num_queries);
        cost_UQ_rnd = zeros(1,tester.num_queries);
        cost_RQ_rnd = zeros(1,tester.num_queries);
        for i = 1:tester.num_queries
          Q = RandomKSegmentQuery(P.T,P.d,tester.k);
          cost_PQ_rnd(i) = P.ComputeQueryCost(Q);
          cost_DQ_rnd(i) = D.ComputeQueryCost(Q);
          cost_UQ_rnd(i) = U.ComputeQueryCost(Q);
          cost_RQ_rnd(i) = R.ComputeQueryCost(Q);
        end
        
        [results.D_eps_rnd,results.D_eps_rnd_std,~,~] = compute_error_estimate(cost_PQ_rnd,cost_DQ_rnd);
        [results.U_eps_rnd,results.U_eps_rnd_std,~,~] = compute_error_estimate(cost_PQ_rnd,cost_UQ_rnd);
        [results.R_eps_rnd,results.R_eps_rnd_std,~,~] = compute_error_estimate(cost_PQ_rnd,cost_RQ_rnd);
        
      end
      
      if tester.SaveData
        [pathstr,name,ext] = fileparts(tester.DataFilepath);
        name = [name,'#',num2str(test_no)];
        save([pathstr,filesep,name,ext])
      end
      
      % flush log output
      if tester.SaveLog
        diary off, diary on
      end
      
    end
    
  end
  
end

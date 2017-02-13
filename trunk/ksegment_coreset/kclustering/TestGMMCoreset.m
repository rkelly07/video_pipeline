classdef TestGMMCoreset < Test
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
           gmm = 1; % coresetType
           kmeans = 2; % coresetType
    end % (Constant)
    properties
        inputMatrix % input points
        n % number of points from the matrix
        figures % show figures
        DZ;
        UZ;
        CZ;
        prior;

        % use random data
        random = false;

        objective = TestGMMCoreset.gmm;

        % solution for k-means/gmm on original set, coreset, and uniform sample
        cost;
        Ccost;
        Ucost;
        Ccost_vs_cost;
        Ucost_vs_cost;
        
        tryNo;  % Number of tries for the same group of parameters.
        
        kc =KMedianCoresetAlg();% the kmeans coreset algorithm.
        CTimeConstruction;
        TimeRunWithoutCoreset;
        CTimeRunOnCoreset;
        CTimeTotalRunOnCoreset;
        TimeOnUniformSample;
        
        nRestartsWithoutCoreset = 1;
        nRestartsWithCoreset = 1;
        nIterationsWithCoreset = 250;
        nIterationsWithoutCoreset = 250;

        % likelihood of coreset model on input data
        Cllh;
        
        % likelihood of uniform sampling model on input data
        Ullh;
        
        % likelihood of full dataset model on input data
        llh;
    end

   properties (Dependent)
        TimeVsCTime;
        CcostVsCost;        
        UcostVsCost;             
   end % properties (Dependent)
    methods
        function result=get.TimeVsCTime(obj)
             result=obj.TimeRunWithoutCoreset/obj.CTimeTotalRunOnCoreset;
        end % get.RatioCtimeVsTime()
        function result=get.CcostVsCost(obj)
            result=obj.Ccost/obj.cost;
        end % RatioCsqDistsVsEnery 
        function result=get.UcostVsCost(obj)
            result=obj.Ucost/obj.cost;
        end % RatioUCostVsCost
        function obj=setReportFields(obj)
            obj.reportFields = {'prior' 'llh' 'Cllh' 'Ullh' 'DZ' 'UZ' 'CZ'  ...
                'Ccost_vs_cost', 'Ucost_vs_cost' 'kc.bicriteriaAlg.robustAlg.partitionFraction', 'kc.bicriteriaAlg.update', 'n', 'kc.k', 'kc.t' 'kc.bicriteriaAlg.robustAlg.beta' ...
               'CTimeConstruction', 'TimeRunWithoutCoreset', ...
        'CTimeRunOnCoreset', 'CTimeTotalRunOnCoreset',...
        'cost' 'Ccost', 'Ucost'  'tryNo', 'TimeVsCTime', 'CcostVsCost', 'UcostVsCost'...
        'kc.report.bicriteriaTime', 'kc.report.bicriteriaSize',...
        'nIterationsWithCoreset', 'nIterationsWithoutCoreset', 'kc.coresetType', 'kc.weightsFactor', 'kc.warningNegative'};
        end
        function P=createMatrix(obj)
            % Create matrix.
            if obj.random
                mat=obj.randomData(obj.n, 2, obj.kc.k);
            else
                originalSize=size(obj.inputMatrix,1);
                mat=obj.inputMatrix(randsample(originalSize, obj.n),:);
            end
            M=Matrix(mat);

            % Create a Pointfunctionset from input matrix.
            P=PointFunctionSet(M);
        end % createMatrix

        function C=computeCoreset(obj,P)
            % Compute CORESET
            obj.CTimeConstruction=tic;           
            Kc=obj.kc;
            Kc.computeCoreset(P);
            obj.CTimeConstruction=toc(obj.CTimeConstruction);
            C=Kc.coreset;
            if obj.figures
                obj.showCoreset(C,P);
            end
        end %computeCoreset

        function showCoreset(obj, C, P)
                close all;
                figure(1)
                clf
                hold on
                scatter(P.M.m(:,1),P.M.m(:,2),1,'b');
                visualizeCoreset(C);
                disp('pause');
                pause
        end
        
        function CModel=computeGmmOnCoreset(obj, P, C)
            obj.CTimeRunOnCoreset = tic;
            %opts = statset('MaxIter',obj.nIterationsWithCoreset);
            if obj.objective == obj.gmm
                [~, CModel, ~] = wemgm_restart(C.M.matrix', C.W.m', obj.kc.k, obj.nRestartsWithCoreset);
                obj.Cllh = computeLLH(P.M.matrix',CModel)*P.M.nRows;
                obj.CZ=obj.computeZ(CModel.Sigma, CModel.weight);
            else
                % determine number of iterations for Ckmeans without coreset
                opts = statset('MaxIter',obj.nIterationsWithCoreset);
                [~, Centers] = ...
                    Ckmeans(C.M.matrix, obj.kc.k, C.W.m,'emptyaction','singleton','Options',opts);
                CModel = obj.kmeans2gmm(Centers);
            end % if obj.objective
            if obj.figures
                figure(1);
                for i = 1:size(CModel.Sigma,3)
                    h=PlotEllipse(CModel.Sigma(:,:,i),CModel.mu(:,i));
                    set(h,'color','m') ;
                end %for
                disp('pause');
                pause;
            end % if
            obj.CTimeRunOnCoreset=toc(obj.CTimeRunOnCoreset);
            obj.CTimeTotalRunOnCoreset=obj.CTimeConstruction+obj.CTimeRunOnCoreset;
        end % computeGMM

        function model=kmeans2gmm(obj, centers)
            d=size(centers,2);
            k=size(centers,1);
            model.mu=centers'; 
            for i=1:k
                model.Sigma(:,:,i)=eye(d,d);
            end % for
        end % kmeans2gmm()
        
        function  Model = computeGmmOnOriginalData(obj, P)
            W(1:obj.n,1)=1;

            % timer for original kmedian
            obj.TimeRunWithoutCoreset=tic;
            if obj.objective == obj.gmm
                 [~, Model, ~] = wemgm_restart(P.M.matrix', W', obj.kc.k, obj.nRestartsWithoutCoreset);
                 obj.llh = computeLLH(P.M.matrix',Model)*P.M.nRows;
                 obj.DZ=obj.computeZ(Model.Sigma, Model.weight);
            else
                % determine number of iterations for Ckmeans without coreset
                 opts = statset('MaxIter',obj.nIterationsWithoutCoreset);
                 [~, Centers, cost] = ...
                     kmeans(P.M.matrix, obj.kc.k, 'Options',opts, 'emptyAction', 'singleton');
                 Model = obj.kmeans2gmm(Centers);
                 %obj.cost = 
            end  % if
            obj.TimeRunWithoutCoreset=toc(obj.TimeRunWithoutCoreset);
            if obj.figures
                hold on;
                for i = 1:size(Model.Sigma,3)
                   h=PlotEllipse(Model.Sigma(:,:,i),Model.mu(:,i));
                   set(h,'color','g');
                end
                figure(1);
                disp('pause');
                pause;
            end % if
        end
        
        function UModel = computeGmmOnUniformRandom(obj, P, sampleSize)
            % compute EM on uniform random sample
            obj.TimeOnUniformSample=tic;

            idxs = randsample(obj.n, sampleSize);
            UW = ones(sampleSize,1);
            U=P.matrix(idxs,:)';
            if obj.objective == obj.gmm
                [~, UModel, ~] = wemgm_restart(U, UW', obj.kc.k, obj.nRestartsWithCoreset);
                obj.Ullh = computeLLH(P.matrix', UModel)*P.nRows;
                obj.UZ=obj.computeZ(UModel.Sigma, UModel.weight);
            else
                opts = statset('MaxIter',obj.nIterationsWithCoreset);
                [~, Centers] = ...
                    kmeans(U', obj.kc.k,'emptyaction','singleton','Options',opts);
                    UModel = obj.kmeans2gmm(Centers);
            end % if
            obj.TimeOnUniformSample = toc(obj.TimeOnUniformSample);
            if obj.figures
                for i = 1:size(UModel.Sigma,3)
                   h=PlotEllipse(UModel.Sigma(:,:,i),UModel.mu(:,i));
                   set(h,'color','r');
                end
                disp('pause');
                pause;
            end % if
        end

        function reportPhi(obj, P, Model, CModel, UModel)
            obj.cost=obj.computePhi(P.M.matrix, Model);
            obj.cost
            obj.computePhi2(P.M, Model)
            
            obj.Ccost=obj.computePhi(P.M.matrix, CModel);
            obj.Ucost=obj.computePhi(P.M.matrix, UModel);
            
            obj.Ccost_vs_cost=Utils.ratio(obj.cost, obj.Ccost);
            obj.Ucost_vs_cost=Utils.ratio(obj.cost, obj.Ucost);
        end
        function main(obj)
            P=obj.createMatrix();
            Model=obj.computeGmmOnOriginalData(P);
            
            C=obj.computeCoreset(P);
            CModel=obj.computeGmmOnCoreset(P, C);
            UModel = obj.computeGmmOnUniformRandom(P.M, C.W.nRows);
            %obj.reportPhi(P, Model, CModel, UModel);
        end% function main   
        
        function obj=run(obj)
            obj=obj.setReportFields();
            obj.main();
        end 
        function computePhi(obj, P, model)
           ll = computeLLH(P.matrix',model)*P.nRows;
           Z= obj.computeZ(model.Sigma, model.weight);
           
        end
        function r=randomData(obj, n, d, k)
            r=[];
            for i=1:k
                mu = rand(d,1)*100;
                %A=randn(d,d);
                %SIGMA = A'*A;
                SIGMA=eye(2,2);
                if i~=k
                    newr = mvnrnd(mu,SIGMA,round(n/k));
                else
                    s=n-size(r,1);
                    newr = mvnrnd(mu,SIGMA,s);
                end% if
                r=[r; newr];
            end % for
            if obj.figures
               plot(r(:,1),r(:,2),'+')
               figure(1);
               disp('pause..');
               pause;
            end
        end % randomData
        
    end % methods
    
    methods (Static)
        function test2
            G=TestGMMCoreset();
        end
        function randM=loadPhoneData()
                 load 7recordings_combined_262hrs;
                 M=zeros(size(cTrain_set));
                 M=[];
                 for (i=1:size(cTrain_set,2));
                     M=[M feature.Feature.unpackFeatureVectors(cTrain_set(:,i))];
                 end
                 randM=M(:,randperm(size(M,2))) ;
                 randM=randM';
                 save randM;
        end
        function Z = computeZ(Sigma, weight)
                Z=0;
                for i=1:length(weight)
                    S=Sigma(:,:,i);
                    w=weight(i);
                    Z=Z+w/sqrt(det(2*pi*S));
                end % for
        end % computeZ

        
%         function testkmeans()
%             compare the results 
%             [ct, t, Csq, sq]=TestKMedianCoreset.compareCoresetKMeans(P, C, obj.kc.k, ...
%                 obj.nIterationsWithCoreset, obj.nIterationsWithoutCoreset);
% 
%             obj.CTimeKmeansOnCoreset=ct;
%             obj.CTimeTotalKmeansOnCoreset=obj.CTimeConstruction+obj.CTimeKmeansOnCoreset;
%             obj.TimeKmeansWithoutCoreset=t;
%             obj.CsqDists=Csq;
%             obj.sqDists=sq;
%         end
        
        function test()
            myClear;
            random=false;  % random input data
            T=TestGMMCoreset();
            T=T.setTestField('n', LS.n);  % number of points
            T.random=random;
            if not(random)
             %load m;   
             T.inputMatrix=LS.transLines;
            end
            
            % don't show figures
            T.figures=false;
            T=T.setTestField('toExcel', false);
            T.fileName='.\report.xls';
            
            %
            T=T.setTestField('tryNo', 1);
            
            % test parameters
            str='kc.';
            % number of clusters
            T=T.setTestField([str 'k'], LS.nclusters);
            T=T.setTestField([str 'coresetType'], [KMedianCoresetAlg.linearInK ]);% ]);
            % size of coreset
            T=T.setTestField([str 't'], 1000);%1000:500:8000);%[100:1000:9000]);
            str=[str 'bicriteriaAlg.robustAlg.'];
            T=T.setTestField([str 'beta'], 12);
            T=T.setTestField([str 'partitionFraction'], 1/5);
            T=T.setTestField([str 'costMethod'], ClusterVector.maxDistanceCost);
            
            str=[str 'figure.'];
            T=T.setTestField([str 'sample'], false);
            T=T.setTestField([str 'iteration'], false);
            T=T.setTestField([str 'opt'], false);
            

%            T=T.setTestField('nIterationsWithCoreset', inf);
%            T=T.setTestField('nIterationsWithoutCoreset', inf);
            T=T.setTestField('kc.bicriteriaAlg.robustAlg.nIterations', 2);
            T=T.setTestField('nRestartsWithCoreset', 5);
            T=T.setTestField('nRestartsWithoutCoreset', 5);
            T=T.setTestField('kc.bicriteriaAlg.robustAlg.gamma', 1);
            T.runCartesianProduct();
        end % test
    end % methods (static)
end % class
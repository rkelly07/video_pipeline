 classdef KmeansTester < Tester
    methods (Static)
        function main ()
            myClear;
            %obj.pointSource = inputFile;
            T=Test();
            T.toExcel=true;
            T.fileName='.\report.xls';
            T.tester{1}=KmeansTester();
            T=T.init();
            T.runCartesianProduct();
        end
    end 
    methods
        function initPrivate(obj)
            leafSize = 100;
            k=6;
            beta=10;
            t=50;
            partition = 1/2;
            nIterations = 2;
            
            obj.setTestField('streamAlg', Stream()); 
            str='streamAlg.';
            obj.setTestField([str 'coresetAlg'], KMedianCoresetAlg());
            obj.setTestField([str 'coresetAlg'], KMedianCoresetAlg());

            str=[str '.coresetAlg.'];
            obj.setTestField([str 'k'], 1);
            obj.setTestField([str 'coresetType'], [KMedianCoresetAlg.linearInK ]);% ]);
            %obj.setTestField([str 'nRestartsWithCoreset'], 5);
            %obj.setTestField([str 'nRestartsWithoutCoreset'], 5);
            obj.setTestField([str 'sampleSize'], 1:10:100, 1);
            obj.setTestField([str 'k'], 1:10:100);

            str=[str 'bicriteriaAlg.robustAlg.'];
            obj.setTestField([str 'beta'], beta);
            obj.setTestField([str 'partitionFraction'], partition);
            obj.setTestField([str 'costMethod'], ClusterVector.maxDistanceCost);
            obj.setTestField([str 'nIterations'], nIterations);
            obj.setTestField([str 'gamma'], 1);
            
            str=[str 'figure.'];
            obj.setTestField([str 'sample'], false);
            obj.setTestField([str 'iteration'], false);
            obj.setTestField([str 'opt'], false);
            
            obj.setTestField('pointSource', {'inputFile'}); 
            obj.setTestField('runIfUnchanged', false); 
            obj.setTestField('streamAlg.leafSize', leafSize); 
%            obj.setTestField('onCoresetAlg', CKmenas); % for the final result
%            obj.setTestField('onCoresetAlg.k', onCoresetK); % for the final result
        end % init

         function computeP(obj)
             obj.P = PointFunctionSet(rand(1000,2));
             %load(obj.inputFile);
         end
    end % methods
end


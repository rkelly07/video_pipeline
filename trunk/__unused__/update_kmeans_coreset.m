function res=update_kmeans_coreset(res,F)
if (~isfield(res,'spmd_feature_coreset'))
params.NumFeatureClusters=5000;

feature_coreset_alg = KMedianCoresetAlg;
feature_coreset_alg.k = params.NumFeatureClusters;
feature_coreset_alg.t = 50;
feature_coreset_alg.coresetType = KMedianCoresetAlg.linearInK;
feature_coreset_alg.bicriteriaAlg.robustAlg.beta = 1e6;
feature_coreset_alg.bicriteriaAlg.robustAlg.partitionFraction = 0.5;
feature_coreset_alg.bicriteriaAlg.robustAlg.costMethod = ClusterVector.maxDistanceCost;
feature_coreset_alg.bicriteriaAlg.robustAlg.nIterations = 2;
feature_coreset_alg.bicriteriaAlg.robustAlg.gamma = 1e5;
feature_coreset_alg.bicriteriaAlg.robustAlg.figure.sample = false;
feature_coreset_alg.bicriteriaAlg.robustAlg.figure.opt = false;
feature_coreset_alg.bicriteriaAlg.robustAlg.figure.iteration = false;
feature_coreset_save_tree = false;
feature_coreset_leaf_size = 10000;

spmd_feature_coreset = Stream;
spmd_feature_coreset.leafSize = feature_coreset_leaf_size;
spmd_feature_coreset.coresetAlg = feature_coreset_alg;
spmd_feature_coreset.saveTree = feature_coreset_save_tree;
res.spmd_feature_coreset=spmd_feature_coreset;
end
idx=~any(isnan(F));
res.spmd_feature_coreset.addPointSet(PointFunctionSet(Matrix(F(:,idx)')));


end
function [tracklets,graph] = initialize_gtsam_factor_graph(tracklets)

tracklets.graph.poseNoiseSigmas = [0.001 0.001 0.001 0.1 0.1 0.1]';
tracklets.graph.pointNoiseSigma = 0.1;

tracklets.graph.measurementNoiseSigma = 0.01;

tracklets.graph.poseNoise1 = gtsam.noiseModel.Diagonal.Sigmas(tracklets.graph.poseNoiseSigmas);
tracklets.graph.pointPriorNoise  = gtsam.noiseModel.Isotropic.Sigma(3,tracklets.graph.pointNoiseSigma);
tracklets.graph.measurementNoise1 = gtsam.noiseModel.Isotropic.Sigma(2,tracklets.graph.measurementNoiseSigma);
tracklets.graph.pose_keys={};
tracklets.graph.point_keys={};
graph = gtsam.NonlinearFactorGraph;
tracklets.graph.parameters = gtsam.LevenbergMarquardtParams;
tracklets.graph.parameters.setlambdaInitial(1.0);
tracklets.graph.parameters.setVerbosityLM('trylambda');
tracklets.graph.initialEstimate = gtsam.Values;

end
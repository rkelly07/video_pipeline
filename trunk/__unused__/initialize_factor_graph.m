function [tracklets,graph] = initialize_factor_graph(tracklets)
tracklets.graph.poseNoiseSigmas = [0.001 0.001 0.001 0.1 0.1 0.1]';
tracklets.graph.pointNoiseSigma = 0.1;

tracklets.graph.measurementNoiseSigma = 0.01;

tracklets.graph.poseNoise1 = noiseModel.Diagonal.Sigmas(poseNoiseSigmas);
tracklets.graph.pointPriorNoise  = noiseModel.Isotropic.Sigma(3,pointNoiseSigma);
tracklets.graph.measurementNoise1 = noiseModel.Isotropic.Sigma(2,measurementNoiseSigma);
graph = NonlinearFactorGraph;
tracklets.graph.x3keys={}; % for 3D points
tracklets.graph.pkeys={}; % for p
focal=500;
tracklets.graph.calibration_matrix=Cal3DS2(focal,focal,0,320,240,0,0,0,0);
K=[tracklets.graph.calibration_matrix.fx,tracklets.graph.calibration_matrix.skew,tracklets.graph.calibration_matrix.px;...
    0 tracklets.graph.calibration_matrix.fy,tracklets.graph.calibration_matrix.py;...
    0 0 1];

end
clear;
import gtsam.*


%% Create graph container and add factors to it
graph = NonlinearFactorGraph;
focal=500;
calibration_matrix=Cal3DS2(focal,focal,0,320,240,0,0,0,0);
K=[calibration_matrix.fx,calibration_matrix.skew,calibration_matrix.px;...
    0 calibration_matrix.fy,calibration_matrix.py;...
    0 0 1];

%% Add prior
poseNoiseSigmas = [0.001 0.001 0.001 0.1 0.1 0.1]';
pointNoiseSigma = 0.1;

measurementNoiseSigma = 0.01;

poseNoise1 = noiseModel.Diagonal.Sigmas(poseNoiseSigmas);
pointPriorNoise  = noiseModel.Isotropic.Sigma(3,pointNoiseSigma);
% measurementNoise1 = noiseModel.Diagonal.Sigmas([0.1; 0.1]);
measurementNoise1 = noiseModel.Isotropic.Sigma(2,measurementNoiseSigma);
poses=40;
points=15;

% posePriorNoise  = noiseModel.Diagonal.Sigmas(poseNoise1);

x3s={};
for i = 1:points
    x3s{i}=randn(3,1);
    x3keys{i}=symbol('p',i);
    %     graph.add(Point3(x3s{i}(1),x3s{i}(2),x3s{i}(3)));
    %     graph.add(tmpkey,Point3);
end
Rs={};ts={};
cnt=1;
for i = 1:poses
    Rs{i}=randn(3,3)+eye(3)*5;[U,~,V]=svd(Rs{i});Rs{i}=U*V';
    ts{i}=randn(3,1)*40;ts{i}(3)=ts{i}(3)-200;
    pkeys{i}=symbol('x',i);
    for j=1:points
        P=K*[Rs{i},ts{i}];
        PX=P*[x3s{j};1];
        x2=PX(1)/PX(3);y2=PX(2)/PX(3);
        pt2=Point2(x2,y2);
        %        graph.add(symbol(y,cnt),Point2(pt2));
        cnt=cnt+1;
        graph.add(GenericProjectionFactorCal3DS2(pt2,measurementNoise1,pkeys{i},x3keys{j},calibration_matrix)); % add directly to graph
    end
end

for i = 1:2
    graph.add(PriorFactorPose3(pkeys{i}, Pose3(Rot3(Rs{i}),Point3(ts{i})), poseNoise1));
end
% for i = 1:points
% graph.add(PriorFactorPoint3(symbol('p',i), Point3(x3s{i}(1),x3s{i}(2),x3s{i}(3)), pointPriorNoise));
% end
%graph.print(sprintf('\nFactor graph:\n'));

initialEstimate = Values;
for i=1:poses
    pose_i = Pose3(Rot3(Rs{i}),Point3(ts{i}+randn(3,1)*50));
    initialEstimate.insert(symbol('x',i), pose_i);
end
for j=1:points
    point_j = Point3(x3s{j}+randn(3,1));
    initialEstimate.insert(symbol('p',j), point_j);
end
%initialEstimate.print(sprintf('\nInitial estimate:\n  '));

parameters = LevenbergMarquardtParams;
parameters.setlambdaInitial(1.0);
parameters.setVerbosityLM('trylambda');

optimizer = LevenbergMarquardtOptimizer(graph, initialEstimate, parameters);

initial_solution = optimizer.values();
for i=1:500
    optimizer.iterate();
    result = optimizer.values();
    if (mod(i-1,5)==0)
        try
            marginals = Marginals(graph, result);
            cla
            hold on;
            
            plot3DPoints(result, [], marginals);
            plot3DTrajectory(result, '*', 1, 8, marginals);
            
            axis([-40 40 -40 40 -10 20]);axis equal
            view(3)
            colormap('hot')
            drawnow;
        catch
        end
    end
end
result = optimizer.values();
% result.print(sprintf('\nFinal result:\n  '));
%% Plot results with covariance ellipses
marginals = Marginals(graph, result);
cla
hold on;

plot3DPoints(result, [], marginals);
plot3DTrajectory(result, '*', 1, 8, marginals);

axis([-40 40 -40 40 -10 20]);axis equal
view(3)
colormap('hot')

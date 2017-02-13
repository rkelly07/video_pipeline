

%% load video

% for some reason this won't work if you 'clear all'
FILENAME = 'data/test.mp4';

  try
    vr = VideoReader(FILENAME);
  catch
    disp('error')
  end


%% init
BORDER_WIDTH = 20;
options = struct;
options.interference_mask = false([960,1280]);
options.interference_mask((end-70):end,1:400) = true;
options.interference_mask(1:BORDER_WIDTH,:) = true;
options.interference_mask(end+1-(1:BORDER_WIDTH),:) = true;
options.interference_mask(:,1:BORDER_WIDTH) = true;
options.interference_mask(:,end+1-(1:BORDER_WIDTH)) = true;

params = struct;

% feature detection
params.StartFrame = 100;
params.NumFrames = 60;
params.NumStrongestFeatures = 100;
params.MetricThreshold = 2000;
params.NumOctaves = 5;

% k-means
params.NumKMeansClusters = 10;

params


% shorthand
n = params.NumFrames;
k = params.NumKMeansClusters;

P = cell(1,n); % keypoints
F = cell(1,n); % feature descriptors

%% get features
disp(repmat('-',1,80))
disp('computing SURF features')
for i = 1:n
  
  % get frame
  I = read(vr,i+params.StartFrame-1);
  Ihsv = double(rgb2hsv(I));
  H = Ihsv(:,:,3);
  
  % get features
  P{i} = detectSURFFeatures(H,'MetricThreshold',params.MetricThreshold,'NumOctaves',params.NumOctaves);
  [F{i},P{i}] = extractFeatures(H,P{i});
  [F{i},P{i}] = remove_feature_by_mask(F{i},P{i}, options.interference_mask);
  
  disp(['frame ' num2str(i) ': ' num2str(length(P{i})) ' features'])
  
  i = i+1;
end
disp('Done!')

%% kmeans
disp(repmat('-',1,80))
disp('computing kmeans')

% convert frame by frame features into single feature space matrix
Fm = cell2mat(F(:));

% calculate kmeans
Cm = kmeans(Fm,k);

% get clusters for each frame feature
offsets = zeros(1,n);
C = cell(1,n);
C{1} = Cm(1:P{1}.Count);
for i = 2:n
  offsets(i) = offsets(i-1)+P{i-1}.Count;
  C{i} = Cm(offsets(i)+1:offsets(i)+P{i}.Count);
end
disp('Done!')

%%
M = zeros(n,k);
for i = 1:n
  M(i,:) = hist(C{i},1:k);
  M2(i,:) = M(i,:)./sum(M(i,:))*255;
end
figure(200)
image(M')
figure(201)
image(M2')

%% draw
disp(repmat('-',1,80))
DRAW = true;
if DRAW
  i = 50;
  while i <= n
    
    % get frame
    I = read(vr,i+params.StartFrame-1);
    Ihsv = double(rgb2hsv(I));
    H = Ihsv(:,:,3);
    
    % draw
    figure(100), clf
    image(I)
    hold on
    cc = hsv(k);
    idx = C{i};
    for x = 1:k
      Pij = P{i}.Location(idx==x,:);
      plot(Pij(:,1),Pij(:,2),'x','Color',cc(x,:),'LineWidth',2)
    end
    drawnow
    
    disp(['frame ' num2str(i) ': ' num2str(length(P{i})) ' features'])
    
    i = i+1;
    %i = mod(i-1,N)+1;
  end
end



WINDOZE = ~isempty(strfind(computer,'WIN'));

if WINDOZE; BASE_DIR = '\\qonos\RRTO2D3D\study'; else BASE_DIR = '/data/study'; end
VLFEAT_DIR = fullfile(BASE_DIR,'code_deps','vlfeat-0.9.18');
addpath(fullfile(VLFEAT_DIR,'toolbox'));

vl_setup();

addpath(fullfile(VLFEAT_DIR,'apps','recognition'));

%SIFT_DIR = fullfile(BASE_DIR,'reconstruction_cache');
%d = dir(fullfile(SIFT_DIR,'*.sift'));

% IMG_DIR = fullfile(BASE_DIR,'images','bryce3_cam3');
% d = dir(fullfile(IMG_DIR,'*.JPG'));
IMG_DIR = '\\qonos\RRTO2D3D\csail\20140327_161510_5fps';
d = dir(fullfile(IMG_DIR,'*.jpg'));
N = length(d); % num images


%opts.dataset = 'caltech101' ;
%opts.prefix = 'bovw' ;
opts.encoderParams = {'type', 'bovw'} ;
opts.seed = 1 ;
opts.lite = false;
opts.C = 1 ;
opts.kernel = 'linear' ;
opts.Whitening = true;
%opts.dataDir = 'data';
opts.resultDir = fullfile(BASE_DIR,'reconstruction_cache');
opts.cacheDir = fullfile(BASE_DIR,'reconstruction_cache');

%imgPaths = cellfun(@(fname) fullfile(IMG_DIR,fname),{d.name}, 'UniformOutput',false)
randIdxs = randi(N,50,1);
imgPaths = cellfun(@(fname) fullfile(IMG_DIR,fname),{d(randIdxs).name}, 'UniformOutput',false);
tic;
encoder = trainEncoder(imgPaths);
toc

% imagesc(encoder.words);

D = encoder.numWords; % dimensionality of feature vector (encoder-specific?)
N = length(d); % num images
t = (1:N)';
F = zeros(N,D);


filenames = cellfun(@(f) fullfile(IMG_DIR,f), {d.name},'UniformOutput',false);

F = encodeImage(encoder, filenames)';

% for i=1:N
% %parpool(16);
% %parfor i=1:N
%     %filename = fullfile(SIFT_DIR,d(i).name);
%     %[F,D] = vl_ubcread(filename,'FORMAT', 'OXFORD'); % read Lowe's format SIFT files
%  
%     filename = fullfile(IMG_DIR,d(i).name);
%     
% %     % find keypoints
% %     I = rgb2gray(imread(filename));
% %     points = detectSURFFeatures(I);
% %     %imshow(I); hold on; plot(points.selectStrongest(10)); hold off;
% % 
% %     % extract feature descriptors
% %     [features, valid_points] = extractFeatures(I, points);
% %     imshow(I); hold on; plot(valid_points.selectStrongest(10),'showOrientation',true);
% 
%     tic;
%     % bag-of-words: map feature distribution to single vector
%     %F(i,:) = encodeImage(encoder, filename,'cacheDir', opts.cacheDir);
%     F(i,:) = encodeImage(encoder, filename);
%     toc
%     
% end




%min_dt = 5;
min_dt = 20;

K = 30; % should be greater than min_dt?
[neighborIdxs,dists] = knnsearch(F,F,'K',K);
idxs = repmat((1:N)',[1,K]);
pairIdxs = [idxs(:),neighborIdxs(:)];
selfMatchIdxs = pairIdxs(:,1) == pairIdxs(:,2); % no self-matches
largeEnoughBaselineIdxs = diff(t(pairIdxs),[],2).^2 >= min_dt.^2;
pairIdxs = pairIdxs(and(~selfMatchIdxs,largeEnoughBaselineIdxs),1:2);
%t(pairIdxs)
NN = length(pairIdxs);


outfilename = fullfile(BASE_DIR,'reconstruction_cache','putative_match_pairs.txt');
fid = fopen(outfilename,'wt');
for k=1:NN
%for k=randi(NN,1,20)
    i = pairIdxs(k,1);
    j = pairIdxs(k,2);
    f1 = fullfile(IMG_DIR,d(i).name);
    f2 = fullfile(IMG_DIR,d(j).name);
%     img1 = imread(f1);
%     img2 = imread(f2);
%     imshow(cat(2,img1,img2));
%     pause;
%     fprintf('%d<->%d, dt=%d\n',i,j,abs(i-j));
    if(mod(k,1000)==0)
        fprintf('%d th pair (of %d total): %d<->%d, dt=%d\n',k,NN,i,j,abs(i-j));
    end
    %fprintf(fid,'%s %s\n',d(i).name,d(j).name);
    fprintf(fid,'%s %s\n',f1,f2);
end
fclose(fid);



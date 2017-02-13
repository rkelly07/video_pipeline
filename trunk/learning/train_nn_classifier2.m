function res=train_nn_classifier2(inputs,targets)
% load mnist_uint8;
BATCH_SIZE=300;
idx1=rand(size(inputs(1,:)))<0.7;
additional=BATCH_SIZE-mod(sum(idx1),BATCH_SIZE);
idx1b=find(~idx1);idx1b=idx1b(1:additional);idx1(idx1b)=true;
idx2=~idx1;
train_x=inputs(:,idx1)';
train_y=targets(:,idx1)';
test_x=inputs(:,idx2)';
test_y=targets(:,idx2)';
train_x = double(train_x) ;
test_x  = double(test_x)  ;
train_y = double(train_y);
test_y  = double(test_y);

%%  ex1 train a 100 hidden unit RBM and visualize its weights
rng(0);
dbn.sizes = [200];
opts.numepochs =   10;
opts.batchsize = BATCH_SIZE;

opts.momentum  =   0;
opts.alpha     =   1;
dbn = dbnsetup(dbn, train_x, opts);
dbn = dbntrain(dbn, train_x, opts);
figure; visualize(dbn.rbm{1}.W');   %  Visualize the RBM weights

%%  ex2 train a 100-100 hidden unit DBN and use its weights to initialize a NN
rng(0);
%train dbn
dbn.sizes = [300 300 300];
opts.numepochs =   5;
opts.batchsize = 100;
opts.momentum  =   0;
opts.alpha     =   1;
dbn = dbnsetup(dbn, train_x, opts);
dbn = dbntrain(dbn, train_x, opts);

%unfold dbn to nn
nn = dbnunfoldtonn(dbn, size(targets,1));
nn.activation_function = 'sigm';
% nn.trainFcn='traincgp';
%train nn
opts.numepochs =  100;
opts.batchsize = 100;
nn.scaling_learningRate=0.1;
nn = nntrain(nn, train_x, train_y, opts);
[er, bad] = nntest(nn, test_x, test_y);
res.nn=nn;
disp(er)
% assert(er < 0.10, 'Too big error');

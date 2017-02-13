I=imread('cameraman.tif');
im=repmat(double(I),[ 1 1 3]);
caffe=CaffeWrapper(struct('model_def_file','/home/rosman/Downloads/caffe-master/examples/imagenet_deploy.prototxt',...
    'model_data_file','/home/rosman/Downloads/caffe-master/data/caffe_reference_imagenet_model'));
res=caffe.classify_image(im);

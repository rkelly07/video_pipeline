IMAGES_DATA_DIR='/afs/csail/u/r/rosman/data/ArtsQuad_dataset/images/';
RECON_RESULTS_DATA_DIR='/afs/csail/u/r/rosman/data/ArtsQuad_dataset_results';
files=dir(IMAGES_DATA_DIR);
files=[files(3:end)];
num_images=numel(files);
options=[];
options.method='surf';
options.verbose=false;
    image_name1=files(1).name;
    I1=imread([IMAGES_DATA_DIR,filesep,image_name1]);
options.interference_mask=false(size(I1(:,:,1)));
options.tracker=struct('template_scale',17,'search_window_scale',200,'epipolar_scale',1e-4,'min_num_tracklets',1,'minimum_tracking_points',7,'distance_threshold',5,'min_std_normalized',0.05);
bundler_filename=[RECON_RESULTS_DATA_DIR,filesep,'artsquad.disco.out'];
cameras=read_bundler_file(bundler_filename);
features=[];
profile off;profile on
for i_ = 2:num_images
%     camstat1=get_camstat(results_dir,i);
    image_name1=files(i_).name;
    I1=imread([IMAGES_DATA_DIR,filesep,image_name1]);
    tracklets=[];
    old_tracklets=update_tracklets(tracklets,I1,options);
    for j=2:num_images
        if (i_==j)
            continue;
        end
        rdist=sqrt(sum(sum((cameras.cameras{i_}.R'*cameras.cameras{j}.R-eye(3)).^2)));
        if (rdist>0.5)
            continue;
        end
        image_name2=files(j).name;
%         camstat2=get_camstat(results_dir,j);
        I2=imread([IMAGES_DATA_DIR,filesep,image_name2]);
        try
        tracklets=update_tracklets(old_tracklets,I2,options);
        if(min(tracklets.normalized_spatial_std)<0.15) || size(tracklets.features,1)<20
            error('Low spatial spread');
        end
        features=[features;tracklets.features];
        tracklets.old_I=I1;
        tracklets.I=I2;
        I=I2;
        show_points
        drawnow
        try
            disp(['Captured images ',num2str(i_),',',num2str(j),' have ',num2str(size(features,1)),' feature points .']);
        catch
        end
        catch
%             try
%             imshow([I1,I2],[]);drawnow;
%             catch
%             end
%             disp(['Images ',num2str(i_),',',num2str(j),' are too far apart, or not enough matches.']);
        end
    end
end

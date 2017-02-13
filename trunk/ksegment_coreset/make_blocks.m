load my_video1_results.mat
bow1 = bags_of_words;
idx1 = processed_frame_idx;
load my_video2_results.mat
bow2 = bags_of_words;
idx2 = processed_frame_idx;
load my_video3_results.mat
bow3 = bags_of_words;
idx3 = processed_frame_idx;
bow = [bow1; bow2; bow3];
idx2 = idx2+max(idx1);
idx3 = idx3+max(idx2);
idx = [idx1; idx2; idx3];
idx = idx(1:size(bow,1));

bow0 = bow;
block_no = 0;
while block_no < 256
  block_no = block_no+1
  while size(bow,1) < 10000
    bow = [bow; bow0];
  end
  size(bow,1)
  S = bow(1:10000,:);
  save(['test_blocks/block' num2str(block_no) '.mat'],'S')
  bow = bow(10001:end,:);
end

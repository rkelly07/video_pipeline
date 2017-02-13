function pairs=positive_pairs(labeled_frames, segment_width, frames_per_segment)
pairs=[];
for label_num=1:numel(labeled_frames);
    frame_num=labeled_frames(1, label_num);
    if frame_num>segment_width/2
        segment=frame_num+randperm(segment_width, frames_per_segment)-segment_width/2;
    else
        segment=frame_num+randperm(segment_width/2, frames_per_segment);
    end
    segments(1:(frames_per_segment), label_num)=segment;
end

for seg_num=1:numel(labeled_frames)
    seg=segments(:, seg_num);
    for frame_num=1:frames_per_segment-1
        new_pairs=[seg circshift(seg, frame_num)];
        pairs=vertcat(pairs, new_pairs); 
    end
end
end
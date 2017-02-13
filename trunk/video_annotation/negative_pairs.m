function pairs=negative_pairs(labeled_frames, segment_width, frames_per_segment, number_closest_labels, max_distance)
%takes pre-sorted labeled frames, turns them into pairs of frame numbers
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
seg_pairs=segment_pairs(labeled_frames, number_closest_labels, max_distance);
number_pairs=size(seg_pairs, 1);
for pair_num =1:number_pairs
    first_seg=segments(:, seg_pairs(pair_num, 1)); 
    second_seg=segments(:, seg_pairs(pair_num, 2));
    for frame_num=1:frames_per_segment
        new_pairs=[first_seg circshift(second_seg, frame_num)];
        pairs=vertcat(pairs, new_pairs); 
    end

end
end

function [list_of_pair_indices]=segment_pairs(frames, number_closest_labels, max_distance)
%returns n by 2 matrix of INDICES (column numbers, not frames)
list_of_pair_indices=[];
for i=1:numel(frames)
    for j=(i+1):min(numel(frames), i+number_closest_labels)
        if frames(j)-frames(i)< max_distance
            list_of_pair_indices(end+1, 1:2)=[i j];
        else
            break
        end
    end
end
end
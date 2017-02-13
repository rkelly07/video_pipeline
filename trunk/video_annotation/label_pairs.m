function [list_of_pairs_by_file]=label_pairs(userdata, pos_or_neg, segment_width, frames_per_segment, number_closest_labels, max_distance)
labels_by_filename=label_retriever(userdata);
filenames=labels_by_filename.keys;
segments_by_filename=containers.Map();
list_of_pairs_by_file=struct();
for i=1:numel(filenames)
    filename=filenames(i);
    labels=labels_by_filename(filename{:});
    frames=cell2mat(labels(1, :));
    frames=sort(frames);
    switch pos_or_neg
        case 'positive'
            pairs=positive_pairs(frames, segment_width, frames_per_segment);
        case 'negative'
            pairs=negative_pairs(frames, segment_width, frames_per_segment, number_closest_labels, max_distance);
        otherwise
            disp('Indicate positive or negative')
            break
    end
%     output=struct(filename{:}(1:end-4), pairs);
%     list_of_pairs_by_file{i}=output;
    list_of_pairs_by_file = setfield(list_of_pairs_by_file, filename{:}(1:end-4) ,pairs);
end


end


function labs=label_retriever(userdata)
keys=userdata.labels.keys;
values=userdata.labels.values;
frames_and_labels=mat2cell(zeros(2, numel(keys)), 2, numel(keys));
for keynum=1:numel(keys)
        value=values{keynum};
        frams=arrayfun(@(i) value{i}.frame, 1:numel(value), 'UniformOutput', false);
        labs=arrayfun(@(i) value{i}.label, 1:numel(value), 'UniformOutput', false);
        frames_and_labels{keynum}=[frams; labs];
end
labs = containers.Map(keys, frames_and_labels);
end


classdef NaiveBayesClassifier
properties
    class_examples;
    num_classes;
    search_objs;
end
methods
    function obj=NaiveBayesClassifier(class_examples_)
        obj.class_examples=class_examples_;
        obj.num_classes=numel(obj.class_examples);
        obj.search_objs=cell(obj.num_classes,1);
        for i = 1:obj.num_classes
            if (isempty(obj.class_examples{i}))
                continue;
            end
            obj.search_objs{i}=KDTreeSearcher(obj.class_examples{i});
        end
    end
    function obj=addExamples(obj,class,class_examples_)
        % TODO - currently I recreate the KD-tree, need something more
        % efficient
        obj.class_examples{class}=[obj.class_examples{class};class_examples_];
        obj.search_objs{class}=KDTreeSearcher(obj.class_examples{class});
    end    
    function [cmin,logps]=compute_classification(obj,bag_of_descriptors)
        for c=1:obj.num_classes
            logps(c)=compute_NB_score(obj.search_objs{c},bag_of_descriptors);
        end
        [~,cmin]=max(logps);
%         ps=ps;
    end    
end
end

    function logps=compute_NB_score(search_obj,bag_of_descriptors)
        [idx,d]=search_obj.knnsearch(bag_of_descriptors,'K',1);
        logps=-sum(d.^2);
    end

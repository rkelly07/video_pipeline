classdef CoresetSegment < handle
  %CoreSegment Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (SetAccess = protected)
    
    d       % dimension R^d
    n       % num points represented
    t1      % signal start time
    t2      % signal end time
    num_keypoints % number of keypoints (cached)
    % all your coresets
    coresets
    
  end
  
  %% methods
  methods
    function flushCache(this)
        this.num_keypoints=-1;
    end
    
    % constructor
    function this = CoresetSegment(t1,t2)
      
      this.n = t2-t1+1;
      this.t1 = t1;
      this.t2 = t2;
      
      this.flushCache();
      this.coresets = containers.Map();
      
    end
    
    % add coreset to dictionary using the name of the class as the key
    function addCoreset(this,C)
      %assert(all([this.t1 this.t2]==[C.t1 C.t2]))
      this.flushCache();
      this.d = C.d;
      this.coresets(class(C)) = C;
      
    end

    % copy segment
    function new = copy(this)
      
      new = CoresetSegment(this.t1,this.t2);
      new.d = this.d;
      
      coreset_values = this.coresets.values();
      for i = 1:this.coresets.length 
        new_coreset = coreset_values{i};
        new.addCoreset(new_coreset);
      end
      
    end
    
    function keypoints = getNumKeypoints(this)
        if (this.num_keypoints>=0)
            keypoints=this.num_keypoints;
        else
      keypoints = 0; 
      coreset_values = this.coresets.values();
      for i = 1:this.coresets.length 
        new_kps = coreset_values{i}.getNumKeypoints();
        if (new_kps>keypoints)
            keypoints = new_kps;
        end
      end
      this.num_keypoints=keypoints;
        end
    end
    
  end
  
end


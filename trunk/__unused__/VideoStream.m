% video stream wrapper
classdef VideoStream < handle
  
  properties(Access=protected)
    
    video_reader;
    
  end
  
  properties(SetAccess=protected)
    
    Filename;
    IsActive;
    StartFrame;
    CurrFrame;
    NextFrame;
    NumFrames;
    InterferenceMask;
    ImgBuffer;
    ImgBufferIndices;
    
    Raw = false;
    raw_frames = []
    
  end
  
  methods
    
    %% constructor
    function this = VideoStream(filename,varargin)
      
      % parse input
      p = inputParser;
      addParamValue(p,'StartFrame',1,@isnumeric)
      parse(p,varargin{:});
      
      [~,~,ext] = fileparts(filename);
      if strcmp(ext,'.mat')
        load(filename)
        I = bags_of_words;
        this.raw_frames = I;
        this.NumFrames = size(I,4);
        this.Raw = true;
      else
        
        % init video reader
        try
          this.video_reader = VideoReader(filename);
          this.NumFrames = this.video_reader.NumberOfFrames;
        catch e
          warning(e.identifier,e.message)
        end
        
      end
      
      % init properties
      this.Filename = filename;
      this.IsActive = true;
      this.StartFrame = p.Results.StartFrame;
      this.CurrFrame = 0;
      this.NextFrame = this.StartFrame;
      
      this.ImgBuffer=[];
      this.ImgBufferIndices=[];
      % init interference mask
      border_width = 20;
      this.InterferenceMask = false([960,1280]);
      this.InterferenceMask((end-70):end,1:400) = true;
      this.InterferenceMask(1:border_width,:) = true;
      this.InterferenceMask(end+1-(1:border_width),:) = true;
      this.InterferenceMask(:,1:border_width) = true;
      this.InterferenceMask(:,end+1-(1:border_width)) = true;
      
    end
    
    function this=set_next_frame(this,idx)
      this.NextFrame=idx;
    end
    
    %% get next frame in the video
    function [I,frame_ind] = get_next_frame(this)
      
      I = [];
      frame_ind = 0;
      
      if ~this.IsActive
        warning('Reached end of stream!')
        return
      end
      
      this.CurrFrame = this.NextFrame;
      
      try
        if (isempty(this.ImgBuffer) || ~ismember(this.CurrFrame,this.ImgBufferIndices))
          this.ImgBufferIndices=unique(min(this.CurrFrame+(0:20),this.NumFrames));
          
          if this.Raw
            this.ImgBuffer = this.raw_frames(:,:,:,this.ImgBufferIndices(1:end));
          else
            this.ImgBuffer = read(this.video_reader,[this.ImgBufferIndices(1),this.ImgBufferIndices(end)]);
          end
          
          this.ImgBufferIndices=this.ImgBufferIndices(1)+(1:(size(this.ImgBuffer,4)))-1;
        end
        idx= this.ImgBufferIndices==this.CurrFrame;
        I=this.ImgBuffer(:,:,:,idx);
      catch e
        warning(e.identifier,e.message)
      end

%       try
%         if this.Raw
%           I = this.raw_frames(:,:,:,this.CurrFrame);
%         else
%           I = read(this.video_reader,this.CurrFrame);
%         end
%       catch e
%         warning(e.identifier,e.message)
%       end

      frame_ind = this.CurrFrame;
      
      this.NextFrame = this.NextFrame+1;
      
      if this.NextFrame > this.NumFrames
        this.IsActive = false;
      end
      
    end
    
    %% get frame out of sequence, does not affect stream
    function I = get_frame(this,frame_ind)
      
      if this.Raw
        I = this.raw_frames(:,:,:,frame_ind);
      else
        I = read(this.video_reader,frame_ind);
      end
      
    end
    
    %% get next n frames
    function [I,frame_ind] = get_next_nframes(this,n)
      
      I = {};
      frame_ind = [];
      
      for i = 1:n
        if this.IsActive
          [curr_I,curr_frame_ind] = this.get_next_frame();
          I = cat(1,I,curr_I);
          frame_ind = cat(1,frame_ind,curr_frame_ind);
        else
          warning(['Reached end of stream! '...
            'Returning ' num2str(i-1) ' of ' num2str(n) ' frames'])
          return
        end
      end
      
    end
    
  end % methods
  
end % classdef

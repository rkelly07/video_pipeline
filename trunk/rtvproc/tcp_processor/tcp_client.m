classdef rtvproc_client < handle
 
  properties (Access = protected)
    
  end

  properties (SetAccess = protected)
    InputBufferSize
    BytesAvailable
  end
  
  properties
    htcp
    host
    port
    
    msg_keys = {...
      'RTIMPROC_TX_BEGIN',...
      'RTIMPROC_TX_END',...
      'RTIMPROC_TX_RESET',...
      'RTIMPROC_FRAME_SZ',...
      'RTIMPROC_HIST_SZ',...
      'RTIMPROC_FRAME_IDX',...
      'RTIMPROC_FRAME_RQ',...
      'RTIMPROC_FRAME_RX',...
      'RTIMPROC_HIST_RQ',...
      'RTIMPROC_HIST_RX',...
      'RTIMPROC_FEAT_SZ',...
      'RTIMPROC_FEAT_RQ',...
      'RTIMPROC_FEAT_RX',...
      'RTIMPROC_ACK',...
      }
      
    msg_values = {...
      'AA01',...
      'AA02',...
      'AA04',...
      'AA11',...
      'AA12',...
      'AA21',...
      'AA41',...
      'AA42',...
      'AA81',...
      'AA82',...
      'AA31',...
      'AA32',...
      'AA34',...
      'AAFF',...
      }
    
    msg_encode_map
    msg_decode_map
    
  end
  
  methods
     
    function this = rtvproc_client(host,port)
    
      this.host = host;
      this.port = port;
      
      this.htcp = tcpip(this.host,this.port,'NetworkRole','client');
      set(this.htcp,'InputBufferSize',1048576); % 1 MB
      fopen(this.htcp);
      
      this.msg_encode_map = containers.Map(this.msg_keys, this.msg_values);
      this.msg_decode_map = containers.Map(this.msg_values, this.msg_keys);
      
    end
    
    function close(this)
      fclose(this.htcp);
    end
    
    function sz = get.InputBufferSize(this)
      sz = get(this.htcp,'InputBufferSize');
    end
    
    function b = get.BytesAvailable(this)
      b = this.htcp.BytesAvailable;
    end
    
    % write encoded message 
    function write_msg(this,tx_msg_key)
      
      tx_msg = this.msg_encode_map(tx_msg_key);
      
      msg_bytes(1) = typecast(uint16(sscanf(tx_msg(3:4),'%x')),'uint16');
      msg_bytes(2) = typecast(uint16(sscanf(tx_msg(1:2),'%x')),'uint16');
      
      fwrite(this.htcp,msg_bytes);
      
    end
    
    function b = wait_for_bytes(this)
      b = this.htcp.BytesAvailable;
      while (b == 0)
        % wait
        b = this.htcp.BytesAvailable;
      end
    end
    
    % read encoded message 
    function rx_msg = read_msg(this)

      this.wait_for_bytes();
      
      rx_data = fread(this.htcp,this.htcp.BytesAvailable);
      rx_str = dec2hex(rx_data);
      rx_msg = [rx_str(2,:) rx_str(1,:)];

    end
    
    % verify encoded message
    function verify_msg(this,rx_msg,key)
      
      status = strcmp(this.msg_decode_map(rx_msg),key);
      if status == 0
        error(['received message: ' rx_msg])
      end
      
    end

    % read encoded message 
    function rx_data = read_data(this,bytes)
      
      this.wait_for_bytes();
      
      if bytes == 0
        bytes = this.htcp.BytesAvailable;
      end

      rx_data = fread(this.htcp,bytes);

    end
    
    % decode uint32
    function uint32 = decode_uint32(this,bytes)
      uint32 = bytes(1) + bytes(2)*2^8 + bytes(3)*2^16 + bytes(4)*2*24;
    end
    
    
  end
  
end
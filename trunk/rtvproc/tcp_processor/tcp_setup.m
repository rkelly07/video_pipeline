% ################################################################################
% setup

host = options.Host;
port = options.Port;
data_dir = options.DataDir;

server_start_cmd = ['./RTVideoProcessingServer ' num2str(port) ' ' [data_dir 'vq66.csv'] ' ' [data_dir video_filename] ' &'];
disp(['starting server: ' server_start_cmd])
system(server_start_cmd);
pause(1)
disp('Done!')

if exist('tcp_client ','var')
    tcp_client.close()
end

tcp_client = rtvproc_client(host,port);
% tcp_client = rtvproc_client(host,port);
% tcp_client = rtvproc_client(host,port);
% tcp_client h = mex_video_processing('init',video_filename,VQs);
% num_frames = mex_video_processing('getframecount',h);
num_frames = inf;

% mex_video_processing('deinit',h); = rtvproc_client(host,port);
% tcp_client = rtvproc_client(host,port);

% session request
tcp_client.write_msg('RTIMPROC_TX_BEGIN')
rx_message = tcp_client.read_msg();
tcp_client.verify_msg(rx_message,'RTIMPROC_ACK')

% get frame size
tcp_client.write_msg('RTIMPROC_FRAME_SZ')
frame_rows = tcp_client.decode_uint32(tcp_client.read_data(4))
frame_cols = tcp_client.decode_uint32(tcp_client.read_data(4))

% get hist size
tcp_client.write_msg('RTIMPROC_HIST_SZ')
hist_size = tcp_client.decode_uint32(tcp_client.read_data(4))

bags_of_words = [];
curr_frame = 0;
processed_frame_idx = [];

figure(100)

% ################################################################################

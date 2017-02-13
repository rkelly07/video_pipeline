%% setup

if exist('tcp_client ','var')
  tcp_client.close()
end
myclear, close all, clc

host = '127.0.0.1';
port = 5562 ;
data_dir = '~/Desktop/SOURCE_DATA/';

features_enabled = true;

%%

server_start_cmd = ['./RTVideoProcessingServer ' num2str(port) ' -vq ' [data_dir 'vq66.csv']];
if features_enabled
  server_start_cmd = [server_start_cmd ' --feat'];
end
server_start_cmd = [server_start_cmd ' &'];

disp(['starting server: ' server_start_cmd])
system(server_start_cmd);

%%

tcp_client = rtvproc_client(host,port);
% tcp_client = rtvproc_client('127.0.0.1',5555);
% tcp_client = rtvproc_client('128.30.7.13',5556);
% tcp_client = rtvproc_client('128.30.5.153',5556);
% tcp_client = rtvproc_client('10.189.97.5',5556);
% tcp_client = rtvproc_client('18.111.4.242',5556);

% session request
tcp_client.write_msg('RTIMPROC_TX_BEGIN')
rx_message = tcp_client.read_msg();
tcp_client.verify_msg(rx_message,'RTIMPROC_ACK')

% get frame size
tcp_client.write_msg('RTIMPROC_FRAME_SZ')
frame_width = tcp_client.decode_uint32(tcp_client.read_data(4))
frame_height = tcp_client.decode_uint32(tcp_client.read_data(4))

% get hist size
tcp_client.write_msg('RTIMPROC_HIST_SZ')
hist_size = tcp_client.decode_uint32(tcp_client.read_data(4))

bags_of_words = [];
processed_frame_idx = [];
figure(100)
start_time = tic;

%% loop

while 1
  
  figure(100),clf
 
  %-------------------------------------------------------------
  % get frame idx
  
  tcp_client.write_msg('RTIMPROC_FRAME_IDX')
  curr_frame = tcp_client.decode_uint32(tcp_client.read_data(4));
  disp(['frame idx ' num2str(curr_frame)])
  processed_frame_idx = cat(1,processed_frame_idx,curr_frame);
  
  %-------------------------------------------------------------
  % get frame
  
  % send frame request
  tcp_client.write_msg('RTIMPROC_FRAME_RQ')
  
  bytes_received = 0;
  bytes_expected = frame_width*frame_height*3;
  img_data = zeros(bytes_expected,1);
  while bytes_received < bytes_expected
    b = tcp_client.wait_for_bytes();
    rx_data = tcp_client.read_data(b);
    img_data(bytes_received+1:bytes_received+b) = rx_data;
    bytes_received = bytes_received+b;
  end
  
  img_data = permute(reshape(img_data,[3 frame_width frame_height]),[3 2 1]);
  img_data = img_data(:,:,[3 2 1]);
  I = img_data./255;

  % send frame rx
  tcp_client.write_msg('RTIMPROC_FRAME_RX')
  rx_message = tcp_client.read_msg();
  tcp_client.verify_msg(rx_message,'RTIMPROC_ACK')
  
  %-------------------------------------------------------------
  % get hist
  
  % send frame request
  tcp_client.write_msg('RTIMPROC_HIST_RQ')
  
  bytes_received = 0;
  bytes_expected = hist_size*4;
  hist_data = zeros(bytes_expected,1);
  while bytes_received < bytes_expected
    b = tcp_client.wait_for_bytes();
    rx_data = tcp_client.read_data(b);
    hist_data(bytes_received+1:bytes_received+b) = rx_data;
    bytes_received = bytes_received+b;
  end
  
  hist = zeros(1,hist_size);
  hist_data = reshape(hist_data,[4 hist_size])';
  for i = 1:hist_size
    hist(i) = tcp_client.decode_uint32(hist_data(i,:));
  end
  B = hist./sum(hist);
  bags_of_words = cat(1,bags_of_words,B);
  
  % send frame rx
  tcp_client.write_msg('RTIMPROC_HIST_RX')
  rx_message = tcp_client.read_msg();
  tcp_client.verify_msg(rx_message,'RTIMPROC_ACK')
  
  %-------------------------------------------------------------
  % get features
  
  if features_enabled
  
    % get feat size
    tcp_client.write_msg('RTIMPROC_FEAT_SZ')
    feat_size = tcp_client.decode_uint32(tcp_client.read_data(4));

    % send feat request
    tcp_client.write_msg('RTIMPROC_FEAT_RQ')

    bytes_received = 0;
    bytes_expected = feat_size*8;
    feat_data = zeros(bytes_expected,1);
    while bytes_received < bytes_expected
      b = tcp_client.wait_for_bytes();
      rx_data = tcp_client.read_data(b);
      feat_data(bytes_received+1:bytes_received+b) = rx_data;
      bytes_received = bytes_received+b;
    end

    feat_x = zeros(1,feat_size);
    feat_y = zeros(1,feat_size);
    feat_data = reshape(feat_data,[8 feat_size])';
    for i = 1:feat_size
      feat_x(i) = tcp_client.decode_uint32(feat_data(i,1:4));
      feat_y(i) = tcp_client.decode_uint32(feat_data(i,5:8));
    end

    % send frame rx
    tcp_client.write_msg('RTIMPROC_FEAT_RX')
    rx_message = tcp_client.read_msg();
    tcp_client.verify_msg(rx_message,'RTIMPROC_ACK')
  
  end
  
  %-------------------------------------------------------------
  % plot
  
  subplot(2,2,1), hold on
  imshow(I), title(['received frame ' num2str(curr_frame)])
  if features_enabled
    scatter(feat_x,feat_y,'xy')
  end
  
  subplot(2,2,3:4)
  
  % display last n bow vectors
  num_last_frames = 500;
  
  % pick k_disp best clusters to display
  k_disp = 100;
  [~,sorted_idx] = sort(sum(bags_of_words,1));
  best_idx = sorted_idx(end:-1:end-k_disp+1);
  
  lastn_bows = bags_of_words(:,best_idx).*255;
  if size(lastn_bows,1) <= num_last_frames
    lastn_bows = cat(1,lastn_bows,zeros(num_last_frames-size(lastn_bows,1),k_disp));
  else
    lastn_bows = lastn_bows(end-num_last_frames+1:end,:);
  end
  
  % boost color display
  lastn_bows = lastn_bows.*10;
  image(lastn_bows');
  
  % display best clusters
  %   set(gca,'xtick',1:frame_idx)
  %   set(gca,'XTickLabel',num2str((max(frame_idx-num_last_frames+1,1):frame_idx)'))
  %   set(gca,'ytick',1:k_disp)
  %   set(gca,'YTickLabel',num2str(best_idx'))
  
  drawnow
  
  if mod(curr_frame,100) == 0
    disp([num2str(toc(start_time)/60) ' minutes elapsed'])
  end
  
end


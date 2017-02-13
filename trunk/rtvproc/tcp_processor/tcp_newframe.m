% ################################################################################
% loop

figure(100),clf

% -------------------------------------------------------------
% get frame idx

tcp_client.write_msg('RTIMPROC_FRAME_IDX')
curr_frame = tcp_client.decode_uint32(tcp_client.read_data(4));
% disp(['frame idx ' num2str(curr_frame)])
processed_frame_idx = cat(1,processed_frame_idx,curr_frame);
webcam
% -------------------------------------------------------------
% get frame

% send frame request
tcp_client.write_msg('RTIMPROC_FRAME_RQ')

bytes_received = 0;
bytes_expected = frame_rows*frame_cols*3;
img_data = zeros(bytes_expected,1);
while bytes_received < bytes_expected
    b = tcp_client.wait_for_bytes();
    rx_data = tcp_client.read_data(b);
    img_data(bytes_received+1:bytes_received+b) = rx_data;
    bytes_received = bytes_received+b;
end

img_data = permute(reshape(img_data,[3 frame_cols frame_rows]),[3 2 1]);
img_data = img_data(:,:,[3 2 1]);
I = img_data./255;

% send frame rx
tcp_client.write_msg('RTIMPROC_FRAME_RX')
rx_message = tcp_client.read_msg();
tcp_client.verify_msg(rx_message,'RTIMPROC_ACK')

% -------------------------------------------------------------
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

B2 = hist./sum(hist);
if sum(hist) == 0
    B2 = hist./max(0.1,sum(hist));
end

% bags_of_words = cat(1,bags_of_words,B);

% send frame rx
tcp_client.write_msg('RTIMPROC_HIST_RX')
rx_message = tcp_client.read_msg();
tcp_client.verify_msg(rx_message,'RTIMPROC_ACK')

% -------------------------------------------------------------
% get features

% get hist size
tcp_client.write_msg('RTIMPROC_FEAT_SZ')
feat_size = tcp_client.decode_uint32(tcp_client.read_data(4));

% send frame request
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

% ################################################################################

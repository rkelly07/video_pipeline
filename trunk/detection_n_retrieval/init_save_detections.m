setup_server;

% each field in persisten_data will be unpacked
% to a variable with the same name
fields = fieldnames(persistent_data);
for i = 1:length(fields)
    s = fields{i};
    fprintf('Unpacking persistent data: %s\n',s)
    cmd = [s ' = persistent_data.' s ';'];
    eval(cmd);
end
descriptor_dim = size(VQ,2);

%% init stream
disp('Initializing video stream ...');

% process rescale size
rescale_size = params.RescaleSize;
if isempty(params.RescaleSize)
    rescale_size = [0 0];
end
if any(rescale_size == -1)
    if all(rescale_size == -1)
        rescale_size = [0 0];
    elseif rescale_size(1) == -1
        rescale_size(1) = round(params.VideoInfo.Width*(rescale_size(2)/params.VideoInfo.Height));
    elseif rescale_size(2) == -1
        rescale_size(2) = round(params.VideoInfo.Height*(rescale_size(1)/params.VideoInfo.Width));
    end
end  
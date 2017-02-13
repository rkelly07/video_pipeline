function color_array = frameResColor( stats_in )

color_array = repmat(rgb('Blue'), size(stats_in,2), 1);

smallFrame = 640;  %[640 480];
medFrame   = 1920; %[1920 1080];
largeFrame = 3840; %[3840 2880];

for ii = 1: size(stats_in,2)
    switch stats_in(ii).res(1)
        case smallFrame
            color_array(ii,:) = rgb('Blue');
        case medFrame
            color_array(ii,:) = rgb('Green');
        case largeFrame
            color_array(ii,:) = rgb('Cyan');
    end
end


return
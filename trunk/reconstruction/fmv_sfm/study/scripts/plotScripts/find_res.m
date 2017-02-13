function [res_small, res_med, res_large] = find_res( stats_in )



smallFrame = 640;  %[640 480];
medFrame   = 1920; %[1920 1080];
largeFrame = 3840; %[3840 2880];

res_small = false(1, size(stats_in,2));
res_med   = false(1, size(stats_in,2));
res_large = false(1, size(stats_in,2));

for ii = 1: size(stats_in,2)
    switch stats_in(ii).res(1)
        case smallFrame
            res_small(ii) = true;
        case medFrame
            res_med(ii)   = true;
        case largeFrame
            res_large(ii) = true;
    end
end


return
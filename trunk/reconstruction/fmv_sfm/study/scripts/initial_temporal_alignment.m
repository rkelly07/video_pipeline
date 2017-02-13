% automatically figure out timestamps for the pics using GPS/INS data,
% under basic assumption that pics run from take-off to touch-down and that
% some field/function of the GPS/INS data can also reliably distinguish take-off and touch-down
%
% t_pics: timestamps of each pic
% t_ins: timestamps of the GPS/INS data
% X_ins: positions [x(t),y(t),z(t)] given by GPS/INS
% f_ins: whatever function f(t) we think has zero-crossings/minima at take-off and touch-down (e.g., speed, altitude)

% t_pics_corrected: timestamps of each pic, but now aligned to reference temporal frame (i.e., t_ins)
function [X_pics,t_pics_corrected,delta_t] = initial_temporal_alignment(t_pics,t_ins,X_ins,f_ins)

    dt_ins = mean(diff(t_ins));
    
    dt_pics = 0.5; % 2 Hz % FIXME: don't hard-code
    % FIXME: 2 Hz below? 120 below?
    
    T_pics = length(t_pics) * dt_pics; % duration of time pics were snapped
    
    % window during which time pics were snapped at 2 Hz
    kernel = ones( 1, ceil(T_pics./dt_ins) );
    kernel = conv(kernel, gausswin(ceil(120./dt_ins))); % FIXME: don't hard-code kernel width
    kernel = [kernel,zeros(1,length(t_ins)-length(kernel))];
    %kernel = kernel ./ sum(kernel);

    % cross-correlate window with speed (appears to be the most reliable piece of metadata to distinguish take-off and landing via zero-crossing
    %t_pics = ( ( 1:length(d) ) - 1 ) / 2;
    %figure; plot(kernel); hold on; plot(X_ins(:,3),'r--'); hold off
    %figure; plot(conv(X_ins(:,3),kernel));
    figure; plot(xcorr(f_ins,kernel));
    %[corrs,lags] = xcorr(X_ins(:,3),kernel);
    [corrs,lags] = xcorr(f_ins,kernel);
    [~,maxIdx] = max(corrs);
    delta_t = lags(maxIdx) * dt_ins;
    %figure; plot(t_perdix,X_perdix(:,3),t_perdix+delta_t,kernel);
    figure; plot(t_ins,f_ins,t_ins+delta_t,kernel);

    t_pics_corrected = t_pics + delta_t;
    X_pics = zeros(length(t_pics),3);
    X_pics(:,1) = interp1(t_ins,X_ins(:,1),t_pics_corrected,'pchip','extrap');
    X_pics(:,2) = interp1(t_ins,X_ins(:,2),t_pics_corrected,'pchip','extrap');
    X_pics(:,3) = interp1(t_ins,X_ins(:,3),t_pics_corrected,'pchip','extrap');
    %X(:,3) = interp1(t_perdix,z_hat,t,'pchip','extrap');


    figure; plot3(X_ins(:,1),X_ins(:,2),X_ins(:,3),'b-'); axis equal; % viz
    hold on; plot3(X_pics(:,1),X_pics(:,2),X_pics(:,3),'r.'); hold off;
    legend('Trajectory','Snapshots');
    title('Locations of snapshots after (rough,initial) temporal alignment');

end

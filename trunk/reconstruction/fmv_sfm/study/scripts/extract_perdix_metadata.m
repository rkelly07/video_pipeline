function extract_perdix_metadata(perdixLogFilename,imageDir,outFilename)

    % testing
    perdixLogFilename = '\\qonos\RRTO2D3D\study\truth\Log_GNC01_7.mat';
    outFilename = '\\qonos\RRTO2D3D\study\truth\DataCollect_3.metadata';
    frameDir = 'F:\RRTO2D3D\bryce\DataCollect_3\GoPro_3';
    
    load(perdixLogFilename);

    % convert lat/long/alt to UTM coords
    [lat0,long0,alt0] = deal(GPS.parsed.nav.lat(1),GPS.parsed.nav.long(1),GPS.parsed.nav.alt(1));
    [x,y,z] = geodetic2enu(GPS.parsed.nav.lat,GPS.parsed.nav.long,GPS.parsed.nav.alt,lat0,long0,alt0,wgs84Ellipsoid);
    figure; plot3(x,y,z,'b.'); axis equal; % viz
    X = [x;y;z]';
    
    t0 = GPS.parsed.nav.ts(1);
    t = GPS.parsed.nav.ts - t0;
    
    % convert initial lat/long to UTM
    ll0 = [lat0,long0];
    zone0 = utmzone(ll0);
    [ellipsoid,~] = utmgeoid(zone0);
    utmstruct = defaultm('utm'); 
    utmstruct.zone = zone0; 
    utmstruct.geoid = ellipsoid; 
    utmstruct = defaultm(utmstruct);
    [x0,y0] = mfwdtran(utmstruct,lat0,long0);
    z0 = alt0;
    
    X = bsxfun(@plus,X,[x0,y0,z0]);
    t = t + t0;
    
    % alternate method
%     [x,y] = mfwdtran(utmstruct,GPS.parsed.nav.lat,GPS.parsed.nav.long);
%     z = GPS.parsed.nav.alt;
%     X = [x;y;z]';

    % intial temporal alignment of pics to perdix GPS readings
    speed = sqrt(sum( [GPS.parsed.nav.ecefvx;GPS.parsed.nav.ecefvy;GPS.parsed.nav.ecefvz].^2 ))';
    %f_ins = speed .* X(:,3); % this function should let us distinguish take-off/touch-down from flight
    f_ins = speed; % this function should let us distinguish take-off/touch-down from flight
    [t_pics,t0_pics,filenames] = read_frame_timestamps(frameDir);
    [X_pics,t_pics,delta_t] = initial_temporal_alignment(t_pics,t,X,f_ins);
    
%     t = t_pics + delta_t;
%     X = zeros(length(t_pics),3);
%     X(:,1) = interp1(t_perdix,X_perdix(:,1),t,'pchip','extrap');
%     X(:,2) = interp1(t_perdix,X_perdix(:,2),t,'pchip','extrap');
%     X(:,3) = interp1(t_perdix,X_perdix(:,3),t,'pchip','extrap');

    N = size(X,1);

    U = zeros(N,3); % FIXME: properly extract UAV orientation info!
    V = zeros(N,3); % FIXME: properly extract camera pointing info!
    
    
    hdrStr = '# image_filename   epoch (secs) UAV_easting UAV_northing UAV_alt  UAV_heading UAV_pitch UAV_bank tgt_easting  tgt_northing  tgt_alt';
    %filenames = repmat({'FIXME.jpg'},[N,1]); % FIXME: do temporal registration to frames
    
    % write file
    fid = fopen(outFilename,'wt');
    fprintf(fid,'%s\n\n',hdrStr);
    for i=1:length(filenames)
        fprintf(fid, ...
                    '%s %.4f %.2f %.2f %.2f %.8f %.8f %.8f %.2f %.2f %.2f\n', ...
                    filenames{i},t_pics(i), ...
                    X_pics(i,1),X_pics(i,2),X_pics(i,3), ...
                    U(i,1),U(i,2),U(i,3), ...
                    V(i,1),V(i,2),V(i,3) ...
                );
    end
    fclose(fid);

end


function [t_pics,t0,filenames] = read_frame_timestamps(frameDir)

    d = dir(fullfile(frameDir,'*.jpg'));

    % populate t_pics by reading times for pics from EXIF info
    dates = zeros(length(d),length(datevec(now)));
    t_pics = zeros(length(d),1);
    filenames = cell(length(d),1);
    for i=1:length(d)
        filenames{i} = d(i).name;
        fprintf('Working on %s : %d of %d (%.2f%%)\n',filenames{i},i,length(d),100*i/length(d));
        imgInfo = imfinfo(fullfile(frameDir,d(i).name));
        dates(i,:) = datevec(imgInfo.DigitalCamera.DateTimeOriginal,'yyyy:mm:dd HH:MM:SS');
        t_pics(i) = etime(dates(i,:),dates(1,:));
    end
    t_pics([false;diff(t_pics)==0]) = t_pics([false;diff(t_pics)==0]) + 0.5; % fix multiple pics having same timestamp due to 1-second resolution of stored time
    % FIXME: make more general - the above fix assumes 2 Hz snapshots

    t0 = datenum(dates(1,:));
    
end

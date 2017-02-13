function signed_zone=get_signed_utm_zone(llh)
% function signed_zone=get_signed_utm_zone(llh)
%
% Returns the "signed UTM zone" of one or more [lat;lon;height] vectors.
% Height is not used in the calculation, but can be passed in anyway.  
% The signed UTM zone is an integer zone number, similar to the output of 
% utmzone.m except with a sign instead of a letter, and not a string.  
% For points in the northern hemisphere or on the equator, the signed UTM 
% zone is positive, and for points in the southern hemisphere, it's 
% negative.  
%
% Input:
% llh = [lat(radians); lon(radians); height(meters)]
%
% Output:
% signed_zone
%
% Ethan Phelps, 2012-06-27

lat_deg=llh(1,:)*180/pi;
lon_deg=llh(2,:)*180/pi;

% utmzone maps 180 deg lon to zone 60, so do the same
is_180=(lon_deg==180);

lon_deg=mod(lon_deg+180,360)-180;

signed_zone=1+floor((lon_deg+180)/6);

signed_zone(is_180)=60;

signed_zone(lat_deg<0)=-signed_zone(lat_deg<0);
return

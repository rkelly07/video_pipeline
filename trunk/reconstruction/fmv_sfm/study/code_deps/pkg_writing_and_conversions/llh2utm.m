function utm=llh2utm(llh,signed_zone,earth)
% function utm=llh2utm(llh,signed_zone,earth)
%
% Converts an array of position vectors from LLH (LLA) to UTM.  Units are
% meters and radians.  
%
% Inputs:
% llh - 3xN array, with each column being [latitude; longitude; altitude]
% signed_zone - scalar UTM zone number, positive if Northern hemisphere, and negative if Southern hemisphere
% earth - structure of earth parameters from make_earth.m
%
% Outputs:
% utm - 3xN array, with each column being [Easting; Northing; altitude]
%
% There is an internal flag "use_mapping_toolbox" that determines whether
% the mapping toolbox is used, or whether equations from the following
% website are used:
% http://en.wikipedia.org/wiki/Universal_Transverse_Mercator_coordinate_system#Simplified_formulas
%
% Ethan Phelps, 2012-05

lat=llh(1,:);
lon=llh(2,:);
alt=llh(3,:);

re=earth.radius_equatorial;
rp=earth.radius_polar;

use_mapping_toolbox=false;
if use_mapping_toolbox
    ecc=sqrt(1-(rp/re)^2);
    lat_in_zone=0.1*sign(signed_zone);
    lon_in_zone=(-180+6*abs(signed_zone)-3)*pi/180;
    
    utmstruct=defaultm('utm');
    utmstruct.zone=utmzone(lat_in_zone*180/pi,lon_in_zone*180/pi);
    utm_struct.geoid=[re,ecc];
    utmstruct.flatlimit=[];
    utmstruct.maplatlimit=[];
    utmstruct=defaultm(utmstruct);
    
    [E,N,alt]=mfwdtran(utmstruct,lat*180/pi,lon*180/pi,alt);
    utm=[E;N;alt];
    return
end

F=re/(re-rp);
k0=0.9996;
E0=500e3;

% longitude of central meridian
lon0=(-180+6*abs(signed_zone)-3)*pi/180;

% if signed_zone>0
%     N0=0;
% elseif signed_zone<0
%     N0=10000e3;
% end
N0=10000e3*(signed_zone<0);

n=1/(2*F-1);
A=(re/(1+n))*( ...
    1+ ...
    (3*n/2-n)^2+ ...
    ((3*n/2-n)*(3*n/4-n))^2 ...
    );

alpha=[
    1/2,    -2/3,   5/16;
    0,      13/48,  -3/5;
    0,      0,      61/240;
    ]*[n;n^2;n^3];

% beta=[
%     1/2,    -2/3,   37/96;
%     0,      1/48,   1/15;
%     0,      0,      17/480;
%     ]*[n;n^2;n^3];
% 
% delta=[
%     2,  -2/3,   -2;
%     0,  7/3,    -8/5;
%     0,  0,      56/15;
%     ]*[n;n^2;n^3];

slat=sin(lat);
dlon=lon-lon0;

c=2*sqrt(n)/(1+n);
t=sinh(atanh(slat)-c*atanh(c*slat));
zeta=atan(t./cos(dlon));
eta=atanh(sin(dlon)./sqrt(1+t.^2));

E_sum=0;
for k=1:3
    E_sum=E_sum+alpha(k)*cos(2*k*zeta).*sinh(2*k*eta);
end
E=E0+k0*A*(eta+E_sum);

N_sum=0;
for k=1:3
    N_sum=N_sum+alpha(k)*sin(2*k*zeta).*cosh(2*k*eta);
end
N=N0+k0*A*(zeta+N_sum);

utm=[E;N;alt];
return

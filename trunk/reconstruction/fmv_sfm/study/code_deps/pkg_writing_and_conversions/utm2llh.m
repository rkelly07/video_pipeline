function llh=utm2llh(utm,signed_zone,earth)
% function llh=utm2llh(utm,signed_zone,earth)
%
% Converts an array of position vectors from UTM to LLH (LLA).  Units are
% meters and radians.  
%
% Inputs:
% utm - 3xN array, with each column being [Easting; Northing; altitude]
% signed_zone - scalar UTM zone number, positive if Northern hemisphere, and negative if Southern hemisphere
% earth - structure of earth parameters from make_earth.m
%
% Outputs:
% llh - 3xN array, with each column being [latitude; longitude; altitude]
%
% There is an internal flag "use_mapping_toolbox" that determines whether
% the mapping toolbox is used, or whether equations from the following
% website are used:
% http://en.wikipedia.org/wiki/Universal_Transverse_Mercator_coordinate_system#Simplified_formulas
%
% Ethan Phelps, 2012-05

E=utm(1,:);
N=utm(2,:);
alt=utm(3,:);

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
    
    [lat_deg,lon_deg,alt]=minvtran(utmstruct,E,N,alt);
    llh=[lat_deg*pi/180;lon_deg*pi/180;alt];
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

% alpha=[
%     1/2,    -2/3,   5/16;
%     0,      13/48,  -3/5;
%     0,      0,      61/240;
%     ]*[n;n^2;n^3];

beta=[
    1/2,    -2/3,   37/96;
    0,      1/48,   1/15;
    0,      0,      17/480;
    ]*[n;n^2;n^3];

delta=[
    2,  -2/3,   -2;
    0,  7/3,    -8/5;
    0,  0,      56/15;
    ]*[n;n^2;n^3];

zeta=(N-N0)/(k0*A);
eta=(E-E0)/(k0*A);

zeta_sum=0;
for k=1:3
    zeta_sum=zeta_sum+beta(k)*sin(2*k*zeta).*cosh(2*k*eta);
end
zeta1=zeta-zeta_sum;

eta_sum=0;
for k=1:3
    eta_sum=eta_sum+beta(k)*cos(2*k*zeta).*sinh(2*k*eta);
end
eta1=eta-eta_sum;

chi=asin(sin(zeta1)./cosh(eta1));

lat_sum=0;
for k=1:3
    lat_sum=lat_sum+delta(k)*sin(2*k*chi);
end
lat=chi+lat_sum;

lon=lon0+atan(sinh(eta1)./cos(zeta1));

llh=[lat;lon;alt];
return

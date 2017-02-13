coord=[42.362717, -71.090184];
W=1e-2;
minx=coord(2)-W;
maxx=coord(2)+W;
miny=coord(1)-W;
maxy=coord(1)+W;
url=['http://www.panoramio.com/map/get_panoramas.php?set=public&from=0&to=20&minx=',num2str(minx),'&miny=',num2str(miny),'&maxx=',num2str(maxx),'&maxy=',num2str(maxy),'&size=medium&mapfilter=true'];
json_txt=urlread(url);
json=parse_json(json_txt);
% mkdir tmpdir
% delete tmpdir/*
% tmpdir='tmpdir/';
for i=1:numel(json.photos); 
    tmpname=[tempname,'.jpg'];
    [sys_stat,sys_res]=system(['wget -q  --output-document=',tmpname,' ',json.photos{i}.photo_file_url]);
    I=imread(tmpname);
    
    delete(tmpname);
    imshow(I,[]);
    drawnow;
    pause
end
dir tmpdir/
function save_binary_coordinates(P,filename)
n=size(P,2);
d=size(P,1);
fid=fopen(filename,'wb');
fwrite(fid,n,'uint32');
fwrite(fid,d,'uint32');
% Pt=P';
fwrite(fid,single(P(:)),'single');

% for i=1:n
%     if (mod(i,ceil(n/100))==0)
%         fprintf('.');
%     end
%     fwrite(fid,single(P(i,:)),'single');
% end
fclose(fid);
end
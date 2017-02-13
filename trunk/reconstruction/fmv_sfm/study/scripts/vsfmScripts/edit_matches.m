
%function [nSaved, nTries] = edit_matches( match_file_in, match_file_out, matchLo )

% function to edit the matches text file to save matched frames that have more than matchLo
%  feature matches.
% This should help ensure a successful reconstruction
%------------------------------------------------------------------

fid     = fopen('/data/study/reconstruction_cache/my_matches.txt','r');
fid_out = fopen('/data/study/reconstruction_cache/edit_matches.txt','w');
fid_images = fopen('/data/study/reconstruction_cache/edit_images.txt','w');
matchLo = 0;

%fid     = fopen(match_file_in, 'r');
%fid_out = fopen(match_file_out, 'w');

% read header
headerText = textscan(fid,'%s',5,'delimiter', '\n');
fprintf(fid_out,'%s\n%s\n%s\n%s\n%s\n',headerText{1}{1:5});

nSaved = 0;
nTries = 0;

while(~feof(fid))
    nTries = nTries + 1;
    cur_match.frame1  = textscan(fid,'%s',1,'delimiter', '\n');
    cur_match.frame2  = textscan(fid,'%s',1,'delimiter', '\n');
    
    n_pts_str = textscan(fid,'%s',1,'delimiter', '\n');
    cur_match.nPoints = str2double(n_pts_str{1});
    
   
    cur_match.match1  = textscan(fid,'%s',1,'delimiter', '\n');
    cur_match.match2  = textscan(fid,'%s',1,'delimiter', '\n');
    
    textscan(fid, '%s',1,'delimiter', '\n');  % blank line
    
    if (cur_match.nPoints > matchLo)
        fprintf(fid_out,'%s\n',cur_match.frame1{1}{1});
        fprintf(fid_out,'%s\n',cur_match.frame2{1}{1});
        fprintf(fid_out,'%d\n',cur_match.nPoints);
        fprintf(fid_out,'%s\n',cur_match.match1{1}{1});
        fprintf(fid_out,'%s\n\n',cur_match.match2{1}{1});
        
        fprintf(fid_images,'%s %s\n',cur_match.frame1{1}{1},cur_match.frame2{1}{1});
        nSaved = nSaved + 1;
    end
end

fclose(fid);
fclose(fid_out);
fclose(fid_images);

fprintf('Saved %d out of %d matches: %f percent \n',nSaved, nTries, nSaved/nTries*100);

return

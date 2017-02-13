function [ t_sift, t_match ] = parse_log( cmd_log)
% parse_log parses through a log of screen commands to extract the time elapsed for sift and match


% break into cell of lines
log_info      = regexp(cmd_log,char(13), 'split'); 

% look through the logfile for the phrase "Feature Detection finished," then will have " 457 sec used "

Key       = 'finished,';
ind_all   = strfind(log_info, Key);
ind_ans   = find(not(cellfun('isempty',ind_all)));
sift_line = log_info{ind_ans(1)};

Index    = strfind(sift_line, Key);
t_sift   = sscanf(sift_line(Index(1) + length(Key):end),'%g',1);

% continue looking through log for the phrase "Image Match finished," then willl have  " 3869 sec used"
% use same key as before....

match_line = log_info{ind_ans(2)};
Index      = strfind(match_line, Key);
t_match    = sscanf(match_line(Index(1) + length(Key):end),'%g',1);


end


% return workspace memory usage
function freemem = mymemory()

% [~,w] = unix('free | grep Mem');
% stats = str2double(regexp(w, '[0-9]*', 'match'));
% memsize = stats(1)/1e6;
% freemem = (stats(3)+stats(end))/1e6;

% S = whos;
% freemem = sum(cell2mat({S.bytes}));

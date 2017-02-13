function [ rmsErr, absErr ] = trackAccuracy( logFile )
% Function to find the RMS and absolute error from a reconstruction
% after geo-registration. Values are contained within log file.
% They just need to be found and changed from text string to a value....


rmsErr  = 0.;
absErr  = 0.;

% ....... Step 1) Find the 2 lines in the file containing the word "squared"
stringFound = strfind(logFile, 'squared');
ansRows     = find( ~cellfun(@isempty, stringFound) );
if (~isempty(ansRows))
    strRow      = logFile{ansRows(1)};
    Key         = '= ';
    Index       = strfind(strRow, Key);
    rmsErr      = sscanf( strRow( Index(1) + length(Key) : end ), '%f', 1);
end


% ...... Step 2) Find the 2 lines in the file containing the word "absolute"
stringFound = strfind(logFile, 'absolute');
ansRows     = find( ~cellfun(@isempty, stringFound) );
if (~isempty(ansRows))
    strRow      = logFile{ansRows(1)};
    Key         = '= ';
    Index       = strfind(strRow, Key);
    absErr     = sscanf( strRow( Index(1) + length(Key) : end ), '%f', 1);
end

end


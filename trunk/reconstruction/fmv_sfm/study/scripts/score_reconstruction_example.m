WINDOZE = ~isempty(strfind(computer,'WIN'));

if WINDOZE
   BASE_DIR = '\\qonos\RRTO2D3D\study'; 
else
   BASE_DIR = '/data/study'; 
end

if ~exist('CODE_DIR'); CODE_DIR = BASE_DIR; end 

addpath(fullfile(CODE_DIR,'code_deps','nvmProcessing'));
addpath(fullfile(CODE_DIR,'code_deps','nvmProcessing','quaternions'));

if ~WINDOZE
  addpath(fullfile(CODE_DIR,'scripts'));
  nvmFilename = '/mnt/qonos/puma_Sep13_2013_YPG/subset/subset.nvm'; 
else
  addpath(fullfile('\\qonos\RRTO2D3D\fmv_sfm\study\scripts'));
  nvmFilename = '\\qonos\RRTO2D3D\puma_Sep13_2013_YPG\subset\subset.nvm'; 
end 

metadataFilename = fullfile(BASE_DIR,'truth','puma_2013_09_13_flt1_bin2txt.metadata');

%%  If you re-run georegistration, it will overwrite data, so 
%%  you will probably want to specify the 3rd and 4th arguments
% georegister_reconstruction(metadataFilename,nvmFilename);

stats = score_reconstruction(metadataFilename,nvmFilename);

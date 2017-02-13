% persistent display function
%   pdisp(X) displays as normal using disp
%   pdisp([],'SetVerbose',true/false) sets persistent flag
%   on/off to enable/disable display for debug more and worker pools
function pdisp(X,varargin)

persistent set_verbose

p = inputParser;
p.addParamValue('SetVerbose',[],@islogical)
p.parse(varargin{:})
params = p.Results;

if ~isempty(params.SetVerbose)
  if params.SetVerbose
    set_verbose = true;
    %disp('Verbose on')
  else
    set_verbose = false;
    %disp('Verbose off')
  end
end

verbose = true;
if ~isempty(set_verbose)
  verbose = set_verbose;
end
if verbose
  builtin('disp',(X))
end

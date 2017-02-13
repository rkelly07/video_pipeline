% Functional expression for parenthesis
% Solves the "unbalanced or unexpected parenthesis or bracket" limitation
% using a wrapper for MATLAB's own undocumented features.
% Syntactically equivalent to
%   "ans = expr(args)"
% which is not valid syntax if varargin{1} is a function
%   e.g. magic(5)(3,3)
function ans = paren(expr,args)
ans = builtin('_paren',expr,args);

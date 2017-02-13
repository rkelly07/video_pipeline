function [X,L,endpoints] = generate_ksegment_points(T,d,k,varargin)

p = inputParser;
p.addOptional('spread',1,@isnumeric);
p.parse(varargin{:});
spread = p.Results.spread;

T = T(:);
n = length(T);

X = zeros(n,d);

% split points
ns = round(n*spread);
ns = max(ns,k);
startpoint = randi(n-ns+1)-1;
splitpoints = startpoint+sort(randperm(ns-1,k-1));

if ~isempty(splitpoints)
  endpoints = [1,splitpoints(1)];
  for i = 2:k-1
    endpoints = cat(1,endpoints,[splitpoints(i-1)+1,splitpoints(i)]);
  end
  endpoints = cat(1,endpoints,[splitpoints(k-1)+1,n]);
else
  endpoints = [1 n];
end

for i = 1:d
  
  % first line segment
  ak = 1;
  bk = endpoints(1,2);
  mmin = (-1/bk);
  mmax = (1/bk);
  m1 = (mmin)+rand*(mmax-mmin);
  c1 = -sign(m1)*rand;
  Lk = [m1;c1];
  Tk = T(ak:bk);
  Xk = SignalPointSet.LineSegmentPoints(Lk,Tk);
  L{1}(:,i) = Lk;
  X(Tk,i) = Xk;
  
  % following line segments
  for j = 2:k
    
    ak = endpoints(j,1);
    bk = endpoints(j,2);
    
    mmin = (-1-(m1*(ak-1)+c1))/(bk-ak+1);
    mmax = (1-(m1*(ak-1)+c1))/(bk-ak+1);
    m2 = (mmin)+rand*(mmax-mmin);
    c2 = (m1*(ak-1)+c1)-m2*(ak-1);
    
    Lk = [m2;c2];
    Tk = T(ak:bk);
    Xk = SignalPointSet.LineSegmentPoints(Lk,Tk);
    L{j}(:,i) = Lk;
    X(Tk,i) = Xk;
    
    m1 = m2;
    c1 = c2;
    
  end
  
end


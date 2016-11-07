function delta = interpolator(prev,curr)
% INTERPOLATOR calculates the difference between the current
%              and the previous value, if positive, then
%              the interpolator will return a positive change,
%              if negative, it will return a negative change,
%              else there will be zero change
  delta = curr - prev;
  if (delta>0)
    delta = 0.05;
  end
  if (delta<0)
    delta = -0.05;
  end
end

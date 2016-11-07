function [ out ] = allpassFilter(s, g,M )
% All pass filters in series
%   H(z) = (-g + z^-M )/ (1- g * z^M)
    
   for i = 1:length(M)
    b = [-g, zeros(1, M(i)-1), 1];
    a = [1, zeros(1,M(i)-1), -g];
    s = filter(b, a, s); 
   end
   out = s;

end


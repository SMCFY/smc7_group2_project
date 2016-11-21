function E = energyLevel(x,A)
%THIS IS A TEST HEH 
%code based on work by
%   Author: Nabin Sharma
%   Date: 2009/03/15

% generate the window
ham = hamming(length(x));
window = A.*ham';

% enery calculation
x2 = x.^2;
E = wconv(x2,window,length(x));
end
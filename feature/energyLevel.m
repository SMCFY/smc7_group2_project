function E = energyLevel(x,A)
% generate the window
ham = hamming(length(x));
window = A.*ham';

% enery calculation
x2 = x.^2;
E = wconv(x2,window,length(x));

end
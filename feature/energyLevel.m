function E = energyLevel(x,A)

    %code based on work by
    %   Author: Nabin Sharma
    %   Date: 2009/03/15

    % generate the window
    %ham = hamming(length(x));
    M = length(x);
    ham = .54 - .46*cos(2*pi*(0:M-1)'/(M-1));
    window = A.*ham';

    % enery calculation
    x2 = x.^2;
    E = real(sum(wconv(x2,window,length(x)))/length(x));
    
end

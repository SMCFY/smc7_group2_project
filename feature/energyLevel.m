function E = energyLevel(x,A)

    %code based on work by
    %   Author: Nabin Sharma
    %   Date: 2009/03/15

    % generate the window
    ham = hamming(length(x));
    window = A.*ham';

    % enery calculation
    x2 = x.^2;
    E = sum(wconv(x2,window,length(x)))/length(x);
    
end
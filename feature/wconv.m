function y = wconv( x, A, L )
    %code based on work by
    %   Author: Nabin Sharma
    %   Date: 2009/03/15
    % generate the window
    M = length(x);
    ham = .54 - .46*cos(2*pi*(0:M-1)'/(M-1));
    window = A.*ham';

    % perform the convolution using FFT
    NFFT = 2^(nextpow2(length(x)+L));
    X = fft(x,NFFT); W = fft(window,NFFT);
    Y = X.*W;
    y = ifft(Y,NFFT);
end


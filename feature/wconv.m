function y = wconv( x, A, L )
    %code based on work by
    %   Author: Nabin Sharma
    %   Date: 2009/03/15
    % generate the window
    ham = hamming(length(x));
    window = A.*ham';

    % perform the convolution using FFT
    NFFT = 2^(nextpow2(length(x)+L));
    X = fft(x,NFFT); W = fft(window,NFFT);
    Y = X.*W;
    y = ifft(Y,NFFT);
end


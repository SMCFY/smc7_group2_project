function y = wconv( x, A, L )
% generate the window
ham = hamming(length(x));
window = A.*ham';

% perform the convolution using FFT
NFFT = 2^(nextpow2(length(x)+L));
X = fft(x,NFFT); W = fft(window,NFFT);
Y = X.*W;
y = ifft(Y,NFFT);
    


end


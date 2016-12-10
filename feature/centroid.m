function C = centroid(x,fs)
%SPECTRAL CENTROID
%  calculates the spectral centroid
%
% ARGUMENTS:
%   x - input signal
% 	fs - sampling frequency

    M = length(x);
    ham = .54 - .46*cos(2*pi*(0:M-1)'/(M-1));
    window = x(1,:).*ham'; % create a hamming window for the signal
    X = fft(window); % fast fourier transform
    X_mag = abs(X); % magnitude spectrum
    X_mag = X_mag(1:round(length(X_mag)/2)); % cropping the negative region
    if max(X_mag) > 0.5 % minimum threshold for calculation
        X_mag = X_mag/max(X_mag); % normalize spectrum
        w = ((fs/2)/length(X_mag))*[0:length(X_mag)-1]; % bins in frequencies
        C = X_mag * w'/sum(X_mag); % SC
        C = C/(fs/2);
    else 
        C = 0;
    end

end


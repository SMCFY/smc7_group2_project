function C = centroid(x,fs)
%SPECTRAL CENTROID calculates the spectral centorid of a discrete signal
   % x = x / max(abs(x));
    ham = hamming(length(x));
    window = x.*ham'; % create a hamming window for the signal
    X = fft(window); %fast fourier transform
    X_mag = abs(X); %magnitude spectrum
    X_mag = X_mag(1:length(X_mag)/2); %cropping the negative region
    X_mag = X_mag/max(X_mag); % normalize X_mag
    w = ((fs/2)/length(X_mag))*[0:length(X_mag)-1]; %vector of bins where 0 corresponds to DC component which needs to be excluded
                                                   %TODO
    C = X_mag * w'/sum(X_mag); % centroid FUCK YEAH
    %C = C/pi;
    C = C/(fs/2);
    
    %C_hz = C * fs/length(w) 

end


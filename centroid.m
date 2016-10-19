function C = centroid(x)
%SPECTRAL CENTROID calculates the spectral centorid of a discrete signal

    X = fft(x); %fast fourier transform
    X_mag = abs(X); %magnitude spectrum
    X_mag = X_mag(1:length(X_mag)/2); %cropping the n egative region
    w = [0:length(X_mag)-1] %vector of bins where 0 corresponds to DC component which needs to be excluded

    C = X_mag * w'/sum(X_mag); % centroid FUCK YEAH
    
    %C_hz = C * fs/length(w) 

end


function C = centroid(x)
%SPECTRAL CENTROID calculates the spectral centorid of a discrete signal

    X = fft(x); %fast fourier transform
    X_mag = abs(X); %magnitude spectrum
    X_mag = X_mag(1:length(X_mag)/2);
   
    C = X_mag*(0:length(X_mag)-1)'/sum(X_mag);
    
    %w = [1:length(x)].*fs/length(x); %center frequency of each bin

    %C = sum(w(1:length(w)/2).*X_mag(1:length(X_mag)/2))/sum(X_mag(1:length(X_mag)/2));

end


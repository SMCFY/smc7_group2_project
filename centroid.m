function C = centroid(x, fs)
%SPECTRAL CENTROID calculates the spectral centorid of a discrete signal

X = fft(x); %fas fourier transform
X_mag = abs(X); %magnitude spectrum
w = [1:length(x)].*fs/length(x); %center frequency of each bin



C = sum(w(1:length(w)/2).*X_mag(1:length(X_mag)/2))/sum(X_mag(1:length(X_mag)/2));

end


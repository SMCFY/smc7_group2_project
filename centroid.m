function C = centroid(x, fs)
%SPECTRAL CENTROID calculates the spectral centorid of a discrete signal

X = fft(x); %fas fourier transform
X_mag = abs(X); %magnitude spectrum
w = [1:length(x)].*fs/length(x); %center frequency of each bin


    
C = sum(w.*X_mag)/sum(X_mag);
   

end


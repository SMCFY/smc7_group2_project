function C = centroid(x, fs)
%SPECTRAL CENTROID calculates the spectral centorid of a discrete signal

X_mag = abs(fft(x)); %magnitude spectrum

w = fs/lenght(x); %bins to Herz

%for i =1:length(x)
    
    C = sum(X_mag.w)/sum(X_mag);
   
%end

end


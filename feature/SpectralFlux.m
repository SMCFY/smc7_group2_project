
function F = SpectralFlux(signal,windowLength, step, fs)
% SPECTRALFLUX 
% https://se.mathworks.com/matlabcentral/fileexchange/19236-some-basic-audio-features    
signal = signal / max(abs(signal)); % normalization

curPos = 1;
L = length(signal);
numOfFrames = floor((L-windowLength)/step) + 1; % number windows to cover the entire signal
H = hamming(windowLength);
% unused  junk shit - m = [0:windowLength-1]';
F = zeros(numOfFrames,1); % SF vector declaration 

for (i=1:numOfFrames)
    window = H.*(signal(curPos:curPos+windowLength-1));    
    FFT = (abs(fft(window,2*windowLength))); %magnitude spectrum
    FFT = FFT(1:windowLength); % spectrum until nyquist      
    FFT = FFT / max(FFT); % normalization
    if (i>1)
        F(i) = sum((FFT-FFTprev).^2); % spectral difference (NOTE! x^2)
      if F(i) < 0
          F(i) = 0;
%       else
%         F(i) = F(i)^2;
      end
    else
        F(i) = 0; % the first value of the SF vector
    end
    curPos = curPos + step; % stepping to next window
    FFTprev = FFT; % updates the previous spectrum
end
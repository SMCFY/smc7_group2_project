
function [onset, XmagPrev] = detectOnset(signal, threshold, XmagPrev)
% ONSET DETECTION 
%   detects musical onsets by transient regions based on spectral flux
% 
% ARGUMENTS:
%   signal - the windowed signal (buffer)
%   threshold - the threshold of spectral flux for onset detection
%   XmagPrev - previously returned magnitude spectrum
%   

signal = signal / max(abs(signal)); % normalization of the signal   
Xmag = abs(fft(signal,2*length(signal))); %magnitude spectrum
Xmag = Xmag(1:length(signal)); % consider spectrum until nyquist freq     
Xmag = Xmag / max(Xmag); % normalization of the spectrum

if (XmagPrev>0)
    if sum(Xmag-XmagPrev) > 0 % rectification
        SF = sum(Xmag-XmagPrev); % spectral flux
    else
        SF = 0;
    end

else
    SF = 0; % the first output
end
  
XmagPrev = Xmag; % updates the previous spectrum


if SF > threshold %onset detection
    onset = 1;

else
    onset = 0;
end


end
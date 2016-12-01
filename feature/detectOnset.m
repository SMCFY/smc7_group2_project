function [noveltyC, XmagPrev] = detectOnset(signal, noveltyC,  XmagPrev)
% ONSET DETECTION
%   returns a novelty curve, showing transient regions in signal based on spectral flux
%
% ARGUMENTS:
%   signal - the windowed signal (buffer)
% 	noveltyC - novelty curve
%   XmagPrev - previously calculated magnitude spectrum
%
% OUTPUT:
%   XmagPrev - spectrum buffer
%	noveltyC - SF over time

noiseLimit = 0.0001;
for i=1:length(signal) % noise gate
    if (abs(signal(i))<noiseLimit)
        signal(i) = 0;
    end    
end

Xmag = abs(fft(signal,2*length(signal))); %magnitude spectrum
Xmag = Xmag(1:length(signal)); % consider spectrum until nyquist freq
%fftbuffer = zeros(1,length(signal));
fftbuffer = XmagPrev(1,1:length(signal));
if(length(Xmag)~=length(fftbuffer))
	SF = 0;
elseif (XmagPrev>0)
    specDiff = ((Xmag-fftbuffer + abs(Xmag-fftbuffer))/2).^2; % energy of rectified spectral difference
    SF = sum(specDiff); % spectral flux
    
else
    SF = 0; % the first output
end

XmagPrev(1:length(signal)) = Xmag; % storing the spectrum
% Shift the values by one sample to make room for SF
noveltyC(1:end-1) = noveltyC(2:end);
noveltyC(end) = SF;

end

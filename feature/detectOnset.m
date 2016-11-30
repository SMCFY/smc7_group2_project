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

if (XmagPrev>0)
    % If the frameSize changes, make sure that XmagPrev is the same size as
    % Xmag
    if(length(Xmag)-length(XmagPrev)~=0)
	    XmagPrev = resample(XmagPrev,length(Xmag),length(XmagPrev));
    end
    
    specDiff = ((Xmag-XmagPrev + abs(Xmag-XmagPrev))/2).^2; % energy of rectified spectral difference
    SF = sum(specDiff); % spectral flux
    
else
    SF = 0; % the first output
end

XmagPrev = Xmag; % storing the spectrum

noveltyC = [noveltyC, SF];

end
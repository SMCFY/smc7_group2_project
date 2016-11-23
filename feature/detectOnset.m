function [noveltyC, XmagPrev] = detectOnset(signal, threshold, duration, noveltyC,  XmagPrev)
% ONSET DETECTION 
%   detects musical onsets by transient regions in signal based on spectral flux
% 
% ARGUMENTS:
%   signal - the windowed signal (buffer)
%   threshold - the threshold of spectral flux for onset detection
%	duration - length of novelty curve
% 	noveltyC - novelty curve
%   XmagPrev - previously returned magnitude spectrum
%   
% OUTPUT:
%   XmagPrev - spectrum buffer
%	noveltyC - SF over time


% detection function -----------------------------------
noiseLimit = 0.01;
%polarS = sign(signal); % retain polarity of waveform
for i=1:length(signal) % noise gate
	if (abs(signal(i))<noiseLimit)
		signal(i) = 0;
    end
    
end
signal = signal / max(abs(signal)); % normalization of the signal 

%signal = signal - noiseLimit; % DC offset

Xmag = abs(fft(signal,2*length(signal))); %magnitude spectrum
Xmag = Xmag(1:length(signal)); % consider spectrum until nyquist freq     
Xmag = Xmag / max(Xmag); % normalization of the spectrum

if (XmagPrev>0)
    
    specDiff = ((Xmag-XmagPrev + abs(Xmag-XmagPrev))/2).^2; % energy of rectified spectral difference
    SF = sum(specDiff); % spectral flux
    %SF = SF^10; % accentuation

else
    SF = 0; % the first output
end

noveltyC = [noveltyC, SF];



XmagPrev = Xmag; % storing the spectrum

% peak picking ----------------------------------
% 
end
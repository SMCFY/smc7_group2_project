function tempo = estimateTempo(frameSize, fs, bufferSize, signal, threshold, XmagPrev)
%TEMPO ESTIMATION
%   estimates tempo based on  musical onsets
% 
% ARGUMENTS: 
%	frameSize - considered time period for tempo estimation [seconds]
%   fs - samplig frequency
%   bufferSize - samples per frame
%
%   signal - the windowed signal (buffer)
%   threshold - the threshold of spectral flux for onset detection
%   XmagPrev - previously returned magnitude spectrum
%   

frameSizeN = frameSize * fs; % frame size in samples
onsetRes = round(frameSizeN / bufferSize); % frame size in onsets
onsetLoc = ones(1,onsetRes); % array of onset locations

for i=1:onsetRes 
	onsetLoc(i) = detectOnset(signal, threshold, XmagPrev);

	if i == onsetRes % refills the array of onsets from the beginning
		i = 1;
	end

	tempo = round((sum(onsetLoc)/frameSize)*60); %onsets per minute

end


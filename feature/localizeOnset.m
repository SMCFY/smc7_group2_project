function [avgOnset, onsetInterval] = localizeOnset(noveltyC, durationInBuffers, threshold, temporalThreshold, onsetInterval, avgOnset, noveltyCLength)
% AVERAGE INTER-ONSET INTERVAL
%   localizing onsets in the specified time period and calculating the average inter-onset interval
%
% ARGUMENTS:
% 	noveltyC - novelty curve
%   	durationInBuffers - considered period for onsets
%	threshold - absolute treshold in SF for onset detection
%	temporalThreshold - temporal threshold in buffers for onset detection 
%	onsetInterval - IOI
%	avgOnset - average IOI
%	noveltyCLength - window size
%   
% OUTPUT:
%	onsetInterval - IOI between the last 2 onset
%   	avgOnset - average IOI

if sum(noveltyC) > 0            %if (durationInBuffers < length(noveltyC))
    onsetVector = noveltyC(1:noveltyCLength); %windowed novelty curve
    onsetVector = filter([0.2, 0.2, 0.2, 0.2, 0.2], 1, onsetVector); %smooting

    onsetLoc = zeros(1,length(onsetVector));
    for i=1:length(onsetVector)
        if (onsetVector(i)>threshold && temporalThreshold<0)
            if (sum(sign(onsetLoc)==1)) %solving corner case if only one onset is recorded in the vector
              onsetLoc(i) = 1; 
              onsetInterval = 0; % initializing onset interval counter
            else % needs 2 or more onset in the vector in order to calcule a valid IOI value
              onsetLoc(i) = onsetInterval; % store elapsed time in terms of buffers since last onset, when new onset is recorded
            end
	    
            avgOnset = sum(onsetLoc)/sum(sign(onsetLoc)); % average IOI
	    avgOnset = 1/avgOnset; % inverting value
            
	    temporalThreshold = 20; % initializing temporal threshold
            onsetInterval = 0; % initializing onset interval counter
        else
            onsetLoc(i) = 0;

            temporalThreshold = temporalThreshold - 1;
            onsetInterval = onsetInterval +1;
        end
    end
    
else
    
    avgOnset = 0;
    
end




end


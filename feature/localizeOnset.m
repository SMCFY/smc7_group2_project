function [onsetDev, onsetInterval, curPos] = localizeOnset(noveltyC, durationInBuffers, threshold, temporalThreshold, onsetInterval, curPos, onsetDev)
% INTER-ONSET INTERVAL DEVIATION
%   localizing onsets in the specified time period and calculating the inter-onset interval deviation
%	from the avarage onset interval
%
% ARGUMENTS:
% 	noveltyC - novelty curve
%   durationInBuffers - considered period for onsets
%	threshold - absolute treshold in SF for onset detection
%	temporalThreshold - temporal threshold in buffers for onset detection 
%	curPos - current position in reading the novelty curve
%   
% OUTPUT:
%   onsetDev - IOI deviation
%	curPos - window position on the novelty curve

if sum(noveltyC) > 0            %if (durationInBuffers < length(noveltyC))
    onsetVector = noveltyC; %windowed novelty curve
    onsetVector = filter([0.2, 0.2, 0.2, 0.2, 0.2], 1, onsetVector); %smooting

    for i=1:length(onsetVector)
        if (onsetVector(i)>threshold && temporalThreshold<0)
            if (sum(sign(onsetLoc)==1) && length(onsetVector(i)==length(onsetVector)))
              onsetLoc(i) = 1; % store elapsed time in terms of buffers since last onset, when new onset is recorded
              onsetInterval = 0; % initializing onset interval counter
            else
              onsetLoc(i) = onsetInterval; % store elapsed time in terms of buffers since last onset, when new onset is recorded
            end
            onsetDev = sum(onsetLoc)/sum(sign(onsetLoc)); % IOI deviation
	    onsetDev = 1/onsetDev;
            
			temporalThreshold = 20; % initializing temporal threshold
            onsetInterval = 0; % initializing onset interval counter
        else
            onsetLoc(i) = 0;

            temporalThreshold = temporalThreshold - 1;
            onsetInterval = onsetInterval +1;
        end
    end

    %curPos = curPos +1; % moving the window
    
else
    
   % onsetDev = 0;
    
end




end


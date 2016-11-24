function [onsetLoc, curPos] = localizeOnset(noveltyC, durationInSamples, threshold, curPos)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if (durationInSamples < length(noveltyC))
    onsetVector = noveltyC(curPos:durationInSamples+curPos-1); %windowed novelty curve
    onsetVector = filter([0.2, 0.2, 0.2, 0.2, 0.2], 1, onsetVector); %smooting

    for i=1:length(onsetVector)
        if (onsetVector(i)>threshold)
            onsetLoc(i) = 1; % onset!
        else
            onsetLoc(i) = 0;
        end
    end

    curPos = curPos +1;
else
    onsetLoc = zeros(durationInSamples, 1);
    
end


end


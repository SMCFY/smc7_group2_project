function bang = onsetD(buffer, L, threshold)
% ONSET DETECTION
% onset detection based on the slope between 2 points in the time-domain
% the function returns "1", whenever the treshold value is exceeded
%--------------------------------------------------------------------------
% arguments:
%       buffer - analysed segment
%       L - window size for further segmentation (has to be a multiple of
%       the buffer size)
%       threshold - threshold of slope steepness

        bang = 0;
        
    for i=1:buffer/L
        
        onsetSeg = mySignal(L*(i-1)+1:L*i);
        slope = (onsetSeg(L,1)-onsetSeg(1,1))/L;
     
         if slope > threshold
             bang = 1;  
         else
             bang = 0;
         end

    end

    
end


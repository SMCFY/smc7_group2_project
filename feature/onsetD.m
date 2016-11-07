function bang = onsetD(buff, L, thresh)
% ONSET DETECTION
% onset detection based on the slope between 2 points in the time-domain
% the function returns "1", whenever the treshold value is exceeded
%--------------------------------------------------------------------------
% arguments:
%       buff - realtime buffer
%       L - window size for further segmentation (has to be a multiple of
%       the buffer size)
%       thresh - threshold of slope steepness for onset detection

        bang = 0;
        
    for i=1:length(buff)/L
        
        onsetSeg = buff(L*(i-1)+1:L*i);
        slope = (onsetSeg(L,1)-onsetSeg(1,1))/L;
     
         if slope > thresh
             bang = 1;
             disp('ONSET!!!!!!!!!!!!!!!');
         else
             bang = 0;
         end

    end

    
end


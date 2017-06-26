classdef Filters
    % Highpass and lowpass filter class
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function obj = Filters()
        end
        % Butterworth two pole high pass filter coefficients
        function [b, a] = highPassCoeffs(Fc, Q, Fs)
            w0 = 2*pi*Fc/Fs;
            alpha = sin(w0)/sqrt(2 * Q);
            cosw0 = cos(w0);
            norm = 1/(1+alpha);
            b = (1 + cosw0)*norm * [.5  -1  .5];
            a = [1  -2*cosw0*norm  (1 - alpha)*norm];
        end
        
        % Butterworth low pass filter coefficients
        function [b, a] = lowPassCoeffs(Fc,Q, Fs)
            w0 = 2*pi*Fc/Fs;
            alpha = sin(w0)/sqrt(2 * Q);
            cosw0 = cos(w0);
            norm = 1/(1+alpha);
            b = (1 - cosw0)*norm * [.5 1 .5];
            a = [1 -2*cosw0*norm  (1 - alpha)*norm];
        end
    end
    
end


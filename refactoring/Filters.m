classdef Filters < handle
    % Highpass and lowpass filter class
    %   Detailed explanation goes here
    
    properties 
        Q = 1;
        Fc = 5000; 
    end
    properties (Access = private)
        pSR
        % internal state used by LP and HP filter, all zeros the initial
        % state
        zHP = zeros(2)
        bHP = zeros(1,3)
        aHP = zeros(1,3)
        % internal state used by LP and HP filter, all zeros the initial
        % state
        zLP = zeros(2)
        bLP = zeros(1,3)
        aLP = zeros(1,3)  
    end
    
    methods
        function obj = Filters(Fs)
            obj.pSR = Fs; 
        end
        
        % resets internal states of buffers
        function reset(obj, fs)
            % Reset sample rate
            obj.pSR = fs;
            
            % initialize internal filter state
            obj.zHP = zeros(2); obj.zLP = zeros(2);
            [obj.bHP, obj.aHP] = highPassCoeffs(obj.Fc, obj.Q, fs);
            [obj.bLP, obj.aLP] = lowPassCoeffs(obj.Fc, obj.Q, fs);
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


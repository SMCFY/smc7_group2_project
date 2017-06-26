classdef DelayClass < handle
    % reverse and normal delay structure
    %   Might be unnecessary, lets see.
    
    properties (Dependent)
        FeedbackLevel
    end
    
    properties(Access = private)
        pFractionalDelay
        pSR
         % reverse buffer
        rBuffer
        rPointer = 1;
    end
    methods
        function obj = DelayClass(Fs)
            obj.pSR = Fs;
            obj.pFractionalDelay = audioexample.DelayFilter( ...
                'FeedbackLevel', 0.35, ...
                'SampleRate', Fs);
        end
        
        % resets internal states of buffers
        function reset(obj, fs)
            % Reset sample rate 
            obj.pSR = fs;
            
            % Reset delay
            obj.pFractionalDelay.SampleRate = fs;
            reset(obj.pFractionalDelay);
            
            % reset reverse buffer
            obj.rBuffer = zeros(fs*2+1,2); % max delay time in samples
            obj.rPointer = 1;
           
        end
        %set and get for audioexample.DelayFilter class, might not be
        %needed
        function set.FeedbackLevel(obj, val)
            obj.pFractionalDelay.FeedbackLevel = val;
        end
        function val = get.FeedbackLevel(obj)
            val = obj.pFractionalDelay.FeedbackLevel;
        end
        
        function [out, buffer, bufferIndex] = reverse(x, buffer,delay, bufferIndex)
            % Reverse delay
            %       Create a buffer of delayed frames, read from the buffer in reverse
            %       input : ->->->->->, reverse: <-<-<-<-
            
            delayTime = floor(delay); % to make sure delayTime(in samples) is always an integer
            writeIndex = bufferIndex; % to make sure we allocate the new input in the buffer
            for i = 1:size(x,1)
                buffer(writeIndex,:) = x(i,:);  % write the x into the reverse buffer
                writeIndex = writeIndex + 1;    % write next sample
                
                if writeIndex > delayTime       % if writeIndex goes beyond the delaytime
                    writeIndex = 1;             % reset delayTime to 1
                end
            end
            if delayTime < size(x,1)
                delayTime = size(x,1);
                writeIndex = size(x,1) + 1;
            end
            rev = flip(buffer(1:delayTime,:));  % flip the buffer
            
            if bufferIndex >= writeIndex         % if the bufferIndex is bigger than writeIndex
                out = zeros(size(x));
                for i = 1:size(x,1)
                    if bufferIndex > delayTime
                        bufferIndex = 1;
                    end
                    out(i,:) = rev(bufferIndex,:);  % assign the reversed buffer manually
                    
                    bufferIndex = bufferIndex + 1;
                    
                end
            else
                out = rev(bufferIndex:writeIndex-1,:);
            end
            bufferIndex = writeIndex;   % override bufferIndex for next buffer
        end
    end
    
end


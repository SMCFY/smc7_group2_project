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
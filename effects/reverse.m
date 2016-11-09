function [out] = reverse(x)
    ham = hamming(length(x));
    x = x.*ham;
    out = flip(x); % does not work
    % Create a buffer of delayed frames, read from the buffer in reverse
    % input : ->->->->->,, reverse: <-<-<-<-, 
end
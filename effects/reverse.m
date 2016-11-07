function [out] = reverse(x)
    ham = hamming(length(x));
    x = x.*ham;
    out = flip(x);
    
end
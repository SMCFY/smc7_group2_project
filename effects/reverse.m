function [out, buf] = reverse(x, buf)
    
    out = flip(x);
    buf = out;
end
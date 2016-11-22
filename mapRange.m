function output = mapRange( outMax, outMin, inMax, inMin, input )

if input > inMax
    input = inMax;
end 

slope = (outMax - outMin) / (inMax - inMin);
output = outMin + slope * (input - inMin);
    
end


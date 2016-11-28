function [outputValue] = interpol(targetValue, outputValue, rate, deltaY)
% INTERPOLATOR
% 	interpolates between the target value and the current value
%
% ARGUMENTS:
% 	targetValue - target value received from the extraction 
%   outputValue - calculated output
%	rate - change in time
%	deltaY - change in Y
%   
% OUTPUT:
%   outputValue - output value

if targetValue ~= outputValue %calculate new slope on new input

deltaY = (targetValue - outputValue)/rate;
%prevTarget = targetValue;

end

outputValue = outputValue + deltaY;



end

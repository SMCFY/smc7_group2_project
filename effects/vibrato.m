% Vibrato 
% taken from this website http://users.cs.cf.ac.uk/Dave.Marshall/CM0268/PDF/10_CM0268_Audio_FX.pdf
% Example from DAFX book by Udo
function [y, buffer, bufferIndex, sineP] = vibrato(x, fs, modfreq, width, buffer,bufferIndex, sineP)
% Modfreq in Khz, Width = 0.0008; % 0.8 Milliseconds
y = zeros(size(x));
wIndex = bufferIndex;
delay = width;
M = modfreq/fs; % modulation frequency in # samples

for i=1:size(x,1)
   buffer(wIndex,:) = x(i,:);
   
   MOD=sin(M*2*pi*sineP);
   
   sineP = sineP + 1;
   
   if sineP > 192001
       sineP = 1;
   end
   % Delay tap
   TAP=1+delay+width*MOD;
   n=floor(TAP);
   %frac = TAP-n;
   rIndex = floor(wIndex - n);
   
   if rIndex <= 0
       rIndex = rIndex + 192001;
   end
   
   %---Linear Interpolation-----------------------------
   %y(i,:) = buffer(rIndex)*frac+buffer(rIndex)*(1-frac); 
   y(i,:) = buffer(rIndex);
  % y(i,2)=buffer(rIndex+1)*frac+buffer(rIndex)*(1-frac); 
   
   %---Spline Interpolation------------------------------- 
%   y(i,1)=buffer(rIndex+1)*frac^3/6+buffer(rIndex)*((1+frac)^3-4*frac^3)/6 +buffer(rIndex-1)*((2-frac)^3-4*(1-frac)^3)/6 +buffer(rIndex-2)*(1-frac)^3/6;
   
   wIndex = wIndex + 1;
   if wIndex > 192001
       wIndex =  1;
   end
end
bufferIndex = wIndex;

end 
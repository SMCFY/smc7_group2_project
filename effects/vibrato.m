% Vibrato 
% taken from this website http://users.cs.cf.ac.uk/Dave.Marshall/CM0268/PDF/10_CM0268_Audio_FX.pdf
function [y, buffer, bufferIndex, sineP] = vibrato(x, fs, modfreq, width, buffer,bufferIndex, sineP)
% Modfreq in Khz, Width = 0.0008; % 0.8 Milliseconds
y = zeros(size(x));
wIndex = bufferIndex;
delay = width;
M = modfreq/fs; % modulation frequency in # samples

for i=1:size(x,1)
   buffer(wIndex, :) = x(i,:); 

   MOD=sin(M*2*pi*sineP);
   
   sineP = sineP + 1;
   
   if sineP > 192001
       sineP = 1;
   end
   
   ZEIGER=1+delay+width*MOD;
   n=floor(ZEIGER);
   frac=ZEIGER-n;
   rIndex = wIndex - n;
   
   if rIndex <= 0
       rIndex = rIndex + 192001;
   end
   
   %---Linear Interpolation-----------------------------
   y(i,:)=buffer(rIndex+1)*frac+buffer(rIndex)*(1-frac); 
   %y(i,2)=buffer(rIndex+1)*frac+buffer(rIndex)*(1-frac); 
   
   wIndex = wIndex + 1;
   if wIndex > 192001
       wIndex =  1;
   end

bufferIndex = wIndex;

end 
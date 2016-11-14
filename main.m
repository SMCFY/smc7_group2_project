deviceReader = audioDeviceReader;
%deviceReader = dsp.AudioFileReader('Dude.wav');
deviceWriter = audioDeviceWriter('SampleRate',deviceReader.SampleRate);
deviceReader.SamplesPerFrame = 1024;

fs = deviceReader.SampleRate;

delay = Delay();
disp('Begin Signal Input...')

% initialize the centroid and delta with 'bogus' values
C_new = -1;
C_old = -1;
% delta is the amount the delay changes with 
% each new calculated centroid value
delta = -1; 
% initialize a counter for the intperpolator
count = 0;
% store all consecutive delay values (used for testing)
dtime = [];

tic
while toc<50
   
    mySignal = deviceReader();
    myProcessedSignal = process(delay, mySignal);
    deviceWriter(myProcessedSignal);
    
    % Adaptive part with some mapping 
    % use the interpolator to smooth out centroid-to-delay mapping
    [delay.DelayTime count C_old C_new delta] = interpolator(delay.DelayTime,mySignal, C_old,C_new, count, delta);
    
    % keeping track of all the calculated delay values (for testing purposes)
    dtime = [dtime delay.DelayTime];
    
    %disp(C);
    
end

release(deviceReader)
release(deviceWriter)

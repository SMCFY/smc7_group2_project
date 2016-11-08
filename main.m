deviceReader = audioDeviceReader;
%deviceReader = dsp.AudioFileReader('Dude.wav');
deviceWriter = audioDeviceWriter('SampleRate',deviceReader.SampleRate);
deviceReader.SamplesPerFrame = 1024;

fs = deviceReader.SampleRate;

delay = Delay();
disp('Begin Signal Input...')

tic
while toc<50
   
    mySignal = deviceReader();
    myProcessedSignal = process(delay, mySignal);
    deviceWriter(myProcessedSignal);
    
    onsetD(mySignal,32,T);
    
    %C = centroid(mySignal');
    %delay.DelayTime = C/100; % Adaptive part with some mapping 
    
    %disp(C);
    
end

release(deviceReader)
release(deviceWriter)

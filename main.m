deviceReader = audioDeviceReader;
%deviceReader = dsp.AudioFileReader('Dude.wav');
deviceWriter = audioDeviceWriter('SampleRate',deviceReader.SampleRate);
deviceReader.SamplesPerFrame = 1024;

delay = Delay2();
disp('Begin Signal Input...')

XmagPrev = 0;
threshold = 50;
bufferSize = deviceReader.SamplesPerFrame;
fs = deviceReader.SampleRate;

tic
while toc<30
   
    mySignal = deviceReader();
    myProcessedSignal = process(delay, mySignal);
    deviceWriter(myProcessedSignal);
    
    [onset, XmagPrev] = detectOnset(mySignal, threshold, XmagPrev);
    if onset == 1
    	disp('ONSET');
    end
    
    disp(estimateTempo(10, fs, bufferSize, mySignal, threshold, XmagPrev));
    
    %C = centroid(mySignal');
    %delay.DelayTime = C/100; % Adaptive part with some mapping 
    
    %disp(C);
    
end

release(deviceReader)
release(deviceWriter)

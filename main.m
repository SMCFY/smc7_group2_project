deviceReader = audioDeviceReader;
deviceWriter = audioDeviceWriter('SampleRate',deviceReader.SampleRate);
deviceReader.SamplesPerFrame = 256;

delay = Delay();
disp('Begin Signal Input...')
audioTestBench(delay);
tic
while toc<50
   
    mySignal = deviceReader();
    myProcessedSignal = delay.process(mySignal);
    deviceWriter(myProcessedSignal);
    
    C = centroid(mySignal, deviceReader.SampleRate);
    %disp(C);
    
end

release(deviceReader)
release(deviceWriter)

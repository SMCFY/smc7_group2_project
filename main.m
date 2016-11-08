deviceReader = audioDeviceReader;
%deviceReader = dsp.AudioFileReader('Dude.wav');
deviceWriter = audioDeviceWriter('SampleRate',deviceReader.SampleRate);
deviceReader.SamplesPerFrame = 64;

fs = deviceReader.SampleRate;
% setup for soundcard, soundcard = 1, if a soundcard is attached
soundcard = 0;
if(soundcard)
    d = deviceReader.getAudioDevices
    deviceReader.Device = d{3}     % set soundcard as default 
end

delay = Delay2();
disp('Begin Signal Input...')

tic
while toc<25
   
    mySignal = deviceReader();
    myProcessedSignal = process(delay, mySignal);
    deviceWriter(myProcessedSignal);
    
    C = centroid(mySignal');
    delay.DelayTime = C/100; % Adaptive part with some mapping 
    
    %disp(C);
    
end

release(deviceReader)
release(deviceWriter)

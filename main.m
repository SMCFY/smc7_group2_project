deviceReader = audioDeviceReader;
%deviceReader = dsp.AudioFileReader('Dude.wav');
deviceWriter = audioDeviceWriter('SampleRate',deviceReader.SampleRate);
deviceReader.SamplesPerFrame = 256;

delay = Delay2();
disp('Begin Signal Input...')

XmagPrev = 0;
threshold = 40;
runTime = 5; % run time in seconds
bufferSize = deviceReader.SamplesPerFrame;
fs = deviceReader.SampleRate;
onsetBuffer = zeros(runTime*fs,1);
count = 0;
noveltyC = [];
onsetV = [];
tic
while toc<runTime
   
    mySignal = deviceReader();
    %myProcessedSignal = process(delay, mySignal);
   % deviceWriter(myProcessedSignal);
    
    [SF, onset, XmagPrev] = detectOnset(mySignal, threshold, XmagPrev);
    if onset == 1
    	disp('ONSET');
        onsetBuffer(count*bufferSize,1) = 1;
        
    end
    count = count + 1;
    
    noveltyC = [noveltyC , SF];
    onsetV = [onsetV, onset];
    
end
%amountOfOnsets = sum(onsetBuffer);
onsetBuffer = onsetBuffer(1:count*bufferSize);
t = sprintf('Amount of onsets detected: %d', sum(onsetBuffer));
disp(t)
%runTime = (count*bufferSize)/fs
t = sprintf('run time in seconds: %1f', (count*bufferSize)/fs);
disp(t)

plot(noveltyC); hold on;
plot(onsetV*max(noveltyC));

release(deviceReader)
release(deviceWriter)

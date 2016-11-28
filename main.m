deviceReader = audioDeviceReader;
%deviceReader = dsp.AudioFileReader('/Users/Geri/Documents/MATLAB/sp/sound_files/Gregorythme_SOOML.mp3');
deviceWriter = audioDeviceWriter('SampleRate',deviceReader.SampleRate);
deviceReader.SamplesPerFrame = 256;

delay = Delay2();
disp('Begin Signal Input...')
fs = deviceReader.SampleRate;
%runTime = 5; % run time in seconds
bufferSize = deviceReader.SamplesPerFrame;
%count = 0;
%onsetBuffer = zeros(runTime*fs,1);

% ONSET TEST PARAMS -----------
XmagPrev = zeros(256,1);
durationInBuffers = round(5*fs/bufferSize); % 5 seconds
noveltyC = [];
magSpecSum = [];
curPos = 1;
onsetInterval = 0;
threshold = 30;
temporalThreshold = 0;
onsetDev = 0;
count = 0;
rate = 86;
outputValue = 0;
deltaY = 0;
TEMP = [];
% ------------------------------
%x = [];
tic
while toc<20
   
    mySignal = deviceReader();
    %myProcessedSignal = process(delay, mySignal);
   % deviceWriter(myProcessedSignal);
    
    [noveltyC, XmagPrev] = detectOnset(mySignal, noveltyC, XmagPrev);
    [onsetDev, onsetInterval, curPos] = localizeOnset(noveltyC, durationInBuffers, threshold, temporalThreshold, onsetInterval, curPos, onsetDev);
    
    magSpecSum = sum(abs(fft(mySignal)));
    
    if mod(count, rate) == 0
        
        targetValue = onsetDev;
        count = 0;
    end 
    
    [outputValue] = interpol(targetValue, outputValue, rate-count, deltaY);
   
    count = count + 1;
    
    TEMP = [TEMP outputValue];
    
    disp(outputValue);
    %x = [x; mySignal];
end

%amountOfOnsets = sum(onsetBuffer);
%onsetBuffer = onsetBuffer(1:count*bufferSize);
%t = sprintf('Amount of onsets detected: %d', sum(onsetBuffer));
%disp(t)
%runTime = (count*bufferSize)/fs
%t = sprintf('run time in seconds: %1f', (count*bufferSize)/fs);
%disp(t)


% ONSET PLOT ---------
%plot(filter([0.2, 0.2, 0.2, 0.2, 0.2], 1, noveltyC), 'g'); hold on;
%plot(magSpecSum, 'r'); hold on;
plot(TEMP);
legend('novelty curve', 'summed magnitude');
% ---------------------
%sound(x,fs);
release(deviceReader)
release(deviceWriter)
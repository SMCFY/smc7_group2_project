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
durationInSamples = round(2*fs/bufferSize); % 2 seconds
noveltyC = [];
magSpecSum = [];
curPos = 1;
threshold = 25;
% ------------------------------
%x = [];
tic
while toc<5
   
    mySignal = deviceReader();
    %myProcessedSignal = process(delay, mySignal);
   % deviceWriter(myProcessedSignal);
    
    [noveltyC, XmagPrev] = detectOnset(mySignal, noveltyC, XmagPrev);
    [onsetLoc, curPos] = localizeOnset(noveltyC, durationInSamples, threshold, curPos);
    
    %if onset == 1
    %	disp('ONSET');
        %onsetBuffer(count*bufferSize,1) = 1;
        
    %end
    %count = count + 1;
   
    magSpecSum = [magSpecSum, sum(abs(fft(mySignal)))];
    
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
plot(filter([0.2, 0.2, 0.2, 0.2, 0.2], 1, noveltyC), 'g'); hold on;
plot(magSpecSum, 'r'); hold on;
plot([zeros(1, durationInSamples + bufferSize), onsetLoc*10000], 'b');
legend('novelty curve', 'summed magnitude', 'onset location');
% ---------------------
%sound(x,fs);
release(deviceReader)
release(deviceWriter)
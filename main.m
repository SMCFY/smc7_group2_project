deviceReader = audioDeviceReader;
%deviceReader = dsp.AudioFileReader('/Users/Geri/Documents/MATLAB/sp/sound_files/Gregorythme_SOOML.mp3');
deviceWriter = audioDeviceWriter('SampleRate',deviceReader.SampleRate);
deviceReader.SamplesPerFrame = 256;

delay = Delay2();
disp('Begin Signal Input...')
fs = deviceReader.SampleRate;
%runTime = 5; % run time in seconds
%bufferSize = deviceReader.SamplesPerFrame;
%count = 0;
%onsetBuffer = zeros(runTime*fs,1);

% ONSET TEST PARAMS -----------
XmagPrev = zeros(256,1);
threshold = 700;
noveltyC = [];
% onsetV = [];
magSpecSum = [];
% ------------------------------

tic
while toc<5
   
    mySignal = deviceReader();
    %myProcessedSignal = process(delay, mySignal);
   % deviceWriter(myProcessedSignal);
    
    [noveltyC, XmagPrev] = detectOnset(mySignal, threshold, duration, noveltyC, XmagPrev);
    %if onset == 1
    %	disp('ONSET');
        %onsetBuffer(count*bufferSize,1) = 1;
        
    %end
    %count = count + 1;
   
    %onsetV = [onsetV, onset];
    magSpecSum = [magSpecSum, sum(abs(fft(mySignal)))/100];
end

%amountOfOnsets = sum(onsetBuffer);
%onsetBuffer = onsetBuffer(1:count*bufferSize);
%t = sprintf('Amount of onsets detected: %d', sum(onsetBuffer));
%disp(t)
%runTime = (count*bufferSize)/fs
%t = sprintf('run time in seconds: %1f', (count*bufferSize)/fs);
%disp(t)

b = [0.2, 0.2, 0.2, 0.2, 0.2];
a = [1];
noveltySmooth = filter(b,a,noveltyC);

% ONSET PLOT ---------
plot(noveltyC, 'g'); hold on;
plot(magSpecSum, 'r'); hold on;
plot(noveltySmooth, 'b');
legend('novelty curve', 'summed magnitude', 'smoothed novelty curve');
% ---------------------

release(deviceReader)
release(deviceWriter)
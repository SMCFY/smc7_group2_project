deviceReader = audioDeviceReader;
%deviceReader = dsp.AudioFileReader('Dude.wav');
deviceWriter = audioDeviceWriter('SampleRate',deviceReader.SampleRate);
deviceReader.SamplesPerFrame = 1024;

fs = deviceReader.SampleRate;

delay = Delay();
disp('Begin Signal Input...')

C_new = -1;
count = 0;
tic
dtime = [];
while toc<50
   
    mySignal = deviceReader();
    myProcessedSignal = process(delay, mySignal);
    deviceWriter(myProcessedSignal);
    
    % calculate the old and new centroid value
    C_old = C_new;
    C_new = centroid(mySignal');
    if (C_old == -1)
      % C_old and C_new are the same the first time through
      C_old = C_new;
    end

    % calculate a new interpolator value every 5 buffer lengths
    if (mod(count,5)==0)
      delta = interpolator(C_old,C_new);
    end

    % set a min and max threshold value for delay
    delayTime = delay.DelayTime + delta;
    if (delayTime < 0)
      delayTime = 0;
    elseif (delayTime > 1)
      delayTime = 1;
    end

    delay.DelayTime = delayTime; % Adaptive part with some mapping 
    dtime = [dtime delay.DelayTime];


    count = count + 1;
    if (count > 10000) % avoid overflow
      count = 0;
    end
    
    %disp(C);
    
end

release(deviceReader)
release(deviceWriter)

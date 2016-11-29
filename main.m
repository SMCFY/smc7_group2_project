deviceReader = audioDeviceReader;
%deviceReader = dsp.AudioFileReader('Dude.wav');
deviceWriter = audioDeviceWriter('SampleRate',deviceReader.SampleRate);
deviceReader.SamplesPerFrame = 1024;

fs = deviceReader.SampleRate;
% setup for soundcard, soundcard = 1, if a soundcard is attached.
soundcard = 0;
if(soundcard)
    d = deviceReader.getAudioDevices
    deviceReader.Device = d{3}     % set soundcard as default 
end

delay = Delay2();
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
i = 1;
E = [];
C = [];
tic
while toc<5
   
    mySignal = deviceReader();
    myProcessedSignal = process(delay, mySignal);
    deviceWriter(myProcessedSignal);
    
    % Adaptive part with some mapping 
    % use the interpolator to smooth out centroid-to-delay mapping
    [delay.Delay count C_old C_new delta] = interpolator(delay.Delay,mySignal, C_old,C_new, count, delta);
    
    % keeping track of all the calculated delay values (for testing purposes)
    dtime = [dtime delay.Delay];
    
    E(i) = sum(energyLevel(mySignal',1));
    C(i) = centroid(mySignal');
    %disp(C);
   
    i = i+ 1;
end

plot(C);
figure;
plot(E);
release(deviceReader)
release(deviceWriter)

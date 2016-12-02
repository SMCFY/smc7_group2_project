classdef Delay3 < audioPlugin
    % DELAY3
    % Adaptive digital delay/modulation effect
 
    properties
        PresetChoice = PresetEnum.Dreamy
        
        %Delay Base delay (s)
        %   Specify the base delay for echo effect as positive scalar
        %   value in seconds. Base delay value must be in the range between
        %   0 and 1 seconds. The default value of this property is 0.5.
        Delay = 1
        
        %Gain Gain of delay branch
        %   Specify the gain value as a positive scalar. This value must be
        %   in the range between 0 and 1. The default value of this
        %   property is 0.5.
        Gain = 1
        
        Mix = 1
        % Filter variables
        Fc = 20
        Q = 1
        
        % Vibrato
        vDepth = 1
        vRate = 1
        
        % Saturation
        sGain = 1
        sQ = 1
        sDist = 1
        sMix = 1
        
        % On/Off states
        DelayON = 0
        VibratoON = 0
        ReverseON = 0 
        SaturationON = 0
        LPFON = 0
        HPFON = 0
        
        % Mono --> Stereo switch
        Guitar = GuitarEnum.NotConnected
        Adaptive = AdaptiveEnum.ON
    end
    
    properties (Dependent)
        %FeedbackLevel Feedback gain
        %   Specify the feedback gain value as a positive scalar. This
        %   value must range from 0 to 0.5. Setting FeedbackLevel to 0
        %   turns off the feedback. The default value of this property is
        %   0.35.
        FeedbackLevel = 0.35 % preset.Feedback
        
        
    end
    
    properties (Constant)
        % Preset class containing the preset variables
        Dreamy = Preset(0.3, 0.5, 0.5, 0.6,...  % Delay, Gain, Feedback, Mix,
                        1500, 12, 10, 5,...      % Fc, filter Q, vDepth, vRate,
                        0.1, 0.1, 0.1, 0.2,...  % sGain, sQ, sDist, sMix
                        1, 1, 0, 0, 1, 0);      % DelayON, VibratoON, ReverseON, SaturationON, LPFON, HPFON
        Wacky = Preset(0.015, 1, 0.5, 0.7,...   % Delay, Gain, Feedback, Mix,
                       18000, 12, 10, 9,...     % Fc, filter Q, vDepth, vRate,
                       1, 1, 0.1, 0.5,...       % sGain, sQ, sDist, sMix
                       1, 1, 0, 0, 1, 0);       % DelayON, VibratoON, ReverseON, SaturationON, LPFON, HPFON
        Rewinder = Preset(0.8, 1, 0.5, 0.5,...  % Delay, Gain, Feedback, Mix,
                          4500, 20, 1, 1,...    % Fc, filter Q, vDepth, vRate,
                          1, 1, 1, 0.5,...      % sGain, sQ, sDist, sMix
                          0, 0, 1, 1, 1, 0);    % DelayON, VibratoON, ReverseON, SaturationON, LPFON, HPFON
        DirtyTape = Preset(0.2, 1, 0.5, 0.7,... % Delay, Gain, Feedback, Mix,
                           1250, 12, 8, 3,...   % Fc, filter Q, vDepth, vRate,
                           0.8, 3, 2.5, 0.5,... % sGain, sQ, sDist, sMix
                           1, 0, 0, 1, 1, 0);   % DelayON, VibratoON, ReverseON, SaturationON, LPFON, HPFON
        
        % audioPluginInterface manages the number of input/output channels
        % and uses audioPluginParameter to generate plugin UI parameters.
        PluginInterface = audioPluginInterface(...
            'InputChannels',2,...
            'OutputChannels',2,...
            'PluginName','Delay',...
            'VendorName', '', ...
            'VendorVersion', '3.1.4', ...
            'UniqueId', '4pvz',...
            audioPluginParameter('PresetChoice',...
            'DisplayName','Effect',...
            'Mapping',{'enum','Dreamy','Wacky','Rewinder','DirtyTape','Dry'}),... % switch enumerator with different states
            audioPluginParameter('Adaptive',...
            'DisplayName','Adaptive','Mapping',{'enum','OFF','ON'}),...
            audioPluginParameter('Guitar',...
            'DisplayName','Guitar','Mapping',{'enum','Not Connected','Connected'}));
    end
    
    properties (Access = private)
        % preset holder
        %preset
        %pFractionalDelay DelayFilter object for fractional delay with
        %linear interpolation
        pFractionalDelay
        
        %pSR Sample rate
        pSR
        % Vibrato buffer + index
        Buffer = zeros(192001,2)
        BufferIndex = 1
        sPointer = 1 % to keep track of sine wave
        
        % reverse buffer
        rBuffer
        rPointer = 1;
        
        % internal state used by LP and HP filter, all zeros the initial
        % state
        zHP = zeros(2)
        bHP = zeros(1,3)
        aHP = zeros(1,3)
        % internal state used by LP and HP filter, all zeros the initial
        % state
        zLP = zeros(2)
        bLP = zeros(1,3)
        aLP = zeros(1,3)
        
        %---------------------------
        % Adaptive variables 
        calAdaptive = 50; % amount of frames before calculate a new variable
        adaptiveCount = 0;
        adaptiveBuffer = [];
        
        % ONSET PARAMS -----------
        
        FFTBuffer = zeros(1,4096*2);
        durationInBuffers
        noveltyC = zeros(1,ceil(44100*2/64)); % maximum novelty curve window
        onsetTarget = 0;
        curPos = 1;
        onsetInterval = 0;
        threshold = 30;
        temporalThreshold = 0;
        onsetDev = 0;
        detectionCount = 0;
        detectionRate = 86;
        onsetOutput = 0;
        deltaY = 0;
        
        % --------------
        % Pitch 
        Pitch = 0;
        pitchCount = 0;
        pitchBufferSize = 20;
        pitchBuffer = [];
    end
    
    methods
        % Constructor, called when initializing effect
        function obj = Delay3
            fs = getSampleRate(obj);
            obj.pFractionalDelay = audioexample.DelayFilter( ...
                'FeedbackLevel', 0.35, ...
                'SampleRate', fs);
            obj.pSR = fs;
            % Reverse
            obj.rBuffer = zeros(fs*2+1,2); % max delay time in samples
            
            obj.durationInBuffers = 2*fs;
%             obj.preset = Preset(0.3, 0.5, 0.5, 0.8,...  % Delay, Gain, Feedback, Mix,
%                                 1500, 12, 9, 3,...      % Fc, filter Q, vDepth, vRate,
%                                 0.1, 0.1, 0.1, 0.2,...  % sGain, sQ, sDist, sMix
%                                 1, 1, 0, 0, 1, 0);      % DelayON, VibratoON, ReverseON, SaturationON, LPFON, HPFON
            UpdatePreset(obj);
        end
        
        %set and get for audioexample.DelayFilter class
        function set.FeedbackLevel(obj, val)
            obj.pFractionalDelay.FeedbackLevel = val;
        end
        function val = get.FeedbackLevel(obj)
            val = obj.pFractionalDelay.FeedbackLevel;
        end
        
        % resets internal states of buffers
        function reset(obj)
            % Reset sample rate
            fs = getSampleRate(obj);
            obj.pSR = fs;
            
            % Reset delay
            obj.pFractionalDelay.SampleRate = fs;
            reset(obj.pFractionalDelay);
            
            UpdatePreset(obj);
            
            % reset vibrato
            obj.Buffer = zeros(192001,2);
            obj.BufferIndex = 1;
            obj.sPointer = 1;
            
            % reset reverse buffer
            obj.rBuffer = zeros(fs*2+1,2); % max delay time in samples
            obj.rPointer = 1;
            
            % initialize internal filter state
            obj.zHP = zeros(2); obj.zLP = zeros(2);
            [obj.bHP, obj.aHP] = highPassCoeffs(obj.Fc, obj.Q, fs);
            [obj.bLP, obj.aLP] = lowPassCoeffs(obj.Fc, obj.Q, fs);
            
            %--------------------
            % Adaptive variables
            obj.adaptiveCount = 0;
            obj.adaptiveBuffer = [];
            
            % Onset
            obj.FFTBuffer = zeros(1,4096*2);
            obj.durationInBuffers = 2*fs;
            obj.noveltyC = zeros(1,ceil(44100*2/64));
            obj.onsetTarget = 0;
            obj.curPos = 1;
            obj.onsetInterval = 0;
            obj.threshold = 30;
            obj.temporalThreshold = 0;
            obj.onsetDev = 0;
            obj.detectionCount = 0;
            obj.detectionRate = 86;
            obj.onsetOutput = 0;
            obj.deltaY = 0;

            % --------------
            % Pitch 
            obj.Pitch = 0;
        end
        
        function calculateFilterCoeff(obj)
            % Calculate Butterworth filter coefficients 
            if obj.HPFON
                [obj.bHP, obj.aHP] = highPassCoeffs(obj.Fc, obj.Q, obj.pSR);
            end
            if obj.LPFON
                [obj.bLP, obj.aLP] = lowPassCoeffs(obj.Fc, obj.Q, obj.pSR);
            end
        end
        
        function set.PresetChoice(obj, preset)
            obj.PresetChoice = preset;
            UpdatePreset(obj);
        end
        
        function set.Adaptive(obj, adap)
            obj.Adaptive = adap;
            UpdatePreset(obj);
        end
        
        function UpdatePreset(obj)
            
            switch obj.PresetChoice
                case PresetEnum.Dreamy
                    obj.Delay = obj.Dreamy.Delay;
                    obj.Gain = obj.Dreamy.Gain;
                    obj.FeedbackLevel = obj.Dreamy.Feedback;
                    obj.Mix = obj.Dreamy.Mix;
                    % Filter variables
                    obj.Fc = obj.Dreamy.Fc;
                    obj.Q = obj.Dreamy.Q;

                    % Vibrato
                    obj.vDepth = obj.Dreamy.vDepth;
                    obj.vRate = obj.Dreamy.vRate;

                    % Saturation
                    obj.sGain = obj.Dreamy.sGain;
                    obj.sQ = obj.Dreamy.sQ;
                    obj.sDist = obj.Dreamy.sDist;
                    obj.sMix = obj.Dreamy.sMix;
                    obj.DelayON = obj.Dreamy.DelayON;
                    obj.VibratoON = obj.Dreamy.VibratoON;
                    obj.ReverseON = obj.Dreamy.ReverseON;
                    obj.SaturationON = obj.Dreamy.SaturationON;
                    obj.LPFON = obj.Dreamy.LPFON;
                    obj.HPFON = obj.Dreamy.HPFON;
        
                case PresetEnum.Wacky
                    obj.Delay = obj.Wacky.Delay;
                    obj.Gain = obj.Wacky.Gain;
                    obj.FeedbackLevel = obj.Wacky.Feedback;
                    obj.Mix = obj.Wacky.Mix;
                    % Filter variables
                    obj.Fc = obj.Wacky.Fc;
                    obj.Q = obj.Wacky.Q;

                    % Vibrato
                    obj.vDepth = obj.Wacky.vDepth;
                    obj.vRate = obj.Wacky.vRate;

                    % Saturation
                    obj.sGain = obj.Wacky.sGain;
                    obj.sQ = obj.Wacky.sQ;
                    obj.sDist = obj.Wacky.sDist;
                    obj.sMix = obj.Wacky.sMix;
                    obj.DelayON = obj.Wacky.DelayON;
                    obj.VibratoON = obj.Wacky.VibratoON;
                    obj.ReverseON = obj.Wacky.ReverseON;
                    obj.SaturationON = obj.Wacky.SaturationON;
                    obj.LPFON = obj.Wacky.LPFON;
                    obj.HPFON = obj.Wacky.HPFON;
        
                case PresetEnum.Rewinder
                   obj.Delay = obj.Rewinder.Delay;
                    obj.Gain = obj.Rewinder.Gain;
                    obj.FeedbackLevel = obj.Rewinder.Feedback;
                    obj.Mix = obj.Rewinder.Mix;
                    % Filter variables
                    obj.Fc = obj.Rewinder.Fc;
                    obj.Q = obj.Rewinder.Q;

                    % Vibrato
                    obj.vDepth = obj.Rewinder.vDepth;
                    obj.vRate = obj.Rewinder.vRate;

                    % Saturation
                    obj.sGain = obj.Rewinder.sGain;
                    obj.sQ = obj.Rewinder.sQ;
                    obj.sDist = obj.Rewinder.sDist;
                    obj.sMix = obj.Rewinder.sMix;
                    obj.DelayON = obj.Rewinder.DelayON;
                    obj.VibratoON = obj.Rewinder.VibratoON;
                    obj.ReverseON = obj.Rewinder.ReverseON;
                    obj.SaturationON = obj.Rewinder.SaturationON;
                    obj.LPFON = obj.Rewinder.LPFON;
                    obj.HPFON = obj.Rewinder.HPFON;
        
                case PresetEnum.DirtyTape
                    obj.Delay = obj.DirtyTape.Delay;
                    obj.Gain = obj.DirtyTape.Gain;
                    obj.FeedbackLevel = obj.DirtyTape.Feedback;
                    obj.Mix = obj.DirtyTape.Mix;
                    % Filter variables
                    obj.Fc = obj.DirtyTape.Fc;
                    obj.Q = obj.DirtyTape.Q;

                    % Vibrato
                    obj.vDepth = obj.DirtyTape.vDepth;
                    obj.vRate = obj.DirtyTape.vRate;

                    % Saturation
                    obj.sGain = obj.DirtyTape.sGain;
                    obj.sQ = obj.DirtyTape.sQ;
                    obj.sDist = obj.DirtyTape.sDist;
                    obj.sMix = obj.DirtyTape.sMix;
                    obj.DelayON = obj.DirtyTape.DelayON;
                    obj.VibratoON = obj.DirtyTape.VibratoON;
                    obj.ReverseON = obj.DirtyTape.ReverseON;
                    obj.SaturationON = obj.DirtyTape.SaturationON;
                    obj.LPFON = obj.DirtyTape.LPFON;
                    obj.HPFON = obj.DirtyTape.HPFON;
        
            end
            calculateFilterCoeff(obj);
        end
        
        % Onset Detection
        function onset(obj, x)
            
            [L,~] = size(x);
            
            % If the bufferSize has changed
            %if length(obj.noveltyC) == 0
                %obj.FFTBuffer = zeros(L,1);
                %obj.noveltyC = zeros(round(obj.durationInBuffers/L),1);
            %end
	    noveltyCLength = round(obj.durationInBuffers/L);
            
            [obj.noveltyC, obj.FFTBuffer] = detectOnset(x, obj.noveltyC, obj.FFTBuffer,noveltyCLength);
            [obj.onsetDev, obj.onsetInterval, obj.curPos] = localizeOnset(obj.noveltyC, round(obj.durationInBuffers/L),...
                obj.threshold, obj.temporalThreshold, obj.onsetInterval, obj.curPos, obj.onsetDev, noveltyCLength);
            
            if mod(obj.detectionCount, obj.detectionRate) == 0
                obj.onsetTarget = obj.onsetDev;
                obj.detectionCount = 0;
            end
            
            [obj.onsetOutput] = interpol(obj.onsetTarget, obj.onsetOutput, obj.detectionRate-obj.detectionCount, obj.deltaY);
           
           obj.detectionCount = obj.detectionCount + 1;
           
        end
        
        %Adaptive mapping function. 
        function addAdaptive(obj,x)
            %obj.adaptiveCount = 0;
            switch obj.PresetChoice
                case PresetEnum.Dreamy
                    %Extract audio features
                    %onset(obj, x); % obj.onsetOutput stores the onset deviation in 5*fs/frameSize
                    %obj.Pitch = pitch_detector(x,obj.pSR); % obj.Pitch
                    %pitch(obj, x);
                    %obj.Mix = mapRange(0.8,0.6,600,60,obj.Pitch);
                    %obj.vRate = mapRange(10,2,0.9,0.1,obj.onsetOutput);
                    %calculateFilterCoeff(obj);
                    %disp(obj.onsetOutput)
                    
                    if obj.calAdaptive < obj.adaptiveCount
                        obj.adaptiveCount = 0;
                        onset(obj, x); % obj.onsetOutput stores the onset deviation in 5*fs/frameSize
                        obj.Pitch = pitch_detector(x,obj.pSR);
                        
                        E = energyLevel(x(:,1)',1);
                        C = centroid(x(:,1)', obj.pSR);%/(obj.pSR/2);
                        %disp(round(C/(obj.pSR/2) * 1e1)/1e1);
                        %disp(E)

                        obj.FeedbackLevel = mapRange(0.8,0.4,0.08,0,C);
                        obj.Mix = mapRange(0.8,0.5,1000,60,obj.Pitch);
                        obj.vDepth = mapRange(20,7,2,0,E);
                        obj.vRate  = mapRange(7,3,0.3,0,obj.onsetOutput); 
                        obj.Q = mapRange(10,90,1000,80,obj.Pitch);
                        obj.Fc = mapRange(2000,1500,0.08,0,C);
                        obj.FeedbackLevel = mapRange(0.8,0.3,0.08,0,C);
                        obj.Fc = mapRange(1500,500,1,0,E);
                        calculateFilterCoeff(obj);
                    end
                    %Map raw feature data to ranges for the control
                    %parameters
                    %disp(obj.sQ);
                case PresetEnum.Wacky
                    %Extract audio features
                    onset(obj, x); % obj.onsetOutput stores the onset deviation in 5*fs/frameSize
                    obj.Pitch = pitch_detector(x,obj.pSR); % obj.Pitch
                    obj.FeedbackLevel = mapRange(0.7,0.3,500,80,obj.Pitch);
                    obj.vRate = mapRange(11,8,1,0.1,obj.onsetOutput);  
                    if obj.calAdaptive > obj.adaptiveCount
                        obj.adaptiveCount = 0;
                        E = sum(energyLevel(x(:,1)',1));
                        C = centroid(x', obj.pSR);
                        obj.Mix = mapRange(0.9,0.6,1,0,E);
                        obj.FeedbackLevel = mapRange(0.9,0.5,1,0,C);
                    end
                case PresetEnum.Rewinder
                    %Extract audio features
                    onset(obj, x); % obj.onsetOutput stores the onset deviation in 5*fs/frameSize
                    obj.Pitch = pitch_detector(x,obj.pSR); % obj.Pitch
                    obj.Q = mapRange(45,3,500,80,obj.Pitch);
                    if obj.calAdaptive > obj.adaptiveCount
                        obj.adaptiveCount = 0;
                        E = sum(energyLevel(x(:,1)',1));
                        C = centroid(x', obj.pSR);
                        obj.Fc = mapRange(20000,3000,0.5,1,C);
                        obj.FeedbackLevel = mapRange(0.9,0.3,1,0,E);
                    end
                case PresetEnum.DirtyTape
                    %Extract audio features
                    onset(obj, x); % obj.onsetOutput stores the onset deviation in 5*fs/frameSize
                    obj.Pitch = pitch_detector(x,obj.pSR); % obj.Pitch
                    obj.FeedbackLevel = mapRange(0.8,0.3,500,80,obj.Pitch);
                    if obj.calAdaptive > obj.adaptiveCount
                        obj.adaptiveCount = 0;
                        E = sum(energyLevel(x(:,1)',1));
                        C = centroid(x', obj.pSR);
                        obj.sDist = mapRange(7,3,1,0,E);
                        obj.vRate = mapRange(4,1,1,0,C);
                    end
            end
            obj.adaptiveCount = obj.adaptiveCount + 1;
        end
        
        function [x, xd] = setEffect(obj, x, xd)
            % Function that calculates effects
            if obj.DelayON
                delayInSamples = obj.Delay*obj.pSR;
                
                % Delay the input
                xd = obj.pFractionalDelay(delayInSamples, x);
                
                % Add effects to the delayed signal
                if obj.VibratoON
                    % Input: signal, fs, modfreq, width, buffer,bufferIndex, sineBuffer
                    % Output: vibrato, buffer, bufferIndex, Sine wave
                    % pointer
                    [xd, obj.Buffer, obj.BufferIndex, obj.sPointer] = vibrato(xd, obj.pSR, obj.vRate, obj.vDepth, obj.Buffer, obj.BufferIndex, obj.sPointer);
                end
                if obj.ReverseON
                    %delayInSamples = obj.Delay*obj.pSR;
                    [xd, obj.rBuffer, obj.rPointer] = reverse(xd, obj.rBuffer, delayInSamples, obj.rPointer);
                end
                if obj.SaturationON
                    % function [y,zHP,zLP]=tube(x, gain, Q, dist, rh, rl, mix,zHP, zLP)
                    
                    [xd,~,~] = tube(xd, obj.sGain, obj.sQ, obj.sDist, 0,0, obj.sMix, 0,0);
                end
                
                if obj.LPFON
                    [xd,obj.zLP] = filter(obj.bLP, obj.aLP, xd, obj.zLP);
                end
                
                if obj.HPFON
                    [xd,obj.zHP] = filter(obj.bHP, obj.aHP, xd, obj.zHP);
                end
            else
                % Add the effects to the input signal
                if obj.VibratoON
                    % Input: signal, fs, modfreq, width, buffer,bufferIndex, sineBuffer
                    % Output: vibrato, buffer, bufferIndex, Sine wave pointer
                    [x, obj.Buffer, obj.BufferIndex, obj.sPointer] = vibrato(x, obj.pSR, obj.vRate, obj.vDepth, obj.Buffer, obj.BufferIndex, obj.sPointer);
                end
                if obj.SaturationON
                    % function [y,zHP,zLP]=tube(x, gain, Q, dist, rh, rl, mix,zHP, zLP)
                    [x,~,~] = tube(x, obj.sGain, obj.sQ, obj.sDist,0,0, obj.sMix,0,0);
                end
                if obj.ReverseON
                    delayInSamples = obj.Delay*obj.pSR;
                    [xd, obj.rBuffer, obj.rPointer] = reverse(x, obj.rBuffer, delayInSamples, obj.rPointer);
                end
                if obj.LPFON
                    [xd,obj.zLP] = filter(obj.bLP, obj.aLP, xd, obj.zLP);
                end
                if obj.HPFON
                    [xd,obj.zHP] = filter(obj.bHP, obj.aHP, xd, obj.zHP);
                end
            end
        end
        
        
        % output function, gets called at buffer speed
        function y = process(obj, x)
            if obj.Guitar == GuitarEnum.Connected
                x(:,2) = x(:,1);
            end
            if obj.Adaptive == AdaptiveEnum.ON
                addAdaptive(obj,x)
            end
            xd = zeros(size(x));
	    % calculate effect + filter
        if obj.PresetChoice == PresetEnum.Dry
            y = x;
        else
            [x, xd] = setEffect(obj, x, xd);
            
            % Calculate output by adding wet and dry signal in appropriate
            % ratio
            mix = obj.Mix;
            y = (1-mix)*x + (mix)*(obj.Gain.*xd);
        end
        end
    end
end
% Filter calculations from RT audio white paper
% Butterworth two pole high pass filter coefficients
function [b, a] = highPassCoeffs(Fc, Q, Fs)
    w0 = 2*pi*Fc/Fs;
    alpha = sin(w0)/sqrt(2 * Q);
    cosw0 = cos(w0);
    norm = 1/(1+alpha);
    b = (1 + cosw0)*norm * [.5  -1  .5];
    a = [1  -2*cosw0*norm  (1 - alpha)*norm];
end

% Butterworth low pass filter coefficients
function [b, a] = lowPassCoeffs(Fc,Q, Fs)
    w0 = 2*pi*Fc/Fs;
    alpha = sin(w0)/sqrt(2 * Q);
    cosw0 = cos(w0);
    norm = 1/(1+alpha);
    b = (1 - cosw0)*norm * [.5 1 .5];
    a = [1 -2*cosw0*norm  (1 - alpha)*norm];
end

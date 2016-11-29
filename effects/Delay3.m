classdef Delay3 < audioPlugin
    % DELAY3
    % Adaptive digital delay/modulation effect
 
    properties
        PresetChoice = PresetEnum.Dreamy
        preset = Preset.Dreamy
        %Delay Base delay (s)
        %   Specify the base delay for echo effect as positive scalar
        %   value in seconds. Base delay value must be in the range between
        %   0 and 1 seconds. The default value of this property is 0.5.
        Delay
        
        %Gain Gain of delay branch
        %   Specify the gain value as a positive scalar. This value must be
        %   in the range between 0 and 1. The default value of this
        %   property is 0.5.
        Gain
        
        Mix
        % Filter variables
        Fc
        Q
        
        % Vibrato
        vDepth
        vRate
        
        % Saturation
        sGain
        sQ
        sDist
        sMix
        
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
    
    properties
    end
    
    properties (Constant)
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
            'Mapping',{'enum','Dreamy','Wacky','Rewinder','DirtyTape'}),... % switch enumerator with different states
            audioPluginParameter('Adaptive',...
            'DisplayName','Adaptive','Mapping',{'enum','OFF','ON'}),...
            audioPluginParameter('Guitar',...
            'DisplayName','Guitar','Mapping',{'enum','Not Connected','Connected'}));
    end
    
    properties (Access = private)
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
        calAdaptive = 20; % amount of frames before calculate a new variable
           
        adaptiveCount = 0;
        
        % ONSET TEST PARAMS -----------
        FFTBuffer = 0;
        durationInBuffers
        noveltyC = [];
        onsetTarget = 0;
        %magSpecSum = [];
        curPos = 1;
        onsetInterval = 0;
        threshold = 30;
        temporalThreshold = 0;
        onsetDev = 0;
        detectionCount = 0;
        detectionRate = 86;
        onsetOutput = 0;
        deltaY = 0;
        %TEMP = [];
        
        % --------------
        % Pitch 
        pitchCount = 0;
        pitchBuffer = [];
        pitchBufferSize = 5;
        Pitch = 0;
        
    end
    
    methods
        % Constructor, called when initializing effect
        function obj = Delay3
            fs = getSampleRate(obj);
            obj.pFractionalDelay = audioexample.DelayFilter( ...
                'FeedbackLevel', 0.35, ...
                'SampleRate', fs);
            obj.pSR = fs;
            %             % Reverse
            obj.rBuffer = zeros(fs*2+1,2); % max delay time in samples
            
            obj.durationInBuffers = 5*fs;

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
            [obj.bHP, obj.aHP] = highPassCoeffs(obj.preset.Fc, obj.preset.Q, fs);
            [obj.bLP, obj.aLP] = lowPassCoeffs(obj.preset.Fc, obj.preset.Q, fs);
            
            %--------------------
            % Adaptive variables
            obj.adaptiveCount = 0;
            
            % Onset
            obj.FFTBuffer = 0;
            obj.durationInBuffers = 5*fs;
            obj.noveltyC = [];
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
            obj.pitchCount = 0;
            obj.pitchBuffer = [];
            obj.pitchBufferSize = 5;
            obj.Pitch = 0;
        end
        
        function calculateFilterCoeff(obj)
            % Calculate Butterworth filter coefficients 
            if obj.preset.HPFON
                [obj.bHP, obj.aHP] = highPassCoeffs(obj.Fc, obj.Q, obj.pSR);
            end
            if obj.preset.LPFON
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
                    obj.preset = Preset.Dreamy;
                case PresetEnum.Wacky
                    obj.preset = Preset.Wacky;
                case PresetEnum.Rewinder
                    obj.preset = Preset.Rewinder;
                case PresetEnum.DirtyTape
                    obj.preset = Preset.DirtyTape;
            end
            
            obj.Delay = obj.preset.Delay;
            obj.Gain = obj.preset.Gain;
            obj.FeedbackLevel = obj.preset.Feedback;
            obj.Mix = obj.preset.Mix;
            % Filter variables
            obj.Fc = obj.preset.Fc;
            obj.Q = obj.preset.Q;

            % Vibrato
            obj.vDepth = obj.preset.vDepth;
            obj.vRate = obj.preset.vRate;

            % Saturation
            obj.sGain = obj.preset.sGain;
            obj.sQ = obj.preset.sQ;
            obj.sDist = obj.preset.sDist;
            obj.sMix = obj.preset.sMix;

            calculateFilterCoeff(obj);
        end
        
        % Onset Detection
        function onset(obj, x)
            
            [l,~] = size(x);
            
            [obj.noveltyC, obj.FFTBuffer] = detectOnset(x, obj.noveltyC, obj.FFTBuffer);
            [obj.onsetDev, obj.onsetInterval, obj.curPos] = localizeOnset(obj.noveltyC, round(obj.durationInBuffers/l),...
                obj.threshold, obj.temporalThreshold, obj.onsetInterval, obj.curPos, obj.onsetDev);
            
            if mod(obj.detectionCount, obj.detectionRate) == 0
                obj.onsetTarget = obj.onsetDev;
                obj.detectionCount = 0;
            end
            
            [obj.onsetOutput] = interpol(obj.onsetTarget, obj.onsetOutput, obj.detectionRate-obj.detectionCount, obj.deltaY);
           
           obj.detectionCount = obj.detectionCount + 1;
           
        end
        
        function pitch(obj, x)
            if obj.pitchCount == obj.pitchBufferSize
                obj.pitchCount = 0;
                obj.pitchBuffer = [];
            else
                obj.pitchBuffer = [obj.pitchBuffer; x];
            end
            obj.pitchCount = obj.pitchCount + 1;
            
            if mod(obj.pitchCount,obj.pitchBufferSize) == obj.pitchBufferSize-1
                obj.Pitch = pitch_detector(obj.pitchBuffer, obj.pSR);
                %disp(obj.Pitch)
            end
        end
        %Adaptive mapping function. 
        function addAdaptive(obj,x)
            %obj.adaptiveCount = 0;
            switch obj.preset
                case Preset.Dreamy
                    %Extract audio features
                    onset(obj, x); % obj.onsetOutput stores the onset deviation in 5*fs/frameSize
                    pitch(obj,x); % obj.Pitch
                    obj.Mix = mapRange(0.6,0.4,500,80,obj.Pitch);
                    obj.vRate = mapRange(10,2,1,0.1,obj.onsetOutput);
                    %calculateFilterCoeff(obj);
                    %disp(obj.vRate);
                    
                    if obj.calAdaptive < obj.adaptiveCount
                        obj.adaptiveCount = 0;
                        E = energyLevel(x(:,1)',1);
                        C = centroid(x')/(obj.pSR/2);
                        %disp(round(C/(obj.pSR/2) * 1e1)/1e1);
                        disp(C)
                        obj.FeedbackLevel = mapRange(0.8,0.3,0.8,0.5,C);
                        obj.Fc = mapRange(1500,500,1,0,E);
                        calculateFilterCoeff(obj);
                    end
                    %Map raw feature data to ranges for the control
                    %parameters
                    %disp(obj.sQ);
                case Preset.Wacky
                    %Extract audio features
                    onset(obj, x); % obj.onsetOutput stores the onset deviation in 5*fs/frameSize
                    pitch(obj,x); % obj.Pitch
                    obj.FeedbackLevel = mapRange(0.7,0.3,500,80,obj.Pitch);
                    obj.vRate = mapRange(11,8,1,0.1,obj.onsetOutput);
                    if obj.calAdaptive > obj.adaptiveCount
                        obj.adaptiveCount = 0;
                        E = sum(energyLevel(x(:,1)',1));
                        C = centroid(x');
                        obj.Mix = mapRange(0.9,0.6,1,0,E);
                        obj.FeedbackLevel = mapRange(0.9,0.5,1,0,C);
                    end
                case Preset.Rewinder
                    %Extract audio features
                    onset(obj, x); % obj.onsetOutput stores the onset deviation in 5*fs/frameSize
                    pitch(obj,x); % obj.Pitch
                    obj.Q = mapRange(45,3,500,80,obj.Pitch);
                    if obj.calAdaptive > obj.adaptiveCount
                        obj.adaptiveCount = 0;
                        E = sum(energyLevel(x(:,1)',1));
                        C = centroid(x');
                        obj.Fc = mapRange(20000,3000,0.5,1,C);
                        obj.FeedbackLevel = mapRange(0.9,0.3,1,0,E);
                    end
                case Preset.DirtyTape
                    %Extract audio features
                    onset(obj, x); % obj.onsetOutput stores the onset deviation in 5*fs/frameSize
                    pitch(obj,x); % obj.Pitch
                    obj.FeedbackLevel = mapRange(0.8,0.3,500,80,obj.Pitch);
                    if obj.calAdaptive > obj.adaptiveCount
                        obj.adaptiveCount = 0;
                        E = sum(energyLevel(x(:,1)',1));
                        C = centroid(x');
                        obj.sDist = mapRange(7,3,1,0,E);
                        obj.vRate = mapRange(4,1,1,0,C);
                    end
            end
            obj.adaptiveCount = obj.adaptiveCount + 1;
        end
        
        function [x, xd] = setEffect(obj, x)
            % Function that calculates effects
            if obj.preset.DelayON
                delayInSamples = obj.Delay*obj.pSR;
                
                % Delay the input
                xd = obj.pFractionalDelay(delayInSamples, x);
                
                % Add effects to the delayed signal
                if obj.preset.VibratoON
                    % Input: signal, fs, modfreq, width, buffer,bufferIndex, sineBuffer
                    % Output: vibrato, buffer, bufferIndex, Sine wave
                    % pointer
                    [xd, obj.Buffer, obj.BufferIndex, obj.sPointer] = vibrato(xd, obj.pSR, obj.vRate, obj.vDepth, obj.Buffer, obj.BufferIndex, obj.sPointer);
                end
                if obj.preset.ReverseON
                    %delayInSamples = obj.Delay*obj.pSR;
                    [xd, obj.rBuffer, obj.rPointer] = reverse(xd, obj.rBuffer, delayInSamples, obj.rPointer);
                end
                if obj.preset.SaturationON
                    % function [y,zHP,zLP]=tube(x, gain, Q, dist, rh, rl, mix,zHP, zLP)
                    
                    [xd,~,~] = tube(xd, obj.sGain, obj.sQ, obj.sDist, 0,0, obj.sMix, 0,0);
                end
                
                if obj.preset.LPFON
                    [xd,obj.zLP] = filter(obj.bLP, obj.aLP, xd, obj.zLP);
                end
                
                if obj.preset.HPFON
                    [xd,obj.zHP] = filter(obj.bHP, obj.aHP, xd, obj.zHP);
                end
            else
                % Add the effects to the input signal
                if obj.preset.VibratoON
                    % Input: signal, fs, modfreq, width, buffer,bufferIndex, sineBuffer
                    % Output: vibrato, buffer, bufferIndex, Sine wave pointer
                    [x, obj.Buffer, obj.BufferIndex, obj.sPointer] = vibrato(x, obj.pSR, obj.vRate, obj.vDepth, obj.Buffer, obj.BufferIndex, obj.sPointer);
                end
                if obj.preset.SaturationON
                    % function [y,zHP,zLP]=tube(x, gain, Q, dist, rh, rl, mix,zHP, zLP)
                    [x,~,~] = tube(x, obj.sGain, obj.sQ, obj.sDist,0,0, obj.sMix,0,0);
                end
                if obj.preset.ReverseON
                    delayInSamples = obj.Delay*obj.pSR;
                    [xd, obj.rBuffer, obj.rPointer] = reverse(x, obj.rBuffer, delayInSamples, obj.rPointer);
                end
                if obj.preset.LPFON
                    [xd,obj.zLP] = filter(obj.bLP, obj.aLP, xd, obj.zLP);
                end
                if obj.preset.HPFON
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
            % calculate effect + filter
            [x, xd] = setEffect(obj, x);
            
            % Calculate output by adding wet and dry signal in appropriate
            % ratio
            mix = obj.Mix;
            y = (1-mix)*x + (mix)*(obj.Gain.*xd);
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
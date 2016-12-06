classdef DreamyOne < audioPlugin
    % DreamyOne
    % Adaptive digital delay/modulation effect
 
    properties
        PresetChoice = PresetEnumDreamy.Dreamy
        
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
        
        % Mono --> Stereo switch
        Guitar = GuitarEnum.NotConnected
        Adaptive = AdaptiveEnumDreamy.A
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
  
        % audioPluginInterface manages the number of input/output channels
        % and uses audioPluginParameter to generate plugin UI parameters.
        PluginInterface = audioPluginInterface(...
            'InputChannels',2,...
            'OutputChannels',2,...
            'PluginName','DreamyOne',...
            'VendorName', '', ...
            'VendorVersion', '1.0', ...
            'UniqueId', '4pvz',...
            audioPluginParameter('PresetChoice',...
            'DisplayName','Effect',...
            'Mapping',{'enum','Dreamy','Dry'}),... % switch enumerator with different states
            audioPluginParameter('Adaptive',...
            'DisplayName','Version','Mapping',{'enum','A','B'}),...
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
        
        % internal state used by LP filter, all zeros the initial
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
        noveltyC = zeros(1,ceil(192000*2/2)); % maximum novelty curve window
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
        function obj = DreamyOne
            fs = getSampleRate(obj);
            obj.pFractionalDelay = audioexample.DelayFilter( ...
                'FeedbackLevel', 0.35, ...
                'SampleRate', fs);
            obj.pSR = fs;
            
            obj.durationInBuffers = 2*fs;

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
                       
            % initialize internal filter state
            obj.zLP = zeros(2);
            [obj.bLP, obj.aLP] = lowPassCoeffs(obj.Fc, obj.Q, fs);
            
            %--------------------
            % Adaptive variables
            obj.adaptiveCount = 0;
            obj.adaptiveBuffer = [];
            
            % Onset
            obj.FFTBuffer = zeros(1,4096*2);
            obj.durationInBuffers = 2*fs;
            obj.noveltyC = zeros(1,ceil(192000*2/2));
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
            [obj.bLP, obj.aLP] = lowPassCoeffs(obj.Fc, obj.Q, obj.pSR);
            
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
                case PresetEnumDreamy.Dreamy
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
            end
            calculateFilterCoeff(obj);
        end
        
        % Onset Detection
        function onset(obj, x)
            
            [L,~] = size(x);
            
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
            
            %Extract audio features
            if obj.calAdaptive < obj.adaptiveCount
                obj.adaptiveCount = 0;
                
                % Feature Extraction
                onset(obj, x); % obj.onsetOutput stores the onset deviation in 5*fs/frameSize
                obj.Pitch = pitch_detector(x,obj.pSR);
                E = energyLevel(x(:,1)',1);
                C = centroid(x(:,1)', obj.pSR);
                
                % Adaptive mapping
                obj.Mix = mapRange(0.8,0.5,1000,60,obj.Pitch);
                obj.vDepth = mapRange(20,7,2,0,E);
                obj.vRate  = mapRange(7,3,0.3,0,obj.onsetOutput);
                obj.Q = mapRange(10,90,1000,80,obj.Pitch);
                obj.FeedbackLevel = mapRange(0.8,0.3,0.08,0,C);
                obj.Fc = mapRange(2000,1500,1,0,E);
                
                calculateFilterCoeff(obj);
            end
            obj.adaptiveCount = obj.adaptiveCount + 1;
        end
        
        function [x, xd] = setEffect(obj, x)
            % Function that calculates effects
            
            delayInSamples = obj.Delay*obj.pSR;
            
            % Delay the input
            xd = obj.pFractionalDelay(delayInSamples, x);
            
            % Add effects to the delayed signal
            
            % Input: signal, fs, modfreq, width, buffer,bufferIndex, sineBuffer
            % Output: vibrato, buffer, bufferIndex, Sine wave
            % pointer
            [xd, obj.Buffer, obj.BufferIndex, obj.sPointer] = vibrato(xd, obj.pSR, obj.vRate, obj.vDepth, obj.Buffer, obj.BufferIndex, obj.sPointer);
            
            % LP Filter
            [xd,obj.zLP] = filter(obj.bLP, obj.aLP, xd, obj.zLP);      
        end
            
        % output function, gets called at buffer speed
        function y = process(obj, x)
            if obj.Guitar == GuitarEnum.Connected
                x(:,2) = x(:,1);
            end
            if obj.Adaptive == AdaptiveEnumDreamy.B
                addAdaptive(obj,x)
            end
            %xd = zeros(size(x));
	    % calculate effect + filter
            if obj.PresetChoice == PresetEnumDreamy.Dry
                y = x;
            else
                [x, xd] = setEffect(obj, x);

                % Calculate output by adding wet and dry signal in appropriate
                % ratio
                mix = obj.Mix;
                y = (1-mix)*x + (mix)*(obj.Gain.*xd);
            end
        end
    end
end

% Filter calculations from RT audio white paper
% Butterworth low pass filter coefficients
function [b, a] = lowPassCoeffs(Fc,Q, Fs)
    w0 = 2*pi*Fc/Fs;
    alpha = sin(w0)/sqrt(2 * Q);
    cosw0 = cos(w0);
    norm = 1/(1+alpha);
    b = (1 - cosw0)*norm * [.5 1 .5];
    a = [1 -2*cosw0*norm  (1 - alpha)*norm];
end

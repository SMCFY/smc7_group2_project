classdef Delay3 < audioPlugin
    % DELAY2
    %           The effect delays the input signal from 0 - 1 second.
    %           Works in real-time and can generate an audio-plugin
    %           by using built-in functions from audio system toolbox
    % Input
    %           Delay: returns the delaytime in seconds
    %           Gain: Amplitude of the delayed signal, 0-1
    %           Feedback: how much of the delayed signal is feeded back into the
    %           effect. This should not be over 0.9 due to stability.
    %           Wet/Dry: How much of the original signal (dry ) and
    %           delayed signal (wet) is present in the out. Can mixed between 0-1.
    %           At 0 only the dry signal is present, at 1 the output is completely wet.
    % Effects
    
    %           Vibrato:
    %           Adds vibrato to the delayed signal. Can be controlled through
    %           'Vibrate Rate' and 'Vibrato Depth'
    %
    %           Reverse:
    %           Reverses the delayed signal.
    %
    %           Saturation:
    %           Distorts the delayed signal. The amount of distortion can be
    %           controlled with 'Saturation Amount'
    %
    %           HighPass and LowPass Filter:
    %           You can add a highpass or a lowpass filter to the delayed
    %           signal. The cutoff frequency can be controlled with the parameter Fc, and the
    %           quality of the filter can be controlled with Q.
    %
    %           Effects to implemented: Reverb?, grainular
    %           delay.
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
        Width
        Rate
        
        % Saturation
        sGain
        sQ
        sDist
        sMix
        
        % Mono --> Stereo switch
        Guitar = GuitarEnum.NotConnected
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
        %WetDryMix Wet/dry mix
        %   Specify the wet/dry mix ratio as a positive scalar. This value
        %   ranges from 0 to 1. For example, for a value of 0.6, the ratio
        %   will be 60% wet to 40% dry signal (Wet - Signal that has effect
        %   in it. Dry - Unaffected signal).  The default value of this
        %   property is 0.5.
        %         WetDryMix = 0.5
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
            'Mapping',{'enum','Test1','Test2','Test3','Dreamy','Wacky','Rewinder','DirtyTape'}),... % switch enumerator with different states
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
        end
        
        function calculateFilterCoeff(obj)
            % Calculate Butterworth filter coefficients 
            fs = getSampleRate(obj);
            if obj.preset.HPFON
                [obj.bHP, obj.aHP] = highPassCoeffs(obj.preset.Fc, obj.preset.Q, fs);
            end
            if obj.preset.LPFON
                [obj.bLP, obj.aLP] = lowPassCoeffs(obj.preset.Fc, obj.preset.Q, fs);
            end
        end
        
        function set.PresetChoice(obj, preset)
            obj.PresetChoice = preset;
            UpdatePreset(obj);
        end
        
        function UpdatePreset(obj)
            
            switch obj.PresetChoice
                case PresetEnum.Test1
                    obj.preset = Preset.Test1;
                case PresetEnum.Test2
                    obj.preset = Preset.Test2;
                case PresetEnum.Test3
                    obj.preset = Preset.Test3;
                case PresetEnum.Dreamy
                    obj.preset = Preset.Dreamy;
                case PresetEnum.Wacky
                    obj.preset = Preset.Wacky;
                case PresetEnum.Rewinder
                    obj.preset = Preset.Rewinder;
                case PresetEnum.DirtyTape
                    obj.preset = Preset.DirtyTape;
            end
            calculateFilterCoeff(obj);
        end
        
        %interpolation
        
        %switch case
        function addAdaptive(obj,x)
            switch obj.preset
                case Preset.Dreamy
                    %Extract audio features
                    E = sum(energyLevel(x(:,1)',1));
                    
                    %add additional feature extractions here
                    %C = centroid()
                    %IOID = 
                    
                    %Map raw feature data to ranges for the control
                    %parameters
                    obj.sQ = mapRange(10,obj.preset.sQ,1000,0,E);
                    disp(obj.sQ);
                case Preset.Reverse
                    %Extract audio features
                    E = sum(energyLevel(x(:,1)',1));
                    disp(E);
                    %add additional feature extractions here
                    %C = centroid()
                    %IOID = 
                    
                    %Map raw feature data to ranges for the control
                    %parameters
                    
            end
        end
   
       
        
        function [x, xd] = setEffect(obj, x)
            % Function that calculates effects
            if obj.preset.DelayON
                delayInSamples = obj.preset.Delay*obj.pSR;
                
                % Delay the input
                xd = obj.pFractionalDelay(delayInSamples, x);
                
                % Add effects to the delayed signal
                if obj.preset.VibratoON
                    % Input: signal, fs, modfreq, width, buffer,bufferIndex, sineBuffer
                    % Output: vibrato, buffer, bufferIndex, Sine wave
                    % pointer
                    [xd, obj.Buffer, obj.BufferIndex, obj.sPointer] = vibrato(xd, obj.pSR, obj.preset.vRate, obj.preset.vDepth, obj.Buffer, obj.BufferIndex, obj.sPointer);
                end
                if obj.preset.ReverseON
                    delayInSamples = obj.preset.Delay*obj.pSR;
                    [xd, obj.rBuffer, obj.rPointer] = reverse(xd, obj.rBuffer, delayInSamples, obj.rPointer);
                end
                if obj.preset.SaturationON
                    % function [y,zHP,zLP]=tube(x, gain, Q, dist, rh, rl, mix,zHP, zLP)
                    
                    [xd,~,~] = tube(xd, obj.preset.sGain, obj.preset.sQ,obj.preset.sDist,0,0,obj.preset.sMix,0,0);
                end
                
                if obj.preset.LPFON
                    [xd,obj.zLP] = filter(obj.bLP, obj.aLP, xd, obj.zLP);
                end
                
                if obj.preset.HPFON
                    [xd,obj.zHP] = filter(obj.bHP, obj.aHP, xd, obj.zHP);
                end
            else
                % Add the effects to the input signal
                xd = x;
                if obj.preset.VibratoON
                    % Input: signal, fs, modfreq, width, buffer,bufferIndex, sineBuffer
                    % Output: vibrato, buffer, bufferIndex, Sine wave
                    % pointer
                    [xd, obj.Buffer, obj.BufferIndex, obj.sPointer] = vibrato(xd, obj.pSR, obj.preset.vRate, obj.preset.vDepth, obj.Buffer, obj.BufferIndex, obj.sPointer);
                end
                if obj.preset.ReverseON
                    delayInSamples = obj.preset.Delay*obj.pSR;
                    [xd, obj.rBuffer, obj.rPointer] = reverse(xd, obj.rBuffer, delayInSamples, obj.rPointer);
                end
                if obj.preset.SaturationON
                    % function [y,zHP,zLP]=tube(x, gain, Q, dist, rh, rl, mix,zHP, zLP)

                    [xd,~,~] = tube(xd, obj.preset.sGain, obj.sQ,obj.preset.sDist,0,0,obj.preset.sMix,0,0);
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
            
            switch obj.Guitar
                case GuitarEnum.Connected
                    x(:,2) = x(:,1);
                case GuitarEnum.NotConnected
            end
            addAdaptive(obj,x)
            % calculate effect + filter
            [~, xd] = setEffect(obj, x);
            
            % Calculate output by adding wet and dry signal in appropriate
            % ratio
            mix = obj.preset.Mix;
            y = (1-mix)*x + (mix)*(obj.preset.Gain.*xd);
            
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
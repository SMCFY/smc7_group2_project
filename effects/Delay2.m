classdef Delay2 < audioPlugin
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
        %Delay Base delay (s)
        %   Specify the base delay for echo effect as positive scalar
        %   value in seconds. Base delay value must be in the range between
        %   0 and 1 seconds. The default value of this property is 0.5.
        Delay = 0.5
        
        %Gain Gain of delay branch
        %   Specify the gain value as a positive scalar. This value must be
        %   in the range between 0 and 1. The default value of this
        %   property is 0.5.
        Gain = 0.5
        % start position of switch. Can we toggled on in audioTestBench
        EffectType = EffectEnum.Nothing
        FilterType = FilterEnum.Nothing
        % Filter variables
        Fc = 20
        Q = sqrt(2)/2
        
        % Saturation
       % sAmount = 1
        sGain = 0.8
        sQ  = 1
        sDist = 3
        sRH = 0.99
        sRL =  0.6 
        sMix = 0.9
        
        Width = 6;
        Rate = 5;
        
        % Mono --> Stereo switch
        Guitar = GuitarEnum.NotConnected
        
    end
    
    properties (Dependent)
        %FeedbackLevel Feedback gain
        %   Specify the feedback gain value as a positive scalar. This
        %   value must range from 0 to 0.5. Setting FeedbackLevel to 0
        %   turns off the feedback. The default value of this property is
        %   0.35.
        FeedbackLevel = 0.35
        
    end
    
    properties
        %WetDryMix Wet/dry mix
        %   Specify the wet/dry mix ratio as a positive scalar. This value
        %   ranges from 0 to 1. For example, for a value of 0.6, the ratio
        %   will be 60% wet to 40% dry signal (Wet - Signal that has effect
        %   in it. Dry - Unaffected signal).  The default value of this
        %   property is 0.5.
        WetDryMix = 0.5
    end
    
    properties (Constant)
        % audioPluginInterface manages the number of input/output channels
        % and uses audioPluginParameter to generate plugin UI parameters.
        PluginInterface = audioPluginInterface(...
            'InputChannels',2,...
            'OutputChannels',2,...
            'PluginName','Multi-Modulation Delay Of Awesomeness',...
            'VendorName', '', ...
            'VendorVersion', '3.1.4', ...
            'UniqueId', '4pvz',...
            audioPluginParameter('Delay',...
            'DisplayName','Base delay','Label','s','Mapping',{'lin',0.001 1}),...
            audioPluginParameter('Gain',...
            'DisplayName','Gain','Label','','Mapping',{'lin',0 1}),...
            audioPluginParameter('FeedbackLevel',...
            'DisplayName','Feedback','Label','','Mapping',{'lin', 0 0.9}),...
            audioPluginParameter('WetDryMix',...
            'DisplayName','Wet/dry mix','Label','','Mapping',{'lin',0 1}),...
            audioPluginParameter('EffectType',...
            'DisplayName','Effect',...
            'Mapping',{'enum','Nothing','Vibrato', 'Reverse','Saturation'}),... % switch enumerator with different states
            audioPluginParameter('FilterType',...
            'DisplayName','Filter','Mapping',{'enum','Nothing','LowPass', 'HighPass'}),...
            audioPluginParameter('Fc',...
            'DisplayName','Fc','Label','Hz','Mapping',{'log',20 20000}),...
            audioPluginParameter('Q', ...
            'DisplayName',  'Q','Mapping', { 'log', 0.1, 200}),...
            audioPluginParameter('sGain', ...
            'DisplayName','Tube gain','Mapping', { 'lin', 0.1, 2}),...
            audioPluginParameter('sQ', ...
            'DisplayName','Tube Q','Mapping', { 'lin', 0.01, 10}),...
            audioPluginParameter('sDist', ...
            'DisplayName','Tube Distortion','Mapping', { 'lin', 0.01, 10}),...
            audioPluginParameter('sMix', ...
            'DisplayName','Tube Mix','Mapping', { 'lin', 0.001, 1}),...
            audioPluginParameter('Width', ...
            'DisplayName',  'Vibrato Depth','Mapping', { 'lin', 1, 20}),...
            audioPluginParameter('Rate', ...
            'DisplayName',  'Vibrato Rate','Mapping', { 'lin', 1, 20}),...
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
        
        % 
        sZHP = []
        sZLP = []
        % internal state used by LP and HP filter, all zeros the initial
        % state
        z = zeros(2)
        b = zeros(1,3)
        a = zeros(1,3)
    end
    
    methods
        % Constructor, called when initializing effect
        function obj = Delay2()
            fs = getSampleRate(obj);
            obj.pFractionalDelay = audioexample.DelayFilter( ...
                'FeedbackLevel', 0.35, ...
                'SampleRate', fs);
            obj.pSR = fs;
%             % Reverse
            obj.rBuffer = zeros(fs*2+1,2); % max delay time in samples
        end
        
        % set and get for audioexample.DelayFilter class
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
            obj.z = zeros(2);
%             obj.sZHP = zeros(1,2);
%             obj.sZLP = zeros(1,2);
            [obj.b, obj.a] = highPassCoeffs(obj.Fc, obj.Q, fs);
        end
        
        function set.Fc(obj, Fc)
            obj.Fc = Fc;
            calculateFilterCoeff(obj);
        end
        
        function set.Q(obj,Q)
            obj.Q = Q;
            calculateFilterCoeff(obj);
        end
        
        function calculateFilterCoeff(obj)
            fs = getSampleRate(obj);
            switch obj.FilterType
                case FilterEnum.HighPassFilter
                    [obj.b, obj.a] = highPassCoeffs(obj.Fc, obj.Q, fs);
                case FilterEnum.LowPassFilter
                    [obj.b, obj.a] = lowPassCoeffs(obj.Fc, obj.Q, fs);
            end
        end
        
        function [x, xd] = setEffect(obj, x, xd)
            % Switch to toggle on effects/filter on dry or wet signal
            switch obj.EffectType
                case EffectEnum.Vibrato
                    % Input: signal, fs, modfreq, width, buffer,bufferIndex, sineBuffer
                    % Output: vibrato, buffer, bufferIndex, Sine wave
                    % pointer
                    [xd, obj.Buffer, obj.BufferIndex, obj.sPointer] = vibrato(x, obj.pSR, obj.Rate, obj.Width, obj.Buffer, obj.BufferIndex, obj.sPointer);
                case EffectEnum.Reverse
                    delayInSamples = obj.Delay*obj.pSR;
                    [xd, obj.rBuffer, obj.rPointer] = reverse(x, obj.rBuffer, delayInSamples, obj.rPointer);
                case EffectEnum.Saturation
                    % function y=tube(x, gain, Q, dist, rh, rl, mix, zHP, zLP)
                    [xd, obj.sZHP, obj.sZLP] = tube(xd, obj.sGain, obj.sQ, obj.sDist, obj.sRH, obj.sRL, obj.sMix,obj.sZHP,obj.sZLP);
                case EffectEnum.Nothing
            end
            
            switch obj.FilterType
                case FilterEnum.HighPassFilter
                    [xd,obj.z] = filter(obj.b, obj.a, xd, obj.z);
                case FilterEnum.LowPassFilter
                    [xd,obj.z] = filter(obj.b, obj.a, xd, obj.z);
                case FilterEnum.Nothing
            end

        end
        
        function set.sGain(obj,Amount)
            obj.sGain = Amount;
        end
        function set.sQ(obj,Amount)
            obj.sQ = Amount;
        end
        function set.sDist(obj,Amount)
            obj.sDist = Amount;
        end
        function set.sMix(obj,Amount)
            obj.sMix = Amount;
        end
        function set.Width(obj, Width)
            obj.Width = Width;
        end
        
        function set.Rate(obj, Rate)
            obj.Rate = Rate;
        end
        
        % output function, gets called at buffer speed
        function y = process(obj, x)
            
            switch obj.Guitar
                case GuitarEnum.Connected
                    x(:,2) = x(:,1);
                case GuitarEnum.NotConnected
            end
            delayInSamples = obj.Delay*obj.pSR;
            
            % Delay the input
            xd = obj.pFractionalDelay(delayInSamples, x);
            
            % calculate effect + filter
            [~, xd] = setEffect(obj, x, xd);

            % Calculate output by adding wet and dry signal in appropriate
            % ratio
            mix = obj.WetDryMix;
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
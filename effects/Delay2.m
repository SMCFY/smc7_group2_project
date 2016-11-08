classdef Delay2 < audioPlugin
    
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
        Effect = 'Nothing'
        
        Fc = 20
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
            'PluginName','Echo',...
            'VendorName', '', ...
            'VendorVersion', '3.1.4', ...
            'UniqueId', '4pvz',...
            audioPluginParameter('Delay','DisplayName','Base delay','Label','s','Mapping',{'lin',0 1}),...
            audioPluginParameter('Gain','DisplayName','Gain','Label','','Mapping',{'lin',0 1}),...
            audioPluginParameter('FeedbackLevel','DisplayName','Feedback','Label','','Mapping',{'lin', 0 0.9}),...
            audioPluginParameter('WetDryMix','DisplayName','Wet/dry mix','Label','','Mapping',{'lin',0 1}),...
            audioPluginParameter('Effect',...
                'DisplayName','Effect',...
                'Mapping',{'enum','Nothing','Reverse', 'Reverb','HighPass Filter', 'LowPass Filter'}),... % switch enumerator with different states
             audioPluginParameter('Fc','DisplayName','Fc','Label','Hz','Mapping',{'log',20 20000}));
    end
    
    properties (Access = private)        
        %pFractionalDelay DelayFilter object for fractional delay with
        %linear interpolation
        pFractionalDelay
        
        %pSR Sample rate
        pSR
        
        rBuffer
        
        % internal state used by LP and HP filter, all zeros the initial
        % state
        z = zeros(2)
        b = zeros(1,3)
        a = zeros(1,3)
    end
    
    methods
        function obj = Delay2()
            fs = getSampleRate(obj);
            obj.pFractionalDelay = audioexample.DelayFilter( ...
                'FeedbackLevel', 0.35, ...
                'SampleRate', fs);
            obj.pSR = fs;
            obj.rBuffer = []; % filter buffer
        end
        % set.Effect is called every time a new effect is selected 
        function set.Effect(plugin, effect)
            plugin.Effect = effect;
        end
        
        function set.FeedbackLevel(obj, val)
            obj.pFractionalDelay.FeedbackLevel = val;
        end
        function val = get.FeedbackLevel(obj)
            val = obj.pFractionalDelay.FeedbackLevel;
        end
        % functions to be implemented
%         function grain = granular()
%         end

        
        function reset(obj)
            % Reset sample rate
            fs = getSampleRate(obj);
            obj.pSR = fs;
            
            % Reset delay
            obj.pFractionalDelay.SampleRate = fs;
            obj.rBuffer = [];
            reset(obj.pFractionalDelay);
            
            % initialize internal filter state
            obj.z = zeros(2);
          
            [obj.b, obj.a] = highPassCoeffs(obj.Fc, fs);
        end
        function set.Fc(obj, Fc)
            obj.Fc = Fc;
            fs = getSampleRate(obj);
            % Switch to decide which filter to use
            switch obj.Effect
                case 'HighPass Filter' 
                    [obj.b, obj.a] = highPassCoeffs(Fc, fs);
                case 'LowPass Filter'
                    [obj.b, obj.a] = lowPassCoeffs(Fc, fs);
            end
        end
        
        function y = process(obj, x)
            delayInSamples = obj.Delay*obj.pSR;
            
            % Delay the input
            xd = obj.pFractionalDelay(delayInSamples, x);
            
            % Switch to toggle on effects/filter on dry or wet signal  
            switch obj.Effect
                case 'Reverse'
                    [xd] = reverse(xd);
                case 'Reverb'
                    [x, obj.rBuffer] = reverb(x, obj.rBuffer);
                case 'HighPass Filter' 
                    [xd,obj.z] = filter(obj.b, obj.a, xd, obj.z);
                case 'LowPass Filter'
                    [xd,obj.z] = filter(obj.b, obj.a, xd, obj.z);
                case 'Nothing'
            end
            
            % Calculate output by adding wet and dry signal in appropriate
            % ratio
            mix = obj.WetDryMix;
            y = (1-mix)*x + (mix)*(obj.Gain.*xd);
        end
    end
end
% Filter calculations from RT audio white paper
% Butterworth high pass filter coefficients
function [b, a] = highPassCoeffs(Fc, Fs)
  w0 = 2*pi*Fc/Fs;
  alpha = sin(w0)/sqrt(2);
  cosw0 = cos(w0);
  norm = 1/(1+alpha);
  b = (1 + cosw0)*norm * [.5  -1  .5];
  a = [1  -2*cosw0*norm  (1 - alpha)*norm];
end

% Butterworth low pass filter coefficients
function [b, a] = lowPassCoeffs(Fc, Fs)
  w0 = 2*pi*Fc/Fs;
  alpha = sin(w0)/sqrt(2);
  cosw0 = cos(w0);
  norm = 1/(1+alpha);
  % calculate b & a coeff, still needs some tweaking
  b0 = (1 - cos(w0))/2; b1 = 1 - cos(w0); b2 = (1 - cos(w0))/2;
  b = [b0 b1 b2]; %(1 - cosw0)/2*norm * [.5  -1  .5];
  a0 =   1 + alpha; a1 =  -2*cos(w0); a2 =   1 - alpha;
  a = [a0 a1 a2]; %[1  -2*cosw0*norm  (1 - alpha)*norm];
end
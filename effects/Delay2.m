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
        
        Effect = 'Nothing'
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
                'Mapping',{'enum','Nothing','Reverse', 'Reverb','Centroid'}));
    end
    
    properties (Access = private)        
        %pFractionalDelay DelayFilter object for fractional delay with
        %linear interpolation
        pFractionalDelay
        
        %pSR Sample rate
        pSR
        
        rBuffer
    end
    
    methods
      
        function obj = Delay2()
            fs = getSampleRate(obj);
            obj.pFractionalDelay = audioexample.DelayFilter( ...
                'FeedbackLevel', 0.35, ...
                'SampleRate', fs);
            obj.pSR = fs;
            obj.rBuffer = [];
        end
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
        end
        
        function y = process(obj, x)
            delayInSamples = obj.Delay*obj.pSR;
            
            % Delay the input
            xd = obj.pFractionalDelay(delayInSamples, x);
            
            switch obj.Effect
                case 'Reverse'
                    [xd, obj.rBuffer] = reverse(xd, obj.rBuffer);
                case 'Reverb'
                    [xd, obj.rBuffer] = reverse(xd, obj.rBuffer);
                case 'Centroid' 
                case 'Nothing'
            end
            
            % Calculate output by adding wet and dry signal in appropriate
            % ratio
            mix = obj.WetDryMix;
            y = (1-mix)*x + (mix)*(obj.Gain.*xd);
        end
    end
end
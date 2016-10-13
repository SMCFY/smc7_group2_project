classdef Delay < audioPlugin
    properties
        DelayTime = 0.3; 
        Mix = 50;
    end
    properties (Constant)
        
        PluginInterface = audioPluginInterface(...
            'InputChannels',2,...
            'OutputChannels',2,...
            'PluginName','Delay',...
            'VendorName','',...
            'VendorVersion','1.0',...
            'UniqueId','utsg',...
            audioPluginParameter('DelayTime','DisplayName','Delay time','Label','sec','Mapping',{'lin' 0 1}),...
            audioPluginParameter('Mix','DisplayName','Dry/wet Mix','Label','%','Mapping',{'lin' 0 100})); 
    end
      %----------------------------------------------------------------------
    % Private properties
    %----------------------------------------------------------------------
    properties (Access = private, Hidden)
        % Maximum sample rate in most DAWs. Change this value if the
        % maximum sample rate is more than 192000.
        MaximumSampleRate = 192000;
        
        % Initial delay lines.
        DL1 = 0
        
        % Initial sample rate.
        SR = 0
       
        % Initial write and read index.
        WriteIndex1 = 0
        ReadIndex1 = 0
% %         WriteIndex2 = 0
% %         ReadIndex2 = 0
    end
    
    %----------------------------------------------------------------------
    % public methods
    %----------------------------------------------------------------------
    methods
        
        function Output = process(plugin, Input)
            % Calculating sample rate.
            SampleRate = plugin.getSampleRate;
            
            if(plugin.SR ~= SampleRate)
                plugin.SR = SampleRate;
                plugin.DL1 = zeros(plugin.MaximumSampleRate, 1, 'like', Input);
            end

            DryWet = plugin.Mix/100;
            
            % Compute the delay value in samples.
            DelayVector1 = cast(plugin.DelayTime*SampleRate,'like',Input);
            
            % Calling LinearVariableFractionalDelay which performs variable
            % fractional delay by linear interpolating between samples
             [Output1, plugin.WriteIndex1, plugin.ReadIndex1, plugin.DL1] = HelperLinearVariableFractionalDelay...
                 (Input,DelayVector1,plugin.DL1,plugin.WriteIndex1, plugin.ReadIndex1);
%             [Output2, plugin.WriteIndex2, plugin.ReadIndex2, plugin.DL1] = HelperLinearVariableFractionalDelay...
%                 (Input,DelayVector1,plugin.DL1,plugin.WriteIndex1, plugin.ReadIndex1);

            % Using DryWetMix value to adjust dry wet ratio.
            Output = (1-DryWet).*Input + (DryWet).*(Output1);
        end
    end
end
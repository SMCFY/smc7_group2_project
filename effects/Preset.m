classdef Preset < handle
 %   enumeration
        % Delay, Gain, Feedback, Mix, Fc, Q, vDepth, vRate, sGain, sQ, sDist, sMix,
        % DelayON, VibratoON, ReverseON, SaturationON, LPF, HPF
%         Test1(0.7, 1, 0.6, 0.7,... % Delay, Gain, Feedback, Mix,
%             5000, 1, 10, 5,...      % Fc, filter Q, vDepth, vRate,
%             0.8, 1, 1, 1,...        % sGain, sQ, sDist, sMix
%             1, 1, 1, 0, 0, 0)       % DelayON, VibratoON, ReverseON, SaturationON, LPFON, HPFON
%         
%         Test2(0.7, 1, 0.3, 0.4,...% Delay, Gain, Feedback, Mix,
%             500, 12, 10, 5,...      % Fc, filter Q, vDepth, vRate,
%             0.8, 1, 10, 1,...       % sGain, sQ, sDist, sMix
%             1, 0, 0, 1, 0, 0)       % DelayON, VibratoON, ReverseON, SaturationON, LPFON, HPFON
%         
%         Test3(0.7, 1, 0.3, 0.4,...% Delay, Gain, Feedback, Mix,
%             2000, 12, 12, 5,...      % Fc, filter Q, vDepth, vRate,
%             1, 1, 1, 0.5,...         % sGain, sQ, sDist, sMix
%             0, 1, 1, 1, 1, 1)        % DelayON, VibratoON, ReverseON, SaturationON, LPFON, HPFON
       
        % Presets for Leo 
%         Dreamy(0.3, 0.5, 0.5, 0.8,...% Delay, Gain, Feedback, Mix,
%             1500, 12, 9, 3,...      % Fc, filter Q, vDepth, vRate,
%             0.1, 0.1, 0.1, 0.2,...   % sGain, sQ, sDist, sMix
%             1, 1, 0, 0, 1, 0)        % DelayON, VibratoON, ReverseON, SaturationON, LPFON, HPFON
%         Wacky(0.015, 1, 0.5, 0.7,...% Delay, Gain, Feedback, Mix,
%             18000, 12, 10, 9,...      % Fc, filter Q, vDepth, vRate,
%             1, 1, 0.1, 0.5,...         % sGain, sQ, sDist, sMix
%             1, 1, 0, 0, 1, 0)        % DelayON, VibratoON, ReverseON, SaturationON, LPFON, HPFON
%         Rewinder(0.8, 1, 0.5, 0.5,...% Delay, Gain, Feedback, Mix,
%             4500, 20, 1, 1,...      % Fc, filter Q, vDepth, vRate,
%             1, 1, 1, 0.5,...         % sGain, sQ, sDist, sMix
%             0, 0, 1, 1, 1, 0)        % DelayON, VibratoON, ReverseON, SaturationON, LPFON, HPFON
%         DirtyTape(0.2, 1, 0.5, 0.7,...% Delay, Gain, Feedback, Mix,
%             1250, 12, 8, 3,...      % Fc, filter Q, vDepth, vRate,
%             0.8, 3, 2.5, 0.5,...         % sGain, sQ, sDist, sMix
%             1, 0, 0, 1, 1, 0)        % DelayON, VibratoON, ReverseON, SaturationON, LPFON, HPFON
   % end
    properties 
        Delay
        Gain
        Feedback
        Mix
        Fc
        Q
        vDepth
        vRate
        sGain
        sQ 
        sDist 
        sMix 
        DelayON
        VibratoON
        ReverseON
        SaturationON
        LPFON
        HPFON
        
    end
    methods
        function obj = Preset(delay, gain, feedback, mix, fc, q, vDepth, vRate, sGain, sQ, sDist, sMix, dOn, vOn, rOn, sOn, lpf, hpf)
            obj.Delay = delay;
            obj.Gain = gain;
            obj.Feedback = feedback;
            obj.Mix = mix;
            obj.Fc = fc;
            obj.Q = q;
            obj.vDepth = vDepth;
            obj.vRate = vRate;
            obj.sGain = sGain;
            obj.sQ = sQ;
            obj.sDist = sDist;
            obj.sMix = sMix;
            obj.DelayON = dOn;
            obj.VibratoON = vOn;
            obj.ReverseON = rOn;
            obj.SaturationON = sOn;
            obj.LPFON = lpf;
            obj.HPFON = hpf;
        end
    end
end
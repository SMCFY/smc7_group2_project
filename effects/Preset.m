classdef Preset < handle
    enumeration
        % Delay, Gain, Feedback, Mix, Fc, Q, vDepth, vRate, sAmount,
        % DelayON, VibratoON, ReverseON, SaturationON, LPF, HPF
        Dreamy(0.5, 1, 0.3, 0.8, 5000, 0.5, 10, 3, 1, 1, 1, 0, 0, 1, 0)
        
        Reverse(0.7, 1, 0.3, 0.4,...% Delay, Gain, Feedback, Mix,
            500, 12, 10, 3, 5,...  % Fc vDepth, vRate, sAmount
            1, 0, 1, 1, 1, 0)       % DelayON, VibratoON, ReverseON, SaturationON, LPFON, HPFON
    end
    properties
        Delay
        Gain
        Feedback
        Mix
        Fc
        Q
        vDepth
        vRate
        sAmount
        DelayON
        VibratoON
        ReverseON
        SaturationON
        LPFON
        HPFON
        
    end
    methods
        function obj = Preset(delay, gain, feedback, mix, fc, q, vDepth, vRate, sAmount, dOn, vOn, rOn, sOn, lpf, hpf)
            obj.Delay = delay;
            obj.Gain = gain;
            obj.Feedback = feedback;
            obj.Mix = mix;
            obj.Fc = fc;
            obj.Q = q;
            obj.vDepth = vDepth;
            obj.vRate = vRate;
            obj.sAmount = sAmount;
            obj.DelayON = dOn;
            obj.VibratoON = vOn;
            obj.ReverseON = rOn;
            obj.SaturationON = sOn;
            obj.LPFON = lpf;
            obj.HPFON = hpf;
        end
    end
end
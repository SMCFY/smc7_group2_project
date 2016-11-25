classdef Mapping < handle
    enumeration
        Mapping1(0.5,6,5000,0.8)
        Mapping2(0.2,1,20000,0.3)
        Mapping3(0.2,6,5000,0.8)
    end
    properties
        Delay
        vRate
        LPCutoff
        Mix
    end
    methods
        function obj = Mapping(different,types,of,parameters)
            obj.Delay = different;
            obj.vRate = types;
            obj.LPCutoff = of;
            obj.Mix = parameters;
        end
    end
end
classdef Vibrato < handle
    properties
        rate
        width
        waveform
    end
    properties (Access=private)
        delay
        fs
        Buffer = zeros(192001,2);
        BufferIndex = 1;
        phase = 0;
        freq
        amplitude = 0.9;
    end
    
    methods
        function obj = Vibrato(r_, w_, waveform, fs_)
            obj.rate = r_;
            obj.width = w_;
            obj.fs = fs_;
            
            obj.delay = round(obj.width * obj.fs);
            obj.freq = obj.rate / obj.fs;
            obj.waveform = waveform;
        end
        function setRate(obj,rate)
            obj.rate = rate;
            obj.freq = rate;
        end
        function setWidth(obj,width)
            obj.width = width;
            obj.delay = round(width * obj.fs);
        end
        function setWaveform(obj,waveform)
            obj.waveform = waveform;
        end
        function out = process(obj, x)
            y = zeros(size(x));
            writeIndex = obj.BufferIndex;
            
            delta = (obj.freq * 2 * pi) / obj.fs;
            
            for i = 1:size(x,1)
                obj.Buffer(writeIndex,:) = x(i,:); % Store buffer
                
                osc = 0;
                
                switch(obj.waveform)
                    case 'Sin'
                        osc = obj.amplitude*sin(obj.phase);
                    case 'Sqr'
                        if obj.phase < pi
                            osc = obj.amplitude;
                        else
                            osc = -obj.amplitude;
                        end
                    case 'Saw'
                        osc = obj.amplitude - (obj.amplitude / pi * obj.phase);
                    case 'Tri'
                        if obj.phase < pi
                            osc = -obj.amplitude + (2 * obj.amplitude / pi)  * obj.phase;
                        else
                            osc = 3 * obj.amplitude - (2 * obj.amplitude / pi)  * obj.phase;
                        end                      
                end
                
                obj.phase = obj.phase + delta;
                
                if obj.phase > 2 * pi
                    obj.phase = obj.phase - 2 * pi;
                end
                
                tap = 1 + obj.delay + obj.delay * osc;
                
                n = floor(tap);
                frac = tap - n;
                readIndex = floor(writeIndex - n);
                
                if readIndex <= 0
                    readIndex = readIndex + 192001;
                end
                
                if readIndex == 1
                    y(i,:) = frac*obj.Buffer(192001) + (1-frac)*obj.Buffer(readIndex);
                else
                    y(i,:) = frac*obj.Buffer(readIndex - 1) + (1-frac)*obj.Buffer(readIndex);
                end
                
                writeIndex = writeIndex + 1;
                if writeIndex > 192001
                    writeIndex =  1;
                end
            end
            obj.BufferIndex = writeIndex;
            out = y;
        end
        function reset(obj, fs)
            obj.fs = fs;
            obj.BufferIndex = 1;
            obj.Buffer = zeros(192001,2);
            obj.phase = 0; 
        end        
    end
end
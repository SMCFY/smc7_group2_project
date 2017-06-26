classdef FeatureExtraction < handle 
    %Collection of feature extraction algorithms
    %   Detailed explanation goes here
    
    properties (Access = private)
        Fs
        hannWin = zeros(1,4096*2)
        fftBuffer = zeros(1,4096*2)
        
         % Pitch 
        Pitch = 0;
        pitchCount = 0;
        pitchBufferSize = 20;
        pitchBuffer = [];
        
    end
    
    methods
        function obj = FeatureExtraction(Fs)
            obj.Fs = Fs;
        end
        
        % resets internal states of buffers
        function reset(obj, fs)
            % Reset sample rate
           
            obj.pSR = fs;            
            obj.FFTBuffer = zeros(1,4096*2);
            % --------------
            % Pitch 
            obj.Pitch = 0;
        end
        function C = centroid(x,fs)
            %SPECTRAL CENTROID
            %  calculates the spectral centroid
            %
            % ARGUMENTS:
            %   x - input signal
            % 	fs - sampling frequency
            
            M = length(x);
            ham = .54 - .46*cos(2*pi*(0:M-1)'/(M-1));
            window = x(1,:).*ham'; % create a hamming window for the signal
            X = fft(window); % fast fourier transform
            X_mag = abs(X); % magnitude spectrum
            X_mag = X_mag(1:round(length(X_mag)/2)); % cropping the negative region
            if max(X_mag) > 0.5 % minimum threshold for calculation
                X_mag = X_mag/max(X_mag); % normalize spectrum
                w = ((fs/2)/length(X_mag))*[0:length(X_mag)-1]; % bins in frequencies
                C = X_mag * w'/sum(X_mag); % SC
                C = C/(fs/2);
            else
                C = 0;
            end
            
        end
        function E = energyLevel(x,A)
            
            %code based on work by
            %   Author: Nabin Sharma
            %   Date: 2009/03/15
            
            % generate the window
            %ham = hamming(length(x));
            M = length(x);
            ham = .54 - .46*cos(2*pi*(0:M-1)'/(M-1));
            window = A.*ham';
            
            % enery calculation
            x2 = x.^2;
            E = real(sum(wconv(x2,window,length(x)))/length(x));
            
        end
        function y = wconv( x, A, L )
            %code based on work by
            %   Author: Nabin Sharma
            %   Date: 2009/03/15
            % generate the window
            M = length(x);
            ham = .54 - .46*cos(2*pi*(0:M-1)'/(M-1));
            window = A.*ham';
            
            % perform the convolution using FFT
            NFFT = 2^(nextpow2(length(x)+L));
            X = fft(x,NFFT); W = fft(window,NFFT);
            Y = X.*W;
            y = ifft(Y,NFFT);
        end
        function freq = pitch_detector(x,fs)
            % PITCH_DETECTOR:  Michael and Leo's pitch detection algorithm
            %
            %   INPUT:         signal: a segment of the signal that is used for
            %                          calculating its pitch
            %                  fs:     sampling rate of the signal
            %
            %   OUTPUT:        freq:   the frequency of the calculated pitch in Hz
            
            signal = x(:,2); % right channel only
            
            winLength = min(floor(fs/2),length(signal)); % window length is no more than 0.5 seconds long
            %hanWin = hann(winLength).*signal(1:winLength); % hanning window
            hanWin = .5*(1 - cos(2*pi*(1:winLength)'/(winLength+1)));
            hanWin = hanWin.*signal(1:winLength);
            fftsize = 2^16;
            
            fty = fft(hanWin,fftsize); % fft of hann window, + transform length in powers of 2
            x = abs(fty); % provides magnitude
            x = x(1:length(x)/2); % halfing the magnitude spectrum to get frequencies
            % ranging from 0 to the nyquist rate (half the sample rate, pi)
            
            x = x'; % turn x into a row vector
            
            down_sample2 = [x(1:2:end) zeros(1,length(x)/2)]; % downsample (factor of 2)
            % add zeros to the end so that it is same length as original
            
            down_sample3 = x(1:3:end); % downsample (factor of 3)
            down_sample3 = [down_sample3 zeros(1,length(x)-length(down_sample3))]; % work-around
            % of non-integer issue
            
            down_sample4 = x(1:4:end); % downsample (factor of 4)
            down_sample4 = [down_sample4 zeros(1,length(x)-length(down_sample4))]; % work-around
            % of non-integer issue
            
            mult = x.*down_sample2.*down_sample3.*down_sample4; % multiply original signal with the
                      
            [max_freq, freq] = max(mult);
            
            freq = freq*((fs/2)/(fftsize/2));
        end
        
        
    end
    
end


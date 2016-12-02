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
  % various down-sampled versions
  % mutltiplied together to increase the fundamental frequency and
  % attenuate the higher harmonics
  

  %% the following plots were used for testing purposes

  %% plot the fundamental frequency
  %plot([1:(length(x)/8)]*((fs/2)/(fftsize/2)),mult(1:(length(mult)/8)));
  %title('fundamental frequency')
  %figure
  %plot([1:length(x)]*((fs/2)/(fftsize/2)),x) % original 
  %title('original spectrum of the signal')
  
  %% plot frequencies in the range of 0 to an eighth of the sample rate
  %xlim([0 floor(fs/8)]);
  % frequencies are plotted in increments of 500 Hz
  %set(gca,'XTick',0:500:floor(fs/8));


  [max_freq freq] = max(mult);

  freq = freq*((fs/2)/(fftsize/2));
end

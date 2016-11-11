% Michael and Leo's pitch detection algorithm
%
% NOTE: This detects only one note
%       playing for 0.5 seconds.
%       Currently testing stereo sound files.

clear all; clc
[y fs] = audioread('../sound/pianoA440.wav'); % read a piano note
                                     % playing at 440 Hz

%y = (y(:,1)+y(:,2))/2; % TODO  stereo to mono doesn't quite work
y = y(:,2); % right channel only

winLength = fs/2; % window length is 0.5 seconds long
hanWin = hann(winLength).*y(1:winLength); % hanning window
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

% plot the fundamental frequency
plot([1:(length(x)/4)]*((fs/2)/(fftsize/2)),mult(1:(length(mult)/4)));
%plot([1:length(x)]*((fs/2)/(fftsize/2)),x) % original 

% plot frequencies in the range of 0 to an eighth of the sample rate
xlim([0 floor(fs/8)]);
% frequencies are plotted in increments of 500 Hz
set(gca,'XTick',0:500:floor(fs/8));

% play the 440 Hz piano tone
soundsc(y,fs);

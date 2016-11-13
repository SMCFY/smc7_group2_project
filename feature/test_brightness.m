function [C f0 fc f0AC] = test_brightness(audiofile)
  % TEST_BRIGHTNESS: A test function to return values
  %                  related to brightness
  % 
  % INPUT:           audiofile: The name of an audio file
  %                             inputed as a string value
  % 
  % OUTPUT:          C:         centroid value of audio signal
  %                  f0:        fundamental frequency of the signal in Hz
  %                  fc:        centroid value converted to a frequency
  %                             value in Hz
  %                  f0AC:      The adjusted centroid, which is the ratio
  %                             of the centroid to the fundamental frequency

  L = 5*2^10; % default length of the signal
  [signal,fs] = audioread(audiofile);
  L = min(length(signal),L); % signal may be smaller than the default length
  x = signal(1:L);
  C = centroid(x);
  fc = C*(fs/2)/pi;
  f0 = pitch_detector(signal,fs);
  f0AC = fc/f0;
end

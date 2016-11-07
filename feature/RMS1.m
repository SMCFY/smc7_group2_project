clear all;clc

% User Data
FS = 44100

[DAFx_in, FS] = audioread('flute.wav');
hop = 256; % hop size between two FFTs
WLen = 1024; % length of the windows
w = hanning(WLen);

% Initialisations 
WLen2 = WLen/2;
normW = norm(w,2);
pft = 1;
lf = floor((length(DAFx_in) - WLen)/hop);
feature_rms = zeros(lf,1);
tic 

pin = 0;
pend = length(DAFx_in) - WLen;

while pin<pend
    grain = DAFx_in(pin+1:pin+WLen).* w; 
    feature_rms(pft) = norm(grain,2)/normW;
    pft = pft+1;
    pin = pin+hop;
end

toc
subplot(2,2,1); plot(DAFX_in); axis([1 pend -1 1])
subplot(2,2,2); plot(feature_rms); axis([1 lf -1 1])
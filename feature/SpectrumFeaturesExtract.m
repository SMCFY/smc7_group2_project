function [ LFcontent, midBassContent, midContent, upperMidContent, highContent, spectralCentroid, spectralSpread, spectralSkewness, spectralKurtosis, dBMeanLevel, dBPeakLevel, peakFreq ] = SpectrumFeaturesExtract( audioNumber )
% SpectrumFeaturesExtract computes the power spectral density of the sound,
% using PWELCH function, and then extracts from it two useful features,
% LFcontent which is the low frenquency (f < 80 Hz) content (the percentage of low
% frequencies for the whole song) and spectralCentroid which is the bary
% center of the spectrum (in Hz). It returns also the mean frequency value of the
% overall sound (in dB). dBPeakLevel is the pick level (in dB) and peakFreq
% is the frequency at which the pick occurs.

    global audio;
    audio = getGlobalAudio;
    A = audio(audioNumber);
    samp = A.mono_samples_norm;
    FS = A.sample_rate;
    
    % PSD using PWELCH. pxx is the onesided PSD values, and f is the frequency
    % vector. f spans the interval [0,fs/2]
    [pxx,f] = pwelch(samp,[],[],4*FS,FS); % avec nfft=4*FS : nombre de points DFT - précision 321 points pour les LFs
                                          % window = 50% overlap
    
%     [pxx1,f1] = periodogram(samp,[],4*FS,FS);
    
    index20 = find(f>=20, 1 ); % low limit
    index80 = find(f>=80, 1 ); % bass
    index400 = find(f>=400, 1 ); % mid bass
    index2600 = find(f>=2600, 1 ); % mid
    index5200 = find(f>=5200, 1 ); % upper mid
    index20000 = find(f>=20000, 1 ); % high limit
    
    % spectrum of audible range
    pxx = pxx(index20:index20000);
%     pxx1 = pxx1(index20:index20000);
    
    % mean
    dBMeanLevel = 10*log10(abs(mean(pxx)));
    
    % spectral centroid
    spectralCentroid = sum(pxx.*f(index20:index20000)) / sum(pxx);
    %spectralCentroid1 = sum(pxx1.*f(index20:index20000)) / sum(pxx1);
    % spectral spread = variance relative to spectral centroid
    spectralSpread = sum((pxx.*(f(index20:index20000)-spectralCentroid)).^2) / sum(pxx);
    % spectral skewness
    sigma = sqrt(spectralSpread); % standard deviation relative to spectral centroid
    thirdMoment = sum((pxx.*(f(index20:index20000)-spectralCentroid)).^3) / sum(pxx);
    spectralSkewness = thirdMoment/sigma^3;
    % spectral kurtosis
    fourthMoment = sum((pxx.*(f(index20:index20000)-spectralCentroid)).^4) / sum(pxx);
    spectralKurtosis = fourthMoment/sigma^4;
    

    lowFreqSpectrum = pxx(1:index80);
    midBassSpectrum = pxx(index80+1:index400);
    midSpectrum = pxx(index400+1:index2600);
    upperMidSpectrum = pxx(index2600+1:index5200);
    highSpectrum = pxx(index5200+1:end);
     
%     lowFreqSpectrum1 = pxx1(1:index80);
    
    % LF energy in percent
    LFcontent = 100 * (sum(lowFreqSpectrum) / sum(pxx));
    midBassContent = 100 * (sum(midBassSpectrum) / sum(pxx));
    midContent = 100 * (sum(midSpectrum) / sum(pxx));
    upperMidContent = 100 * (sum(upperMidSpectrum) / sum(pxx));
    highContent = 100 * (sum(highSpectrum) / sum(pxx));
    
%     LFcontent1 = 100 * (sum(lowFreqSpectrum1) / sum(pxx1));
    
    % Peak level and peak freq
    [Max, IndexMax] = max(pxx);
    dBPeakLevel = 10*log10(abs(Max));
    peakFreq = f(IndexMax);
    
%     [Max1, IndexMax1] = max(pxx1);
%     dBPeakLevel1 = 10*log10(abs(Max1));
%     peakFreq1 = f(IndexMax1);
    
end


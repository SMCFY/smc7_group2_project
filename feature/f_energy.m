function E = f_energy(x)
%%%% THIS could be an alternative to the energyLevel.m function. This is a
%%%% simpler version. I don't know which one is more usable
%Calculate the energy of an audio frame

%  code based on:
% (c) 2014 T. Giannakopoulos, A. Pikrakis

E = (1/(length(x))) * sum(abs(x.^2));
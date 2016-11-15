function [ s,zf ] = cFilter(s, g, Mcomb, z)
% Comb filter
%   1 / (1-gz^-M)
    b = 1;
    a = [1, zeros(1,Mcomb-1) -g];
    
    [sf,zf] = filter(b,a,s,z); % comb filter
%   One pole LPF, z + 1 / z, 
    a = 1;
    b = [1 1];
    [s,z] = filter(b,a,sf,z);
    zf = z + zf;
    
end


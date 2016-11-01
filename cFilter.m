function [ s ] = cFilter(s, g, Mcomb)
% Comb filter
%   1 / (1-gz^-M)
    b = 1;
    a = [1, zeros(1,Mcomb-1) -g];
    s = filter(b,a,s); % comb filter
%   One pole LPF, z + 1 / z, 
    a = 1;
    b = [1 1];
    s = filter(b,a,s);
    
end


function [y, zHP, zLP]=tube(x, gain, Q, dist, rh, rl, mix, zHP,zLP)
% function y=tube(x, gain, Q, dist, rh, rl, mix)
% Author: Bendiksen, Dutilleux, Zölzer
% DAFX, p. 123

% y=tube(x, gain, Q, dist, rh, rl, mix)
% "Tube distortion" simulation, asymmetrical function 
% x - input
% gain - the amount of distortion, >0->
% Q - work point. Controls the linearity of the transfer function for low input levels, 
% more negative=more linear 
% dist - controls the distortion's character, a higher number gives
% a harder distortion, >0
% rh - abs(rh)<1, but close to 1. Placement of poles in the HP filter
% which removes the DC component 
% rl - 0 < rl 1. The pole placement in the LP filter used to simulate capacitances 
% in a tube amplifier  
% mix - mix of original and distorted sound, 1=only distorted
y = zeros(size(x));
x = x(:,1);
q=x*gain/max(abs(x));        % Normalization
if Q==0
    z=q./(1-exp(-dist*q));   % Test because of the transfer
    for i=1:length(q)        % function's 0/0 value in Q
        if q(i)==Q
            z(i,:)=1/dist;
        end;
    end;
else
    z=(q-Q)./(1-exp(-dist*(q-Q)))+Q/(1-exp(dist*Q));
    for i=1:length(q)
        if q(i)==Q                         % Test because of the transfer
            z(i,:)=1/dist+Q/(1-exp(dist*Q)); % function's 0/0 value in Q
        end;
    end;
end;
y(:,1)=mix*z*max(abs(x))/max(abs(z))+(1-mix)*x; 
y(:,1)=y(:,1)*max(abs(x))/max(abs(y(:,1)));
y(:,2)=y(:,1);
%y(:,2)=y*max(abs(x))/max(abs(y));
%[y1, zHP]=filter([1 -2 1],[1 -2*rh rh^2],y, zHP);   % HP Filter
%[y, zLP]=filter([1-rl],[1 -rl],y1, zLP);            % LP Filter



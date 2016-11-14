function [delay count prev_centroid curr_centroid delta] = interpolator(delay,signal,prev_centroid,curr_centroid,count,delta)
% INTERPOLATOR calculates the difference between the current
%              and the previous centroid value, if positive, then
%              the interpolator will return a positive change in the delay,
%              if negative, it will return a negative change in the delay,
%              else there will be zero change 
%
%   INPUT:     delay:         the current amount of delay in the signal, from 0 to 1
%              signal:        a segment of the signal that is used for calulating the centroid
%              prev_centroid: the previous centroid value
%              curr_centroid: the current centroid value
%              count:         a counter variable to keep track of the number of passes 
%                             through the signal buffer
%              delta:         the amount that the delay changes by with each pass through
%                             the signal buffer (currently set to 0.05)
%
%   OUTPUT:    delay:         the newly calculated delay in the signal, from 0 to 1
%              count:         the updated counter variable, adding 1 each time 
%                             interpolator is called
%              prev_centroid: the previous centroid is updated with the current centroid value
%              curr_centroid: the current centroid is updated with the new centroid value
%              delta:         the newly calculated change in the delay

  % calculate the current and previous centroid value
  prev_centroid = curr_centroid;
  curr_centroid = centroid(signal');

  if (prev_centroid == -1)
    % previous and current centroid are the same the first time through
    prev_centroid = curr_centroid;
  end

  % a new delta value will be calculated
  % for every five passes through the buffer
  if (mod(count,5)==0)
    centroid_change = curr_centroid - prev_centroid;
    % if the new centroid has a positive change
    % then assign a positive change in delta
    if (centroid_change>0)
      delta = 0.05;
    % if the new centroid has a negative change
    % then assign a negative change in delta
    elseif (centroid_change<0)
      delta = -0.05;
    else
    % otherwise, there is no change in delta
      delta = 0;
    end
    % change the delay by the amount of change in delta
    delay = delay + delta;
  else
    % the change in delay will be constant until a
    % new delta value is calculated
    delay = delay + delta;
  end

  count = count + 1;
  if (count > 10000) % avoid overflow
    count = 0;
  end 

  % set a min and max threshold value for the new delay
  if (delay<0)
    delay = 0;
  elseif (delay>1)
    delay = 1;
  end
end

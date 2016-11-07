function out = reverb(x)
            Mcomb = [511,331,551,667, 401, 731];
            gComb = 0.9;
            g = 0.7;

            s = x;

            s = cFilter(s,gComb,Mcomb(1)) + cFilter(s,gComb,Mcomb(2)) ...
                + cFilter(s,gComb,Mcomb(3)) + cFilter(s,gComb,Mcomb(4)) ...
                + cFilter(s,gComb,Mcomb(5)) +  cFilter(s,gComb,Mcomb(6));
            
            Mall = 531;

            s = allpassFilter(x,g, Mall);
           
            out = x*0.5 + s*0.5;
        end
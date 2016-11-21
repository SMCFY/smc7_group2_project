function [out,z] = reverb(x, z)
    %Mcomb = [511,331,551,667, 401, 731];
    %gComb = 0.9;
    g = 0.7;

    s = x;

    %[s1,z1] = cFilter(s,gComb,Mcomb(1),z);
    %[s2,z2] = cFilter(s,gComb,Mcomb(2),z);
    %[s3,z3] = cFilter(s,gComb,Mcomb(3),z);
    %[s4,z4] = cFilter(s,gComb,Mcomb(4),z);
    %[s5,z5] = cFilter(s,gComb,Mcomb(5),z);
    %[s6,z6] = cFilter(s,gComb,Mcomb(6),z);

    %s = s1 + s2 + s3 +s4 +s5 +s6;
    %Mall = 531;
    %z = z1 + z2 + z3 + z4 + z5 + z6;
    [out, z] = allpassFilter(s,g, 2531,z);

   % out = x*0.5 + s*0.5;
end
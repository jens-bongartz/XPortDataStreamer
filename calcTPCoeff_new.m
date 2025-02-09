# Koeffizientenberechnung von shepazu.github.io/Audio-EQ-Cookbook/audio-eq-cookbook.html
function [nr_coeff re_coeff]= calcTPCoeff(fs,f0)
   w0 = 2*pi*(f0/fs);
   Q = 1/sqrt(2);
   alpha = sin(w0)/(2*Q);
   b0 = (1-cos(w0))/2;
   b1 = 1-cos(w0);
   b2 = b0;
   a0 = 1 + alpha;
   a1 = (-2)*cos(w0);
   a2 = 1 - alpha;
   nr_coeff = [(b0/a0) (b1/a0) (b2/a0)];
   re_coeff = [1 (a1/a0) (a2/a0)];
endfunction


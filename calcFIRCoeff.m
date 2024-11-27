# Funktion zur Berechnung der Koeffizienten eines FIR-Bandpass-Filters
# fa >> Abtastfrequenz  df >> Frequenzaufloesung  N = fa / df
function coeff = calcFIRCoeff(fa,df,f1,f2)
   N    = round(fa / df);
   N_f1 = round(f1 / df);
   N_f2 = round(f2 / df);
   H = zeros(N,1);
   H(N_f1+1:N_f2+1,1) = 1;
   H(N-N_f2:N-N_f1,1) = 1;
   coeff = fftshift(real(ifft(H)));
endfunction


function [b, a] = bessel_biquad(N, Wn, type, fs)
  % bessel_biquad - Erstellt einen digitalen Biquad-Filter mit Bessel-Charakteristik
  % Ähnlich wie butter(), aber mit Bessel-Design für minimale Phasenverzerrung.
  %
  % Inputs:
  %   N    - Filterordnung (z.B. 2 für einen Biquad)
  %   Wn   - Grenzfrequenz in Hz (nicht normiert!)
  %   type - "low" für Tiefpass, "high" für Hochpass
  %   fs   - Abtastrate in Hz
  %
  % Outputs:
  %   b, a - Numerator- und Denominator-Koeffizienten des digitalen IIR-Biquads
  %
  % Beispiel:
  %   [b, a] = bessel_biquad(2, 10, "low", 200);
  %   y = filter(b, a, x);
  
  % 1. Analoge Grenzfrequenz umrechnen (Bessel nutzt radiale Frequenz!)
  Wn_analog = 2 * pi * Wn;  

  % 2. Analogen Bessel-Filter berechnen
  [b_analog, a_analog] = besself(N, Wn_analog);

  % 3. Digitalisierung mit bilinear-Z-Transformation
  [b, a] = bilinear(b_analog, a_analog, fs);

  % 4. Falls Hochpass gewünscht, Frequenztransformation anwenden
  if strcmp(type, "high")
    [b, a] = lp2hp(b, a, fs);
  elseif ~strcmp(type, "low")
    error("Nur 'low' oder 'high' als Filtertyp erlaubt!");
  endif
endfunction

% Zusatzfunktion für Tiefpass → Hochpass Umwandlung
function [b_hp, a_hp] = lp2hp(b_lp, a_lp, fs)
  % Konvertiert einen Tiefpass (b_lp, a_lp) in einen Hochpass-Filter
  % fs ist die Sampling-Frequenz
  [z, p, k] = tf2zp(b_lp, a_lp);  % In Nullstellen-Polstellen-Form umwandeln
  [z, p] = bilinear(-z, -p, fs);  % Frequenztransformation
  [b_hp, a_hp] = zp2tf(z, p, k);  % Zurück in Koeffizientenform
endfunction

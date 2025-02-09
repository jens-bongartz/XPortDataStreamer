function realtime_ecg_processing(ecg_signal, timestamps)
  % Echtzeit-EKG-Verarbeitung mit R-Zacken-Erkennung, adaptivem Mittelwertfilter und BPM-Berechnung
  
  % Parameter
  fs = 200; % Abtastrate in Hz
  window_size = round(0.15 * fs); % Gleitender Mittelwert über 150 ms
  inhibit_time = round(0.1 * fs); % Filteraussetzung für 100 ms nach R-Zacke
  max_window_size = round(2 * fs); % Fenstergröße für das iterative Maximum über die letzten 2 Sekunden
  
  % Initialisierung
  buffer = zeros(window_size, 1);
  buffer_index = 1;
  sum_val = 0;
  filter_disable = false;
  inhibit_counter = 0;
  last_r_peak_time = 0;
  bpm_values = [];
  max_buffer = zeros(max_window_size, 1);
  max_index = 1;
  
  % Ergebnisarrays
  filtered_signal = zeros(size(ecg_signal));
  detected_r_peaks = zeros(size(ecg_signal));
  bpm_time_series = zeros(size(ecg_signal));
  
  for i = 1:length(ecg_signal)
      sample = ecg_signal(i);
      timestamp = timestamps(i);
      
      % Dynamische Berechnung des Schwellenwerts über die letzten 2 Sekunden
      max_buffer(max_index) = sample;
      max_index = mod(max_index, max_window_size) + 1;
      dynamic_threshold = 0.6 * max(max_buffer); % Adaptives Maximum über die letzten 2 Sekunden
      
      % R-Zacken-Erkennung
      if sample > dynamic_threshold && (timestamp - last_r_peak_time) > 0.3 % Mindestens 300ms Abstand
          detected_r_peaks(i) = 1;
          last_r_peak_time = timestamp;
          
          % BPM-Berechnung
          if last_r_peak_time > 0
              rr_interval = timestamp - last_r_peak_time; % RR-Intervall in Sekunden
              bpm = 60 / rr_interval;
              bpm_values = [bpm_values, bpm];
              bpm_time_series(i) = bpm;
          end
          
          % Mittelwertfilter temporär deaktivieren
          filter_disable = true;
          inhibit_counter = inhibit_time;
      end
      
      % Timer für die Inhibit-Phase
      if filter_disable && inhibit_counter > 0
          inhibit_counter = inhibit_counter - 1;
      else
          filter_disable = false;
      end
      
      % Adaptive Mittelwertfilterung
      if filter_disable
          filtered_sample = sample; % Kein Filter während Inhibit-Phase
      else
          sum_val = sum_val - buffer(buffer_index) + sample;
          buffer(buffer_index) = sample;
          filtered_sample = sum_val / window_size;
          buffer_index = mod(buffer_index, window_size) + 1;
      end
      
      filtered_signal(i) = filtered_sample;
  end
  
  % Plot der Ergebnisse
  figure;
  subplot(3,1,1);
  plot(timestamps, ecg_signal, 'b'); hold on;
  plot(timestamps(detected_r_peaks==1), ecg_signal(detected_r_peaks==1), 'ro');
  title('EKG-Signal mit R-Zacken');
  xlabel('Zeit (s)'); ylabel('Amplitude');
  
  subplot(3,1,2);
  plot(timestamps, filtered_signal, 'g');
  title('Gefiltertes Signal mit adaptivem Mittelwertfilter');
  xlabel('Zeit (s)'); ylabel('Amplitude');
  
  subplot(3,1,3);
  plot(timestamps, bpm_time_series, 'm');
  title('Herzfrequenz (BPM)');
  xlabel('Zeit (s)'); ylabel('BPM');
end

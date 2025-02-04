#          XPortDataStreamer V 1.1  (XPDS)
#  (c) Jens Bongartz, 2025, Hochschule Koblenz
#                Stand: 04.02.2025
#  ================================================
pkg load instrument-control;
clear all; clc;

#inputDevice = "serial";
inputDevice = "udp";

# obj = dataStreamClass(name,plcolor,dt,plotwidth,plot,filter)
# createFilter(f_abtast,f_HP,f_NO,f_TP)
dataStream(1) = dataStreamClass("FBT","red",800,1,1); # externe Klasse
#dataStream(2) = dataStreamClass("FBT","blue",800,1,1); # externe Klasse
# createIIRFilter(f_abtast,f_HP,f_NO,f_TP)
dataStream(1).createIIRFilter(200,2,50,40);
#dataStream(2).createIIRFilter(200,4,50,20);
# createFIRFilter(f_abtast,df,f1,f2)
dataStream(1).createFIRFilter(200,2,1,40);
#dataStream(2).createFIRFilter(200,2,1,45);

dataStream(1).peakDetector  = 1;
dataStream(1).evalWindow    = 200;

if strcmp(inputDevice,"serial")
   baudrate = 115200;
   inputPort = serialPortClass(baudrate);
endif
if strcmp(inputDevice,"udp")
   inputPort = udpPortClass();                   # externe Klasse
endif

inputPort.createSelector(dataStream);         # >> inputPort.streamSelector
inputPort.createRegEx(dataStream);            # >> inputPort.regex_pattern

# Globale Variablen zur Programmsteuerung
# fuer Test mit FIR-Filter sind alle IIR-Filter zunaechst deaktiviert
global HP_filtered = 1 NO_filtered = 1 TP_filtered = 1 DQ_filtered = 0 DQ2_filtered = 0;
# und FIR-Filter ist aktiviert
global FIR_filtered = 0;

global quit_prg = 0 clear_data = 0 save_data = 0 rec_data = 1;

# Einstellwerte fuer die Programm-Performance [Sekunden]
Bench_Time      = 2;       # measurment of load every 2 seconds
Plot_Time       = 0.1;
SerialPort_Time = 0.04;   # alle 40ms (25 Hz) werden Daten empfangen
Pause_Time      = 0.05;

# Der weitere Teil wird nur ausgefuehrt, wenn serielle Schnittstelle gefunden wurde
if !isempty(inputPort)
  # Graphikfenster initialisieren
  plotGraph = plotGraphClass(dataStream);       # externe Klasse
  cap = GUI_Elements(plotGraph.fi_1);           # externe Funktion
  displayInfo(plotGraph.fi_1);          clear inppu
        # externe Funktion
  inputPort.clearPort();                        # externe Klasse
  # Hauptschleife
  # =============
  datasetCounter = 0; datasetCounter_tic = 0; bytesReceived = 0;

  bench_tic = tic(); plot_tic = tic(); serial_tic = tic();
  [t_cpu_prev,t_user_prev,t_sys_prev] = cputime();

  do
    ## CLear-Button
    if (clear_data)
      j = 0;
      for i = 1:length(dataStream);
        dataStream(i).clear;
        if (dataStream(i).plot > 0)
          j = j + 1;
          set(plotGraph.subPl(j),"xlim",[0 dataStream(i).plotwidth*dataStream(i).dt]);
        endif
      endfor
      datasetCounter = 0;  datasetCounter_prev = 0;
      clear_data = 0;
    endif
    ## Save-Button
    if (save_data)
      rec_data = 0;
      dataMatrix = {};
      for i = 1:length(dataStream)
        ar_index = dataStream(i).ar_index;
        dataMatrix{end+1} = dataStream(i).name;
        dataMatrix{end+1} = [dataStream(i).array(ar_index:end) dataStream(i).array(1:ar_index-1)];
        dataMatrix{end+1} = [dataStream(i).t(ar_index:end) dataStream(i).t(1:ar_index-1)];
      endfor
      myfilename = uiputfile();
      if (myfilename != 0)
        save("-text",myfilename,"dataMatrix");
      endif
      save_data = 0;
    endif

    # Port auslesen
    # =============
    s_toc = toc(serial_tic);
    if (s_toc > SerialPort_Time)
      [bytesAvailable,inChar] = inputPort.readPort();  # >> inputPort.inBuffer;
      bytesReceived = bytesReceived + bytesAvailable;
      if (rec_data)   # Wird vom REC-Button gesteuert
        if (length(inChar) > 0)
           countMatches = inputPort.parseInput(inChar,dataStream);
           datasetCounter = datasetCounter + countMatches;         # datasetCounter laeuft durch
           datasetCounter_tic = datasetCounter_tic + countMatches; # datasetCounter_tic >> Bench_Time
        endif
      endif
      serial_tic = tic();
    endif # s_toc

    # Plot-Graphikfenster
    # ===================
    p_toc = toc(plot_tic);
    if (p_toc > Plot_Time)
      plotGraph.draw(dataStream);
      if (ishandle(plotGraph.fi_1))
        set(cap(1),"string",num2str(datasetCounter));
      endif
      drawnow();
      plot_tic = tic();
    endif # p_toc
    # Entlastung der CPU
    pause(Pause_Time);

    # Benchmarking
    # ============
    b_toc = toc(bench_tic);
    if (b_toc > Bench_Time)
      # Empfangene Bytes pro Sekunde
      f_oct = round(datasetCounter_tic/b_toc);
      datasetCounter_tic = 0;
      bytesPerSecond = round(bytesReceived / b_toc);
      bytesReceived = 0;

      [t_cpu,t_user,t_sys] = cputime();
      user_load = t_user - t_user_prev;
      sys_load  = t_sys - t_sys_prev;
      t_cpu_prev = t_cpu;
      t_user_prev = t_user;
      t_sys_prev = t_sys;
      if (ishandle(plotGraph.fi_1))
        set(cap(2),"string",num2str(f_oct));
        set(cap(3),"string",num2str(b_toc));
        set(cap(4),"string",num2str(user_load));
        set(cap(5),"string",num2str(bytesPerSecond));
        set(cap(6),"string",num2str(countMatches));
      endif # ishandle(fi_1)
      bench_tic=tic();
    endif # b_toc
  until(quit_prg);
  clear inputPort;
endif


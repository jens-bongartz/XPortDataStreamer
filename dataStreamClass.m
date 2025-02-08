# dataStreamClass.m >> This is a handle-Class!
classdef dataStreamClass < handle

    properties
        # ar_index >> Counter fuer Ringspeicher
        # index    >> Counter fuer alle Abtastwerte des dataStream
        name      = "";
        array     = []; ar_index  = 1; length = 2000; index = 1;
        t         = []; t_actual  = 0;
        plotwidth = 800; plot     = 1; plcolor   = "";
        ylim      = 0;    #yalternativ lim = [0 100];
        ylim      = [-100 100];    #yalternativ lim = [0 100];
        filter    = 1;
        # Filter-Speicher
        HP_sp  = [0 0 0 0 0 0]; NO_sp  = [0 0 0 0 0 0]; TP_sp  = [0 0 0 0 0 0];
        FIR_sp = [0];
        # Filter-Koeffizienten
        HP_ko  = [0 0 0 0 0]; NO_ko   = [0 0 0 0 0]; TP_ko  = [0 0 0 0 0];
        FIR_ko = [0];

        meanWindow     = 15;
        meanValue      = 0;

        maxWindow      = 300;
        maxValue       = 0;
        maxIndexList   = [];
        maxValueList   = [];

        peakTriggerIdx = 0;
        peakWidth      = 25;

        slopeDetector = 0; lastSample = 0; lastSlope = 1; lastMaxTime = 0;
        peakDetector = 0; peakThreshold = 0; peakTrigger = 0; lastPeakTime  = 0;

        evalCounter = 0; evalWindow = 200;
        BPM = 0;
    endproperties

    methods (Access=public)

        function self = dataStreamClass(name,plcolor,plotwidth,plot,filter)
          self.name      = name;
          self.plcolor   = plcolor;
          self.plotwidth = plotwidth;
          self.plot      = plot;
          self.filter    = filter;
          self.initRingBuffer();
        endfunction

        function initRingBuffer(self)
          self.array    = zeros(1,self.length);
          self.t        = zeros(1,self.length);
          self.ar_index = 1;
        endfunction

        function createIIRFilter(self,f_abtast,f_HP,f_NO,f_TP)
          self.HP_ko = calcHPCoeff(f_abtast,f_HP);
          self.NO_ko = calcNotchCoeff(f_abtast,f_NO);
          self.TP_ko = calcTPCoeff(f_abtast,f_TP);
          ##self.DQ_ko  = [1 -1 0 0 0];                   # (x[n]-x[n-1])/1
          ##self.DQ2_ko = [1 0 -1 0 0];                   # (x[n]-x[n-2])/(2) (1)
        endfunction

        function createFIRFilter(self,fa,df,f1,f2)
          # Erstellen der Filterkoeffizienten
          self.FIR_ko = calcFIRCoeff(fa,df,f1,f2);
          # Erstellen des FIR-Eingangsbuffer entsprechend der Filtergroesse
          self.FIR_sp = zeros(1,length(self.FIR_ko));
          # beide Vektoren sind persistent mit dem dataStream Objekt
        endfunction

        function addSample(self,sample,timestamp)

          if (self.filter > 0)
            sample = self.doFilter(sample);  # hier laufen alle Samples durch
          endif

          if (abs(sample) < 0.0001)        # 'dataaspectratio' Error verhindern
            sample = 0;
          endif

          self.array(self.ar_index)  = sample;
          self.t(self.ar_index)      = timestamp;
          self.t_actual              = timestamp;

          self.index = self.index + 1;
          # Ringspeicher Indexing
          self.ar_index = self.ar_index + 1;
          if (self.ar_index > self.length)
            self.ar_index = 1;
          endif

          # Peak-Detector
          if (self.peakDetector)
            self.evalCounter = self.evalCounter + 1;
            # regelmaessig neu Threshold bestimmen
            if (self.evalCounter > self.evalWindow)
              self.evalThreshold;
            endif
            self.peakDetectorFunction(sample);
          endif
          # Slope-Detector
          if (self.slopeDetector)
            self.slopeDetectorFunction(sample);
          endif
          self.lastSample = sample;
        endfunction


        # Returns the value n samples before the current
        function sample = getSample(self,n)
          if (self.ar_index - n > 0)          # kein Wrap-Around notwendig
            sample = self.array(self.ar_index-n);
          else                                 # n > ar_index >> Wrap-Around
            n1 = n - self.ar_index;
            sample = self.array(self.length-n1);
          endif
        endfunction


        # Returns the n last samples
        function [ret_array, ret_time] = lastSamples(self,n)
          if (self.ar_index - n > 0)          # kein Wrap-Around notwendig
            ret_array = self.array(self.ar_index-n:self.ar_index-1);
            ret_time  = self.t(self.ar_index-n:self.ar_index-1);
          else                                 # n > ar_index >> Wrap-Around
            n1 = n - self.ar_index;
            ret_array = self.array(self.length-n1:self.length);
            ret_array = [ret_array self.array(1:self.ar_index-1)];
            ret_time = self.t(self.length-n1:self.length);
            ret_time = [ret_time self.t(1:self.ar_index-1)];
          endif
        endfunction


        function sample = doFilter(self,sample)
          # Statusvariablen ob Filter gesetzt sind
          global HP_filtered NO_filtered TP_filtered AM_filtered FIR_filtered;
          # am 22.11.2024 FIR Filteroption hinzugefuegt
          if (FIR_filtered)
            # FIR-Eingangsbuffer wird veschoben und mit neuem Sample ergaenzt
            self.FIR_sp = [sample self.FIR_sp(1:end-1)];
            # Filter entspricht Skalarprodukt von Eingangsbuffer und Filterkoeff.
            sample = dot(self.FIR_sp,self.FIR_ko);
          endif

          if (NO_filtered)
            [sample,self.NO_sp] = biquadFilter(sample,self.NO_sp,self.NO_ko);
           endif
           if (TP_filtered)
             [sample,self.TP_sp] = biquadFilter(sample,self.TP_sp,self.TP_ko);
           endif
           if (HP_filtered)
             [sample,self.HP_sp] = biquadFilter(sample,self.HP_sp,self.HP_ko);
           endif
           # Adaptive Mean-Filter
           # ====================
           # inkrementeller Mittelwert >> meanWindow
           self.meanValue = self.meanValue + (sample - self.getSample(self.meanWindow)) / self.meanWindow;

           # inkrementeller Maxfilter
           self.maxValueList(self.index) = sample;
           if ~isempty(self.maxIndexList) && (self.maxIndexList(1) < self.index - self.maxWindow)
             self.maxIndexList(1) = [];
           endif
           while ~isempty(self.maxIndexList) && self.maxValueList(self.maxIndexList(end)) < sample
             self.maxIndexList(end) = [];
           endwhile
           self.maxIndexList(end+1) = self.index;
           self.maxValue = self.maxValueList(self.maxIndexList(1));
           #########################
           if (AM_filtered)
             if (self.index - self.peakTriggerIdx > self.peakWidth)
               if (abs(sample - self.meanValue) > self.maxValue / 3)
                  sample = sample;
                  self.peakTriggerIdx = self.index;
               else
                  sample = self.meanValue;
               endif
             else
                  ##disp(self.index);
                  sample = sample;
             endif
           endif
        endfunction

        ########################################################################

        function slopeDetectorFunction(self,sample)
          slope = sign(sample - self.lastSample);
          if (slope ~= self.lastSlope)
            if (slope < self.lastSlope) # Ubergang 1 >> -1 = Maximum
              if (self.t_actual - self.lastMaxTime > 50)
               self.BPM = round(60000 / (self.t_actual - self.lastMaxTime));
               self.lastMaxTime = self.t_actual;
              endif
            endif
          endif
          self.lastSlope  = slope;
        endfunction

        function evalThreshold(self)
          evalArray = self.lastSamples(self.evalWindow);
          if (max(evalArray) > 4*std(evalArray))
             self.peakThreshold = 0.5*max(evalArray);
          endif
          self.evalCounter = 0;
        endfunction

        function peakDetectorFunction(self,sample)
          # und Threshold vergleichen
          if ((sample > self.peakThreshold) && !self.peakTrigger)
            # Doppel-Peaks unterdruecken (50ms)
            if (self.t_actual - self.lastPeakTime > 50)
              self.BPM = round(60000 / (self.t_actual - self.lastPeakTime));
              self.lastPeakTime = self.t_actual;
              self.peakTrigger = 1;
            endif
          endif
          if ((sample < self.peakThreshold) && self.peakTrigger)
            self.peakTrigger = 0;
          endif
        endfunction

        function clear(self)
          self.index        = 1;
          self.ar_index     = 1;
          self.t_actual     = 0;
          self.lastMaxTime  = 0;
          self.lastPeakTime = 0;
          self.initRingBuffer();
        endfunction

        function disp(self)
            disp("dataStreamClass");
            disp(self.name);
        endfunction
    endmethods
end


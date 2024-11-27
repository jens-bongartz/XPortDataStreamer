classdef udpPortClass < handle

  properties
    streamSelector = [];
    regex_pattern = '';
    serialPortPath = '';
    inBuffer = '';
    port_01 = '';
  endproperties

  methods
    function self = udpPortClass()    # Constructor
      close self.port_01;
      disp('Opening UDP Port ... ')
      #udpport gibt Parameter aus
      self.port_01 = udpport ("LocalHost","192.168.1.4","LocalPort",8266)
    endfunction

    function clearPort(self)
      posLF = 0;
      do
        bytesAvailable = self.port_01.NumBytesAvailable;
        if (bytesAvailable > 0)
          inUDPPort = char(read(self.port_01,bytesAvailable))
          posLF     = index(inUDPPort,char(10),"last")
        endif
      until (posLF > 0);
      # erst ab dem letzten \n geht es los
      self.inBuffer = inUDPPort(posLF+1:end);
    endfunction

    function [bytesAvailable,inChar] = readPort(self)
      udp_count = 0;
      do
         udp_count += 1
         bytesAvailable = self.port_01.NumBytesAvailable
         inUDPPort   = char(read(self.port_01,bytesAvailable));
         self.inBuffer  = [self.inBuffer inUDPPort];
      until (self.port_01.NumBytesAvailable == 0)
      posLF          = index(self.inBuffer,char(10),"last");
      inChar         = '';
      if (posLF > 0)
        inChar   = self.inBuffer(1:posLF);
        self.inBuffer = self.inBuffer(posLF+1:end);
      endif
    endfunction

    function countMatches = parseInput(self,inChar,dataStream)
      matches = regexp(inChar, self.regex_pattern, 'tokens'); # Regular Expression auswerten
      countMatches   = length(matches);                       # Wert wird ausgegeben
      for i = 1:countMatches
        streamName = matches{i}{1};
        adc        = str2num(matches{i}{2});
        sample_t   = str2num(matches{i}{3});
        j = self.streamSelector(streamName);     # Sample einem dataStream zuweisen
        dataStream(j).addSample(adc,sample_t);   # Hier uebernimmt dataStream die Arbeit
        #dataStream(j).addSample(adc,5);   # Hier uebernimmt dataStream die Arbeit
      endfor
    endfunction

    function createRegEx(self,dataStream)
      self.regex_pattern = '(';
      for i = 1:length(dataStream)
        self.regex_pattern = [self.regex_pattern dataStream(i).name];
        if i < length(dataStream)
          self.regex_pattern = [self.regex_pattern '|'];
        endif
      endfor
      self.regex_pattern = [self.regex_pattern '):(-?\d+),t:(\d+)'];
    endfunction

    function createSelector(self,dataStream)
      # Liste aller dataStream Namen erstellen fuer Dictonary
      namelist = {};
      for i = 1:length(dataStream)
        namelist{end+1} = dataStream(i).name;
      endfor
      values = 1:numel(dataStream);
      self.streamSelector = containers.Map(namelist,values);
    endfunction
  endmethods
end

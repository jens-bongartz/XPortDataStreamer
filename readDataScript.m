# Das Skript liest in Multiplot gespeicherte Daten wieder ein
# und zeigt sie in Plot-Fenster an
#
dataStream = [];

readData = load("test_01.txt");
streamCount = (length(readData.dataMatrix)/3)

for i = 1:streamCount
  dataStream(i).name = readData.dataMatrix{(i-1)*3+1};
  dataStream(i).array = readData.dataMatrix{(i-1)*3+2};
  dataStream(i).t     = readData.dataMatrix{(i-1)*3+3};
endfor

for i = 1:length(dataStream)
  figure(1)
  plot(dataStream(i).array)
  figure(2)
  plot(dataStream(i).t)
  figure(3)
  plot(dataStream(i).t,dataStream(i).array)
endfor
daten = dataStream(1).array;

##fa = 200;
##df = fa/length(daten);
##f = -fa/2:df:fa/2-df;
##daten = daten-mean(daten);
##fourier=fftshift(abs(fft(daten)));
##fourier=fourier/max(fourier);
##
##plot(f,fourier)
###axis([0 100 0 1000])


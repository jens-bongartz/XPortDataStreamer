// Anschluss ADS1115: SCL >> A5, SDA >> A4

#include <TimerOne.h>
#include <ADS1115_WE.h>
#include <Wire.h>

#define I2C_ADDRESS 0x48

int faADC  = 200;
int adcValue = 0;
ADS1115_WE adc = ADS1115_WE(I2C_ADDRESS);

void setup() {
  Wire.begin();
  Serial.begin(115200);
  // put your setup code here, to run once:
  if(!adc.init()){
    Serial.println("ADS1115 not connected!");
  }
  else
  {
    Serial.println("ADS1115 found!");         
  }
  adc.setVoltageRange_mV(ADS1115_RANGE_0256);   
  adc.setCompareChannels(ADS1115_COMP_0_1);
  adc.setConvRate(ADS1115_250_SPS);              
  adc.setMeasureMode(ADS1115_CONTINUOUS);

  Timer1.initialize(1000000/faADC);             
  Timer1.attachInterrupt(readADC);   
  Timer1.start();
}

void loop() {
  adcValue = adc.getRawResult();
}

void readADC() {
  //int adcValue = adc.getRawResult();
  Serial.print("FBT:");
  Serial.print(adcValue);
  Serial.print(",t:");
  Serial.println(millis());
}

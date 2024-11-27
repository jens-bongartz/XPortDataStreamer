#include <ADS1115_WE.h>
#include <Wire.h>
#include "ESP8266TimerInterrupt.h"   

#define I2C_ADDRESS 0x48
// Select a Timer Clock
#define USING_TIM_DIV1                true           // for shortest and most accurate timer
#define USING_TIM_DIV16               false           // for medium time and medium accurate timer
#define USING_TIM_DIV256              false            // for longest timer but least accurate. Default

// Init ESP8266 only and only Timer 1
ESP8266Timer ITimer;
ADS1115_WE adc = ADS1115_WE(I2C_ADDRESS);

int faADC  = 200;

// Analoge Eingänge
int adcChannel = 0;  // A0
int adcValue = 0;

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
  
  ITimer.attachInterruptInterval(1000000/faADC, readADC);
}

void loop() {
  adcValue = adc.getRawResult();
}

void readADC() {
  Serial.print("FBT:");
  Serial.print(adcValue);
  Serial.print(",t:");
  Serial.println(millis());
}

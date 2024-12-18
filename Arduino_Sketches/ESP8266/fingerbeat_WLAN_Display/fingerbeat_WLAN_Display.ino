#include <Wire.h>
#include <U8g2lib.h>
#include <ADS1115_WE.h>

#include <ESP8266WiFi.h>
#include <WiFiUdp.h>
#include "ESP8266TimerInterrupt.h"   

// I2C Connection
#define SDA_PIN D2 
#define SCL_PIN D1 
#define I2C_ADDRESS 0x48   // ADS1115

// Select a Timer Clock
#define USING_TIM_DIV1                true             // for shortest and most accurate timer
#define USING_TIM_DIV16               false           // for medium time and medium accurate timer
#define USING_TIM_DIV256              false            // for longest timer but least accurate. Default

#define faADC 200
#define packetSize 20

// Wifi Daten
const char* ssid = "Raspi-Wifi-2.4";                       // Darf bis zu 32 Zeichen haben.
const char* password = "raspi01-wifi";            // Mindestens 8 Zeichen jedoch nicht länger als 64 Zeichen.
unsigned long previousMillis = 0;

int packetCounter = 0;
char packetBuffer[25 * packetSize];

WiFiUDP Udp;
IPAddress unicastIP(192, 168, 1, 2);                  // Adresse des Esp, welcher als Empfänger der Nachricht dient, eintragen.
constexpr uint16_t PORT = 8266;     

ESP8266Timer ITimer;
ADS1115_WE adc = ADS1115_WE(I2C_ADDRESS);

// U8G2_R2 = 180 degrees rotated
U8G2_SSD1306_128X64_NONAME_F_SW_I2C u8g2(U8G2_R2,SCL_PIN,SDA_PIN,U8X8_PIN_NONE);

void setup() {
  Wire.begin();
  Serial.begin(115200);
  // Startbildschirm ausgeben
  u8g2.begin();
  u8g2.clearBuffer();
  u8g2.setFont(u8g2_font_ncenB08_tr);
  u8g2.drawStr(0,20,"Power on");
  u8g2.drawStr(0,40,"Searching ...");
  u8g2.sendBuffer();
   
  u8g2.clearBuffer();
  
  // Mit WLAN verbinden 
  delay(100);
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nVerbunden mit: " + WiFi.SSID());
  u8g2.drawStr(0,20,"Wifi connected");

  // Mit ADS1115 verbinden
  if(!adc.init()){
    Serial.println("ADS1115 not connected!");
    u8g2.drawStr(0,40,"ADS1115 not connected");
  }
  else
  {
    Serial.println("ADS1115 found!");         
    u8g2.drawStr(0,40,"ADS1115 connected");
  }
  adc.setVoltageRange_mV(ADS1115_RANGE_0256);   
  adc.setCompareChannels(ADS1115_COMP_0_1);
  adc.setConvRate(ADS1115_250_SPS);              
  adc.setMeasureMode(ADS1115_CONTINUOUS);
  
  u8g2.sendBuffer();
  delay(1000); 
  
  // Interrupt-Timer starten
  ITimer.attachInterruptInterval(1000000/faADC, readADC);
  
}

void loop() {
}

void readADC() {
  int adcValue = adc.getRawResult();
  char mString[25];
  sprintf(mString,"FBT:%i,t:%lu\r\n", adcValue,millis());
  strcat(packetBuffer,mString);
  packetCounter++;
  if (packetCounter > packetSize-1) {
     Udp.beginPacket(unicastIP, PORT);
     Udp.write(packetBuffer);
     Udp.endPacket();
     packetCounter = 0;
     packetBuffer[0] = '\0';
  }
}
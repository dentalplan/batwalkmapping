// Test code for Adafruit GPS modules using MTK3329/MTK3339 driver
//
// This code shows how to listen to the GPS module in an interrupt
// which allows the program to have more 'freedom' - just parse
// when a new NMEA sentence is available! Then access data when
// desired.
//
// Tested and works great with the Adafruit Ultimate GPS module
// using MTK33x9 chipset
//    ------> http://www.adafruit.com/products/746
// Pick one up today at the Adafruit electronics shop
// and help support open source hardware & software! -ada

#include <SD.h>
#include <SPI.h>

#include <Adafruit_GPS.h>

#define LAT 0
#define LON 1
#define YEAR 0
#define MONTH 1
#define DAY 2
#define HOUR 3
#define MINUTE 4
#define SECONDS 5

float gLoc[2];
int gTime[6];
int gReady = 0;
int buttonState = 0;
const int sensPin = A18;
const int ledPin = 23;
const int buttonPin = 26;

#ifdef __AVR__
  #include <SoftwareSerial.h>
#endif

// If you're using a GPS module:
// Connect the GPS Power pin to 5V
// Connect the GPS Ground pin to ground
// If using software serial (sketch example default):
//   Connect the GPS TX (transmit) pin to Digital 3
//   Connect the GPS RX (receive) pin to Digital 2
// If using hardware serial (e.g. Arduino Mega):
//   Connect the GPS TX (transmit) pin to Arduino RX1, RX2 or RX3
//   Connect the GPS RX (receive) pin to matching TX1, TX2 or TX3

// If you're using the Adafruit GPS shield, change
// SoftwareSerial mySerial(3, 2); -> SoftwareSerial mySerial(8, 7);
// and make sure the switch is set to SoftSerial

// If using software serial, keep this line enabled
// (you can change the pin numbers to match your wiring):
//SoftwareSerial mySerial(3, 2);

// If using hardware serial (e.g. Arduino Mega, Leonardo, Due), comment
// out the above  line and enable this line instead:
#define mySerial Serial2

Adafruit_GPS GPS(&mySerial);
//String strOut;
File dataFile;
char filename[] = "LOG000.CSV";
int valid = 0;
boolean fileReady = 0;


// Set GPSECHO to 'false' to turn off echoing the GPS data to the Serial console
// Set to 'true' if you want to debug and listen to the raw GPS sentences.
#define GPSECHO  true

// this keeps track of whether we're using the interrupt
// off by default!
boolean usingInterrupt = false;
void useInterrupt(boolean); // Func prototype keeps Arduino 0023 happy

void setup() 
{

  // connect at 115200 so we can read the GPS fast enough and echo without dropping chars
  // also spit it out
  Serial.begin(115200);
  Serial.println("Adafruit GPS library basic test!");
  pinMode(ledPin, OUTPUT);
  pinMode(buttonPin, INPUT);
  // 9600 NMEA is the default baud rate for Adafruit MTK GPS's- some use 4800
  GPS.begin(9600);
  mySerial.begin(9600);
 
  // uncomment this line to turn on RMC (recommended minimum) and GGA (fix data) including altitude
  GPS.sendCommand(PMTK_SET_NMEA_OUTPUT_RMCGGA);
  // uncomment this line to turn on only the "minimum recommended" data
  //GPS.sendCommand(PMTK_SET_NMEA_OUTPUT_RMCONLY);
  // For parsing data, we don't suggest using anything but either RMC only or RMC+GGA since
  // the parser doesn't care about other sentences at this time
 
  // Set the update rate
  GPS.sendCommand(PMTK_SET_NMEA_UPDATE_1HZ);   // 1 Hz update rate
  // For the parsing code to work nicely and have time to sort thru the data, and
  // print it out we don't suggest using anything higher than 1 Hz

  // Request updates on antenna status, comment out to keep quiet
  GPS.sendCommand(PGCMD_ANTENNA);

  // the nice thing about this code is you can have a timer0 interrupt go off
  // every 1 millisecond, and read data from the GPS for you. that makes the
  // loop code a heck of a lot easier!

  #ifdef __arm__
    usingInterrupt = false;  //NOTE - we don't want to use interrupts on the Due
  #else
    useInterrupt(true);
  #endif

  delay(1000);
  // Ask for firmware version
  mySerial.println(PMTK_Q_RELEASE);

  //Start SD card
  SD.begin(BUILTIN_SDCARD);  
  for (int i = 0; (i < 1000) && (fileReady == 0); i++) {
    Serial.println(i);
    filename[3] = i/100 + '0';
    filename[4] = i/10 + '0';
    filename[5] = i%10 + '0';
    if (! SD.exists(filename)) {
      // only open a new file if it doesn't exist
      dataFile = SD.open(filename, FILE_WRITE);       
      if (dataFile) { 
        dataFile.println("sens,millis,time,lat,lon,valid,interest");
        dataFile.close();
        Serial.print(filename);
        Serial.println(" opened");
      }else{
        Serial.print(filename);
        Serial.println(" failed");
      }
      fileReady = 1;
      
   //   break;  // leave the loop!
    }
  }
  
}

#ifdef __AVR__
// Interrupt is called once a millisecond, looks for any new GPS data, and stores it
SIGNAL(TIMER0_COMPA_vect) {
  char c = GPS.read();
  // if you want to debug, this is a good time to do it!
#ifdef UDR0
  if (GPSECHO)
    if (c) UDR0 = c; 
    // writing direct to UDR0 is much much faster than Serial.print
    // but only one character can be written at a time.
#endif
}

void useInterrupt(boolean v) {
  if (v) {
    // Timer0 is already used for millis() - we'll just interrupt somewhere
    // in the middle and call the "Compare A" function above
    OCR0A = 0xAF;
    TIMSK0 |= _BV(OCIE0A);
    usingInterrupt = true;
  } else {
    // do not call the interrupt function COMPA anymore
    TIMSK0 &= ~_BV(OCIE0A);
    usingInterrupt = false;
  }
}
#endif //#ifdef__AVR__

uint32_t GPStimer = millis();
uint32_t GSRtimer = millis();
void loop()                     // run over and over again
{
  // in case you are not using the interrupt above, you'll
  // need to 'hand query' the GPS, not suggested :(
  if (! usingInterrupt) {
    // read data from the GPS in the 'main loop'
    char c = GPS.read();
    // if you want to debug, this is a good time to do it!
    if (GPSECHO)
      if (c) Serial.print(c);
  }
  
  // if a sentence is received, we can check the checksum, parse it...
  if (GPS.newNMEAreceived()) {
    // a tricky thing here is if we print the NMEA sentence, or data
    // we end up not listening and catching other sentences! 
    // so be very wary if using OUTPUT_ALLDATA and trytng to print out data
    //Serial.println(GPS.lastNMEA());   // this also sets the newNMEAreceived() flag to false
  
    if (!GPS.parse(GPS.lastNMEA()))   // this also sets the newNMEAreceived() flag to false
      return;  // we can fail to parse a sentence in which case we should just wait for another
  }

  // if millis() or timer wraps around, we'll just reset it
  if (GPStimer > millis())  GPStimer = millis();
  if (GSRtimer > millis())  GSRtimer = millis();

  // approximately 5 times every second log GSR and location
  //analogWrite(ledPin, 255);
  if (fileReady == 0){
    analogWrite(ledPin, 0);
  }

  if (millis() - GSRtimer > 10){
    int buttonVal =  digitalRead(buttonPin);
    if (buttonVal == HIGH){
      buttonState = 1;
    }
  }
  
  if (millis() - GSRtimer > 200){
    GSRtimer = millis();
    int sensVal = analogRead(sensPin);
    if (sensVal > 120){
      if (gReady == 1){
        valid = 1;
      }else{
        valid = 0;
      }
    }
    if (millis() - GPStimer < 2800){
      int outVal = map(sensVal, 0, 1023, 0, 128);
      analogWrite(ledPin, outVal);
    }else if(gReady == 1){
      analogWrite(ledPin, 255);
    }else{
      analogWrite(ledPin, 0);
    }
    writeToFile(sensVal);
    buttonState = 0;
  }

  // approximately every 3 seconds or so, print out the current stats  
  if (millis() - GPStimer > 3000) { 
    GPStimer = millis(); // reset the timer
    printGPSstatusToSerial();
    if (GPS.fix) {
      printGPSlocToSerial();
      gTime[YEAR] = GPS.year;
      gTime[MONTH] = GPS.month;
      gTime[DAY] = GPS.day;
      gTime[HOUR] = GPS.hour;
      gTime[MINUTE] = GPS.minute;
      gTime[SECONDS] = GPS.seconds;
      gLoc[LAT] = GPS.latitudeDegrees;
      gLoc[LON] = GPS.longitudeDegrees;
      gReady = 1;
//      strOut = GPS.hour + ":" + GPS.minute + ":" + GPS.seconds + "," + GPS.latitudeDegrees + "," + GPS.longitudeDegrees;
    }else{
      gReady = 0;
    }


  }
}



void writeToFile(int sensVal) {
  dataFile = SD.open(filename, FILE_WRITE);
  if (dataFile) { 
    Serial.print("GSR = ");
    Serial.println(sensVal);
    dataFile.print(sensVal);
    dataFile.print(",");
    dataFile.print(millis());
    dataFile.print(',');
    if (gReady == 1){
      Serial.print("writing: ");
      if(gTime[HOUR] < 10){ dataFile.print('0');}
      dataFile.print(gTime[HOUR], DEC);
      dataFile.print(':');
      if(gTime[MINUTE] < 10){ dataFile.print('0');}
      dataFile.print(gTime[MINUTE], DEC);
      dataFile.print(':');
      if(gTime[SECONDS] < 10){ dataFile.print('0');}
      dataFile.print(gTime[SECONDS], DEC);
      dataFile.print(',');
      dataFile.print(gLoc[LAT], 9);
      dataFile.print(',');
      dataFile.print(gLoc[LON], 9);      
      dataFile.print(',');
      dataFile.print(valid);
      dataFile.print(',');
      dataFile.print(buttonState);
    }else{
      dataFile.print("waiting on GPS");
      dataFile.print(',');
      dataFile.print(',');
      dataFile.print(',');
      dataFile.println(valid);
    }
    dataFile.close();
    fileReady = 1;
  } else {
    Serial.println("failed");    
    fileReady = 0;
  }
}

void printGPSlocToSerial(){
  Serial.print("Location: ");
  Serial.print(GPS.latitude, 4); Serial.print(GPS.lat);
  Serial.print(", "); 
  Serial.print(GPS.longitude, 4); Serial.println(GPS.lon);
  Serial.print("Location (in degrees, works with Google Maps): ");
  Serial.print(GPS.latitudeDegrees, 4);
  Serial.print(", "); 
  Serial.println(GPS.longitudeDegrees, 4);
  Serial.print("Speed (knots): "); Serial.println(GPS.speed);
  Serial.print("Angle: "); Serial.println(GPS.angle);
  Serial.print("Altitude: "); Serial.println(GPS.altitude);
  Serial.print("Satellites: "); Serial.println((int)GPS.satellites);
}

void printGPSstatusToSerial(){
  Serial.print("\nTime: ");
  Serial.print(GPS.hour, DEC); Serial.print(':');
  Serial.print(GPS.minute, DEC); Serial.print(':');
  Serial.print(GPS.seconds, DEC); Serial.print('.');
  Serial.println(GPS.milliseconds);
  Serial.print("Date: ");
  Serial.print(GPS.day, DEC); Serial.print('/');
  Serial.print(GPS.month, DEC); Serial.print("/20");
  Serial.println(GPS.year, DEC);
  Serial.print("Fix: "); Serial.print((int)GPS.fix);
  Serial.print(" quality: "); Serial.println((int)GPS.fixquality); 
}

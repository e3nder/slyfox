/*
Arduino code to control three Experimental Parameters.
  1. Setting of the Liquid Crystal Waveplate.
  2. One TTL Passthrough (Either Always low or passthrough).
  3. Execute a Pulse after an interrupt, given a delay time, and a pulse time.
    (Say for example a clock pulse).

Language: Arduino language.
Environment: Arduino 0022

Copyright (C) 2012 by Ben Bloom
MIT License

Ver: 0.2
*/

#define pinINT1 2 //Needs to be here, because it is an interrupt pin - Used for Initiating Communication with Computer
#define pinINT2 3 //Needs to be here, because it is an interrupt pin - Used for Initiating Clock Pulse
#define pinLCWaveplate 6 // High voltage corresponds to V2 on LC Waveplate Controller

#define pinTTL_IN1 7 //Reads this TTL In
#define pinTTL_OUT1 5 //Depending on state either mirrors TTL_IN1 or is held low.
#define setPinTTL_OUT1_HIGH() PORTD |= 0b00100000;
#define setPinTTL_OUT1_LOW() PORTD &= 0b11011111;

#define pinTTL_IN2 A0 //Reads this TTL In
#define pinTTL_OUT2 A1 //Depending on state either mirrors TTL_IN1 or is held low.
#define setPinTTL_OUT2_HIGH() PORTC |= 0b00000010;
#define setPinTTL_OUT2_LOW() PORTC &= 0b11111101;

#define pinTTL_IN3_pol 10
#define pinTTL_IN3_Upol 11
#define pinTTL_OUT3 12 //Source of mirrored TTL is set by mirrorTTL3source.
#define setPinTTL_OUT3_HIGH() PORTB |= 0b00010000;
#define setPinTTL_OUT3_LOW() PORTB &= 0b11101111;

#define pinTTL_IN4 A3 //Reads this TTL In
#define pinTTL_OUT4 A2 //Depending on state either mirrors TTL_IN1 or is held HIGH.
#define setPinTTL_OUT4_HIGH() PORTC |= 0b00000100;
#define setPinTTL_OUT4_LOW() PORTC &= 0b11111011;

#define pinClockTTL 8 //Used when arduino is used to supply clock AOM TTL

#define pinLED 13 



#define SERIAL_IDLE 0
#define SERIAL_RECEIVING 1
#define DATA_NOT_READY 0
#define DATA_READY 1

const int numPulses = 5;
const int pulseLength = 2000;
int incomingByte;  // for incoming serial data
boolean readingMode;
byte serialStatus;  //idle or receiving
byte dataStatus;  //ready or not ready
byte serialInputCount; //how many bytes received
volatile int mode = 0; // Mode 0 does not step cycle number
                       // Mode 1 steps cycle counter
                       // Mode 2 is a mod 8 cycle counter
                       // Mode 3 is unpolarized
volatile boolean startCOM = false;
volatile char Command[3];
volatile int cmdIDX; // for building Command list
volatile unsigned long Val0; // for Command[0]
volatile unsigned long Val1; // for Command[1]
volatile unsigned long Val2; // for Command[2]

volatile unsigned long clockDelayTime = 0;
volatile unsigned long clockPulseTime = 80000;

volatile int cycleNum = 666;
volatile boolean mirrorTTL1 = true; // This is usually for varying systematics
volatile boolean mirrorTTL2 = true; // Used for mirroring the Clock Bias field on/off
volatile int mirrorTTL3source = pinTTL_IN3_pol; // 10 - source for beta shutter for polarized sequence
                                                // 11 - source for beta shutter for unpolarized sequence
volatile boolean mirrorTTL4 = true; // Used for mirroring the Z shim coil rotation

void setup(){
  Serial_Init();
  pinMode(pinLED, OUTPUT);
  pinMode(pinINT1, INPUT);
  pinMode(pinINT2, INPUT);
  pinMode(pinLCWaveplate, OUTPUT);
  pinMode(pinTTL_IN1, INPUT);
  pinMode(pinTTL_OUT1, OUTPUT);
  pinMode(pinTTL_IN2, INPUT);
  pinMode(pinTTL_OUT2, OUTPUT);
  pinMode(pinTTL_OUT3, OUTPUT);
  pinMode(pinTTL_IN3_pol, INPUT);
  pinMode(pinTTL_IN3_Upol, INPUT);
  pinMode(pinTTL_IN4, INPUT);
  pinMode(pinTTL_OUT4, OUTPUT);
  pinMode(pinClockTTL, OUTPUT);
  attachInterrupt(0, changeStartCOM, RISING);
  attachInterrupt(1, advanceCycleNum, RISING);
}

void loop(){
  if (mirrorTTL1)
  { 
    if(digitalRead(pinTTL_IN1)){
      setPinTTL_OUT1_HIGH();
    }else
    {
      setPinTTL_OUT1_LOW();
    }
  }
  else
  {
    setPinTTL_OUT1_LOW();
  }
  if (mirrorTTL2)
  { 
    if(digitalRead(pinTTL_IN2)){
      setPinTTL_OUT2_HIGH();
    }else
    {
      setPinTTL_OUT2_LOW();
    }
  }
  else
  {
    setPinTTL_OUT2_LOW();
  }
  
  if(digitalRead(mirrorTTL3source)){
      setPinTTL_OUT3_HIGH();
    }else
    {
      setPinTTL_OUT3_LOW();
    }
  if (mirrorTTL4)
  { 
    if(digitalRead(pinTTL_IN4)){
      setPinTTL_OUT4_HIGH();
    }else
    {
      setPinTTL_OUT4_LOW();
    }
  }
  else
  {
    setPinTTL_OUT4_HIGH(); //this is just because of the logic state of the z-field rotation
  }
    
  if (mode == 0 || mode == 1) {
    switch (cycleNum){
      case 0:
        digitalWrite(pinLCWaveplate, HIGH);
        digitalWrite(pinLED, HIGH);
        break;
      case 1:
        digitalWrite(pinLCWaveplate, HIGH);
        digitalWrite(pinLED, HIGH);
        break;
      case 2:
        digitalWrite(pinLCWaveplate, LOW);
        digitalWrite(pinLED, LOW);
        break;
      case 3:
        digitalWrite(pinLCWaveplate, LOW);
        digitalWrite(pinLED, LOW);
        break;
    }
  }
  else if (mode == 2){
    switch (cycleNum){
      case 0:
        digitalWrite(pinLCWaveplate, HIGH);
        digitalWrite(pinLED, HIGH);
        break;
      case 1:
        digitalWrite(pinLCWaveplate, HIGH);
        digitalWrite(pinLED, HIGH);
        break;
      case 2:
        digitalWrite(pinLCWaveplate, HIGH);
        digitalWrite(pinLED, HIGH);
        break;
      case 3:
        digitalWrite(pinLCWaveplate, HIGH);
        digitalWrite(pinLED, HIGH);
        break;
      case 4:
        digitalWrite(pinLCWaveplate, LOW);
        digitalWrite(pinLED, LOW);
        break;
      case 5:
        digitalWrite(pinLCWaveplate, LOW);
        digitalWrite(pinLED, LOW);
        break;
      case 6:
        digitalWrite(pinLCWaveplate, LOW);
        digitalWrite(pinLED, LOW);
        break;
      case 7:
        digitalWrite(pinLCWaveplate, LOW);
        digitalWrite(pinLED, LOW);
        break;
    }
  }
  
  if (startCOM) {
    ComputerCom();
    startCOM = !startCOM;
  }
}

void setCycleAttributes(){
  mirrorTTL3source = pinTTL_IN3_pol; //default polarized line beta shutter sequence
  mirrorTTL2 = true;  //default clock bias field TTL mirrored
  mirrorTTL4 = true;
  if (mode == 1) {
    cycleNum %= 4;
    
    switch (cycleNum){
      case 0:
        mirrorTTL1 = false;
        break;
      case 1:
        mirrorTTL1 = false;
        break;
      case 2:
        mirrorTTL1 = true;
        break;
      case 3:
        mirrorTTL1 = true;
        break;
    }
  }
  else if (mode == 2) {
    cycleNum %= 8;
    
    switch (cycleNum){
      case 0:
        mirrorTTL1 = false;
        break;
      case 1:
        mirrorTTL1 = false;
        break;
      case 2:
        mirrorTTL1 = true;
        break;
      case 3:
        mirrorTTL1 = true;
        break;
      case 4:
        mirrorTTL1 = false;
        break;
      case 5:
        mirrorTTL1 = false;
        break;
      case 6:
        mirrorTTL1 = true;
        break;
      case 7:
        mirrorTTL1 = true;
        break;
    }
  }
  else if (mode == 4){
    mirrorTTL1 = false;
    mirrorTTL2 = false; //Leave clock bias field off
    mirrorTTL3source = pinTTL_IN3_Upol; //Use unpolarized beta shutter protocol
    mirrorTTL4 = false; //do not add shim coil rotation to zero field state
  }
  else {
    mirrorTTL1 = true;
  }
  
}
void advanceCycleNum(){
  mirrorTTL3source = pinTTL_IN3_pol; //default polarized line beta shutter sequence
  mirrorTTL2 = true;  //default clock bias field TTL mirrored
  mirrorTTL4 = true;
  if (mode == 1) {
    cycleNum += 1;
    cycleNum %= 4;

  }
  else if (mode == 2) {
    cycleNum += 1;
    cycleNum %= 8;
  }
  else {
    mirrorTTL1 = true;
  }
  
  setCycleAttributes();
}

void changeStartCOM(){
  startCOM = !startCOM;
}
void ComputerCom(){
    //Serial.println("Ready");
    digitalWrite(pinLED, HIGH);
    cmdIDX = -1;
    Val0 = 0;
    Val1 = 0;
    Val2 = 0;
    readingMode = false;
    while (Serial.available() > 0) {
      // read the incoming byte:
        incomingByte = Serial.read();
        if (incomingByte == ':'){
          readingMode = true;
        }
        else if (readingMode){
          mode = int(incomingByte - '0');
          readingMode = false;
        }
        else if (incomingByte==';') {
          serialInputCount=0;
          serialStatus=SERIAL_RECEIVING;
          cmdIDX++;
        }
        else {
          if (serialInputCount==0) {
            Command[cmdIDX]=char(incomingByte);
            serialInputCount++;
            //Serial.println(char(incomingByte));
          }
          else{
            switch (cmdIDX) {
              case 0:
                Val0 = (Val0 * 10) + (incomingByte - '0');
              break;
              
              case 1:
                Val1 = (Val1 * 10) + (incomingByte - '0');
              break;
              
              case 2:
                Val2 = (Val2 * 10) + (incomingByte - '0');
              break;
            }
            serialInputCount++;
          }
        }
    }
    if (cmdIDX > -1) {
      for (int x = 0; x<3; x++){ //For now I am just forcing commands in the order 'c' 'd' 't'
        switch (Command[x]) {
          case 'c':
            cycleNum = Val0;
          break;
          
          case 'd':
            clockDelayTime = Val1;
          break;
          
          case 't':
            clockPulseTime = Val2;
          break;
        }
      }
    }
      digitalWrite(pinLED, LOW);
      //QUICK HACK TO GET TIMING CORRECT FOR UNPOLARIZED LINE
//      if (mode == 4){
//        mirrorTTL1 = true;
//        mirrorTTL2 = false; //Leave clock bias field off
//        mirrorTTL3source = pinTTL_IN3_Upol; //Use unpolarized beta shutter protocol
//        mirrorTTL4 = false; //do not add shim coil rotation to zero field state
//      }
//      else {
//        mirrorTTL1 = true;
//      }
    setCycleAttributes();
      //Serial.println(cycleNum);
}

void Serial_Init(void) {
  Serial.begin(57600);
}

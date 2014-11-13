 #include <Timer.h>
 #include "BlinkToRadio.h"
 /**
*
*	Abdul Al-Faraj
*	110149637
*	Computer Networks - Coursework 1
**/
configuration BlinkToRadioAppC {}

implementation {
  components BlinkToRadioC;

  components MainC;
  components LedsC;
  components AMSendReceiveC as Radio;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;
  components new TimerMilliC() as Timer3;
  components new TimerMilliC() as Timer4;
  components new TimerMilliC() as Timer5;
  components new TimerMilliC() as Timer6;
  components new TimerMilliC() as Timer7;
  
  BlinkToRadioC.Boot -> MainC;
  BlinkToRadioC.RadioControl -> Radio;

  BlinkToRadioC.Leds -> LedsC;
  BlinkToRadioC.Timer0 -> Timer0;
  BlinkToRadioC.Timer1 -> Timer1;
  BlinkToRadioC.Timer2 -> Timer2;
  BlinkToRadioC.Timer3 -> Timer3;
  BlinkToRadioC.Timer4 -> Timer4;
  BlinkToRadioC.Timer5 -> Timer5;
  BlinkToRadioC.Timer6 -> Timer6;
  BlinkToRadioC.Timer7 -> Timer7;
  
  BlinkToRadioC.Packet -> Radio;
  BlinkToRadioC.AMPacket -> Radio;
  BlinkToRadioC.AMSendReceiveI -> Radio;
}

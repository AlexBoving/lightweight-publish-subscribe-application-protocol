#include "LightWeight.h"
#include "printf.h"
#define NEW_PRINTF_SEMANTICS //Comment this line when using tossim.

configuration LightWeightAppC {}

implementation {

  components MainC, LightWeightC as App;
  // Add the other components here.
  components new TimerMilliC() as temp_t;
  components new TimerMilliC() as hum_t;
  components new TimerMilliC() as lum_t;
  components new TimerMilliC() as time_0;
  components new TimerMilliC() as time_1;
  components new TimerMilliC() as time_2;
  components new TempHumLumSensorC();
  components ActiveMessageC;
  components new AMSenderC(AM_SEND_MSG);
  components new AMReceiverC(AM_SEND_MSG);
  
  // For printing
  components SerialStartC; //Comment this line when using tossim.
  components SerialPrintfC; //Comment this line when using tossim.

  //Boot interface
  App.Boot -> MainC.Boot;

  //Timer interface
  App.TempTimer -> temp_t;
  App.HumTimer -> hum_t;
  App.LumTimer -> lum_t;
  App.Timer0 -> time_0;
  App.Timer1 -> time_1;
  App.Timer2 -> time_2;
	
  //Sensor read
  App.TempRead -> TempHumLumSensorC.TempRead;
  App.HumRead -> TempHumLumSensorC.HumRead;
  App.LumRead -> TempHumLumSensorC.LumRead;

  //Radio Control
  App.SplitControl -> ActiveMessageC;
  App.AMSend -> AMSenderC;
  App.Packet -> AMSenderC;
  App.Receive -> AMReceiverC;
}

#include "Timer.h"
#include "LightWeight.h"
#include "printf.h" //Comment this line when using Tossim.

module LightWeightC {

  uses {
  	// Interface for booting.
	interface Boot;

	// Interface for communication.
	interface SplitControl;
	interface Packet;
    interface AMSend;
    interface Receive;

    // Interface for Timers.	
    interface Timer<TMilli> as TempTimer;
	interface Timer<TMilli> as HumTimer;
	interface Timer<TMilli> as LumTimer;
	interface Timer<TMilli> as Timer0;
	interface Timer<TMilli> as Timer1;
	interface Timer<TMilli> as Timer2;

	// Interface for 
	interface Read<uint16_t> as TempRead;
	interface Read<uint16_t> as HumRead;
	interface Read<uint16_t> as LumRead;

  }

} implementation {

  message_t packet;
  message_t queued_packet;

  // This is for the 'Stop & Wait' protocol. 
  uint8_t connack_flag = 0;
  uint8_t suback_flag = 0;
  uint8_t retransmission_con = 1;
  uint8_t retransmission_sub = 1;
  uint16_t timeouts[7] = {1000, 2000, 4000, 8000, 16000, 32000, 64000}; // Timeouts in milli seconds.
  uint16_t time_delays[8]={61,173,267,371,479,583,689,795}; //Time delay in milli seconds.
  uint16_t sub_type[8] = {1,2,3,2,1,2,3,2}; // Modify here to change the subscription of the nodes.
  uint16_t queue_addr;

  // PANC's dashboard. List of nodes connected to the PANC and what topic are they subscribed to.
  // The rows are for the nodes and the columns represent, in order: 
  // "Connected (0/1)" where 0: not connected and 1: connected. 
  // "Subscribed (0/1/2/3)" where 0: not subscribed to any topics, 1: subscribed to temperature, 2: subscribed to humidity and 3: subscribed to luminosity.  
  int matrix[ROWS][COLS] = {0};
  // For the generate_send functions.

  bool generate_send (uint8_t type, uint8_t subtype, uint16_t source, uint16_t destination, uint16_t data);
  void sendData(uint16_t address, message_t* packet);

  // ----------------------------------------------------

  bool generate_send (uint8_t type, uint8_t subtype, uint16_t source, uint16_t destination, uint16_t data){
  /*
  * 
  * Function to be used when performing the send after the receive message event.
  * It store the packet and address into a global variable and start the timer execution to schedule the send.
  * It allow the sending of only one message for each REQ and REP type
  * @Input:
  *		address: packet destination address
  *		packet: full packet to be sent (Not only Payload)
  *		type: payload message type
  *
  * MANDATORY: DO NOT MODIFY THIS FUNCTION
  */
  	if (call Timer2.isRunning()){
		return FALSE;
  	}else{
  		lightweight_msg_t* mess = (lightweight_msg_t*)(call Packet.getPayload(&packet, sizeof(lightweight_msg_t)));
	  	if (mess == NULL) {
			return TRUE;
	  	}
  		if (type == 1){
	  		mess->type = type;
		  	mess->source = source;
			mess->source = subtype;
		  	mess->destination = destination;
	  		call Timer2.startOneShot(time_delays[TOS_NODE_ID-1]);
	  		queue_addr = destination;
	  	}else if (type == 2){
	  		mess->type = type;
		  	mess->source = source;
			mess->source = subtype;
		  	mess->destination = destination;
	  		call Timer2.startOneShot(time_delays[TOS_NODE_ID-1]);
	  		queue_addr = destination;
	  	}else if (type == 3){
	  		mess->type = type;
		  	mess->subtype = subtype;
		  	mess->source = source;
		  	mess->destination = destination;
	  		call Timer2.startOneShot(time_delays[TOS_NODE_ID-1]);
	  		queue_addr = destination;
	  	}else if (type == 4){
	  		mess->type = type;
		  	mess->subtype = subtype;
		  	mess->source = source;
		  	mess->destination = destination;
	  		call Timer2.startOneShot(time_delays[TOS_NODE_ID-1]);
	  		queue_addr = destination;
	  	}else if (type == 5){
	  		mess->type = type;
		  	mess->subtype = subtype;
		  	mess->source = source;
		  	mess->destination = destination;
		  	mess->data = data;
	  		call Timer2.startOneShot(time_delays[TOS_NODE_ID-1]);
	  		queue_addr = destination;
	  	}
  	}
  	return TRUE;
  }

  event void Timer2.fired() {
  	/*
  	* Timer triggered to perform the send.
  	* MANDATORY: DO NOT MODIFY THIS FUNCTION
  	*/
  	dbg("timer","Timer2 for handling the sending of the packets fired at %s.\n", sim_time_string());
  	sendData(queue_addr, &packet);
  }

  void sendData(uint16_t address, message_t* packet){
	  dbg("radio_pack","Preparing the message... \n");
	  if(call AMSend.send(address, packet, sizeof(lightweight_msg_t)) == SUCCESS){
	     dbg("radio_send", "Packet passed to lower layer successfully!\n");
	     dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength(packet));
	     dbg_clear("radio_pack","\t Payload Sent\n" );
  	}
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
      dbg("boot","Application booted on node %u.\n", TOS_NODE_ID);
      call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
    if(err == SUCCESS) {
    	dbg("radio", "Radio on!\n");

    	// Send a connection message to the PANC. The PANC has ID = 9.

    	if(TOS_NODE_ID != 9){
			generate_send(1, 0, TOS_NODE_ID, 9, 0); // Sends the connection message.
			call Timer0.startOneShot(timeouts[0]); // Starts the timer before receiving the ACK.
			if(TOS_NODE_ID == 2){
				call TempTimer.startPeriodic(5000); //Modify here for different time periods.
			}else if(TOS_NODE_ID == 3){
				call HumTimer.startPeriodic(10000);
			}else if(TOS_NODE_ID == 7){
				call LumTimer.startPeriodic(15000);
			}
		}
    } else{
		//dbg for error
		call SplitControl.start();
    }
  }

  event void SplitControl.stopDone(error_t err){}

  //***************** MilliTimer interface ********************//
  event void Timer0.fired() {
  	//Handles the re-transmission of the connection message in case of a missing ACK or loss of the packet.
  	if((retransmission_con < 8) && (connack_flag == 0)){ // Maximum 7 re-transmissions before we discard the packet.
  		dbg("timer","Timer0 for handling 'CONNECTION' re-transmissions fired at %s.\n", sim_time_string());
  		generate_send(1, 0, TOS_NODE_ID, 9, 0); // We send the packet again. 
  		call Timer0.startOneShot(timeouts[retransmission_con-1]); // For every following re-transmission, we increase the T_0 value.
  		retransmission_con++;
  	} else {
  		retransmission_con = 1;
  	}
  }
  event void Timer1.fired() {
  	//Handles the re-transmission of the subscription message in case of a missing ACK or loss of the packet.
  	if((retransmission_sub < 8) && (suback_flag == 0)){ // Maximum 7 re-transmissions before we discard the packet.
  		dbg("timer","Timer1 for handling 'SUBSCRIPTION' re-transmissions fired at %s.\n", sim_time_string());
  		generate_send(3, sub_type[TOS_NODE_ID-1], TOS_NODE_ID, 9, 0); // We send the packet again.
  		call Timer1.startOneShot(timeouts[retransmission_sub-1]); // For every following re-transmission, we increase the T_0 value.
  		retransmission_sub++;
  	} else {
  		retransmission_sub = 1;
  	}
  }

  event void TempTimer.fired() {
  	dbg("timer","Temperature timer fired at %s.\n", sim_time_string());
	call TempRead.read();
  }

  event void HumTimer.fired() {
  	dbg("timer","Humidity timer fired at %s.\n", sim_time_string());
	call HumRead.read();
  }

  event void LumTimer.fired() {
  	dbg("timer","Luminosity timer fired at %s.\n", sim_time_string());
	dbg("radio", "Problem is here! \n");
	call LumRead.read();
  }

  //************************* Read interface **********************//
  event void TempRead.readDone(error_t result, uint16_t data) {
	double temp = ((double)data/65535)*100;
	dbg("temp","temp read done %f\n",temp);
	generate_send(5, 1, TOS_NODE_ID, 9, temp);
  }

  event void HumRead.readDone(error_t result, uint16_t data) {
	double hum = ((double)data/65535)*100;
	dbg("hum","hum read done %f\n",hum);
	generate_send(5, 2, TOS_NODE_ID, 9, hum);
  }

  event void LumRead.readDone(error_t result, uint16_t data) {
	double lum = ((double)data/65535)*100;
	dbg("lum","lum read done %f\n",lum);
	generate_send(5, 3, TOS_NODE_ID, 9, lum);
  }

  event void AMSend.sendDone(message_t* buf, error_t error) {
    if (&packet == buf && error == SUCCESS) {
      dbg("radio_send", "Packet sent...");
      dbg_clear("radio_send", " at time %s \n", sim_time_string());
    }
    else{
      dbgerror("radio_send", "Send done error!");
    }
  }

event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {

    if (len != sizeof(lightweight_msg_t)) {return bufPtr;}
    else {
      lightweight_msg_t* mess = (lightweight_msg_t*)payload;
      
	  dbg("radio_rec", "Received packet at time %s\n", sim_time_string());
      dbg("radio_pack"," Payload length %hhu \n", call Packet.payloadLength( bufPtr ));
      dbg("radio_pack", ">>>Pack \n");
      dbg_clear("radio_pack","\t\t Payload Received\n" );
      dbg_clear("radio_pack", "\t\t type: %hhu \n ", mess->type);
      dbg_clear("radio_pack", "\t\t subtype: %hhu \n ", mess->subtype);
      dbg_clear("radio_pack", "\t\t source: %hhu \n ", mess->source);
      dbg_clear("radio_pack", "\t\t destination: %hhu \n ", mess->destination);
	  dbg_clear("radio_pack", "\t\t data: %hhu \n", mess->data);

	  // In case we receive a CONNECT message.
	  if(mess->type == 1){ // Only client nodes send a CONNECT message so we can directly send a CONNACK back.
	  	dbg("radio_rec", "Received connect message! %s\n", sim_time_string());
	  	matrix[((int)mess->source) - 1][0] = 1; // 1 means it is positive. Otherwise, 0 means it is not connected yet.
	  	generate_send(2, 0, TOS_NODE_ID, mess->source, 0); // Checks the source address and sends back a CONNACK to this address.
	  } else if (mess->type == 2){ // In case we receive a CONNACK message. We validate the connack_flag. 
	  	connack_flag = 1; // The node client is officialy connected to the PANC.
	  	dbg("radio_rec", "Received connack message! %s\n", sim_time_string());
	  	generate_send(3, sub_type[TOS_NODE_ID-1], TOS_NODE_ID, 9, 0);//After connection, the client node sends a SUBSCRIBE message with its topic to PANC.
	  	call Timer1.startOneShot(timeouts[0]);
	  } else if (mess->type == 3){ // In case we receive a SUBSCRIBE message. We update the node client's subscription.
	  	matrix[((int)mess->source) - 1][1] = mess->subtype;
	  	dbg("radio_rec", "Received subscribe message! %s\n", sim_time_string());
	  	generate_send(4, mess->subtype, TOS_NODE_ID, mess->source, 0); // We send a SUBACK. 
	  } else if (mess->type == 4){ // In case we receive a SUBACK message. 
	  	suback_flag = 1;
	  	dbg("radio_rec", "Received suback message! %s\n", sim_time_string());
	  } else if (mess->type == 5){ // In case we receive a PUBLISH message. Send data to all subscribed nodes of that topic.
	  	if(TOS_NODE_ID == 9){ // If the node is the PANC that receives the PUBLISH message.
	  		int i;
	  		dbg("radio_rec", "The PANC received the publish message! %s\n", sim_time_string());
	  		if(mess->subtype == 1){ //-----------Comment those lines when using tossim.
  				printf("Temperature my value: %u\n", mess->data);
  				printfflush();
	  		} else if(mess->subtype == 2){
	  			printf("Humidity my value: %u\n", mess->data);
	  			printfflush();
			} else if(mess->subtype == 3){
	  			printf("Luminosity my value: %u\n", mess->data);
	  			printfflush();
	  		} //------------

		  	for(i = 0; i < ROWS; i++){
		  		if(matrix[i][1] == mess->subtype){ // Elements of the matrix that are equal to 0 are not considered because the subtype goes: 1, 2 and 3.
		  			dbg("radio", "PANC sends a PUBLISH message to %d\n", (i+1));
		  			generate_send(5, mess->subtype, 9, (i+1), mess->data);
		  		}
		  	}
	  	}else{ // In case it is the other nodes.
			dbg("radio_rec", "The following node client received the publish message: %s\n", TOS_NODE_ID);
			dbg("radio_rec", "The subtype of the message is the following one: %hhu \n", mess->subtype);
			dbg("radio_rec", "The value of the message is the following one: %hhu\n", mess->data);
		}
	  }
      return bufPtr;
    }
    {
      dbgerror("radio_rec", "Receiving error \n");
    }
  }
}
#include <Timer.h>
#include "BlinkToRadio.h"
/**
*
*	Abdul Al-Faraj
*	110149637
*	Computer Networks - Coursework 1
**/

//interfaces declaration 
module BlinkToRadioC {
	uses {
		interface Boot;
		interface SplitControl as RadioControl;

		interface Leds;
		interface Timer<TMilli> as Timer0;
		interface Timer<TMilli> as Timer1;

		interface Packet;
		interface AMPacket;
		interface AMSendReceiveI;
	}
}

//variables and fields declration 
implementation {
	uint16_t counter = 1;
	message_t sendMsgBuf;
	message_t ackMsgBuf;
	message_t* copyMsg = &sendMsgBuf; // initially points to sendMsgBuf
	message_t* sendMsg = &sendMsgBuf; // initially points to sendMsgBuf
	message_t* ackMsg = &ackMsgBuf; //initially points to ackMsgBuf
	bool ackRecieved = TRUE; // for step number 7
	uint8_t sendSq = 0;
	uint8_t recieveSq = 0;
	message_t recievedMsg;

	//boot event
	event void Boot.booted() {
		call RadioControl.start();
		call Timer0.startPeriodic(500);
	}

	event void RadioControl.startDone(error_t error) {
		if (error == SUCCESS) {
			call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
		}
	}

	event void RadioControl.stopDone(error_t error) {};
	
	//timer 0, send the message if it is acknowledge, and calls timer 1.
	//this timer lives for 500 milli seconds
	event void Timer0.fired() {

		//if the message is acknowledged, send the next message and wait
		// the initial start is that the message will be aknowloedge at first
		if(ackRecieved) { 

			BlinkToRadioMsg* btrpkt;
			BlinkToRadioMsg* btCpkt;

			call AMPacket.setType(sendMsg, AM_BLINKTORADIO);
			call AMPacket.setDestination(sendMsg, DEST_ECHO);
			call AMPacket.setSource(sendMsg, TOS_NODE_ID);
			call Packet.setPayloadLength(sendMsg, sizeof(BlinkToRadioMsg));

			btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(sendMsg, sizeof (BlinkToRadioMsg)));

			btrpkt->type = TYPE_DATA;
			btrpkt->seq = sendSq; //gives 0 or 1
			btrpkt->nodeid = TOS_NODE_ID;
			btrpkt->counter = counter;

			//create a copy
			call AMPacket.setType(copyMsg, AM_BLINKTORADIO);
			call AMPacket.setDestination(copyMsg, DEST_ECHO);
			call AMPacket.setSource(copyMsg, TOS_NODE_ID);
			call Packet.setPayloadLength(copyMsg, sizeof(BlinkToRadioMsg));

			btCpkt = (BlinkToRadioMsg*)(call Packet.getPayload(copyMsg, sizeof (BlinkToRadioMsg)));

			btCpkt->type = btrpkt->type;
			btCpkt->seq = btrpkt->seq; //gives 0 or 1
			btCpkt->nodeid = btrpkt->nodeid;
			btCpkt->counter = btrpkt->counter;

			// send message and store returned pointer to free buffer for next message
			// once the message is send, it will be lost hence we created the third copy in timer1
			sendMsg = call AMSendReceiveI.send(sendMsg);
			
			//set ack to false and increase counter and send squence
			ackRecieved = FALSE;
			counter++;
			sendSq = (sendSq+1)%2; //set the sequence number to 1 or 0s
			
			//call timer1 to send mesg if ack not recieved.
			call Timer1.startOneShot(5000);
		}
	}

	//this event is to send another copy of the message in case message is not acknowledge
	// I choose to delay this timer by 5 seconds. It preforms will with other times, such as 1 second.
	//however, for the sake of the analysis, 5 seconds seem a good choise.
	event void Timer1.fired() {

		if(ackRecieved==FALSE) {

			BlinkToRadioMsg* btrpkt;
			BlinkToRadioMsg* btCpkt;

			call AMPacket.setType(sendMsg, AM_BLINKTORADIO);
			call AMPacket.setDestination(sendMsg, DEST_ECHO);
			call AMPacket.setSource(sendMsg, TOS_NODE_ID);
			call Packet.setPayloadLength(sendMsg, sizeof(BlinkToRadioMsg));

			btCpkt = (BlinkToRadioMsg*)(call Packet.getPayload(copyMsg, sizeof (BlinkToRadioMsg)));
			btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(sendMsg, sizeof (BlinkToRadioMsg)));

			btrpkt->type = btCpkt->type;
			btrpkt->seq = btCpkt->seq; //gives 0 or 1
			btrpkt->nodeid = btCpkt->nodeid;
			btrpkt->counter = btCpkt->counter;

			sendMsg = call AMSendReceiveI.send(sendMsg);
			//timer will call itslef in case of message lost again!!!
			call Timer1.startOneShot(5000);
		}
	}

	//this event is behaves as the receiver.
	// there are two parts, one part behaves as receiver host and send host.
	//receiver host, when we recieve data, we send an acknowledgement.
	//sender host is when we receive an acknowledgement we send the next data.
	event message_t* AMSendReceiveI.receive(message_t* msg) {
		uint8_t len = call Packet.payloadLength(msg);
		BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(msg, len));

		//Reciever Host
		if ( btrpkt->type == TYPE_DATA )
		{

			BlinkToRadioMsg* btApkt;
			call Leds.set(btrpkt->counter);
			call AMPacket.setType(ackMsg, AM_BLINKTORADIO);
			call AMPacket.setDestination(ackMsg, DEST_ECHO);
			call AMPacket.setSource(ackMsg, TOS_NODE_ID);
			call Packet.setPayloadLength(ackMsg, sizeof(BlinkToRadioMsg));

			btApkt = (BlinkToRadioMsg*)(call Packet.getPayload(ackMsg, sizeof (BlinkToRadioMsg)));
			//counter++;
			btApkt->type = TYPE_ACK;
			btApkt->seq = btrpkt->seq;
			btApkt->nodeid = TOS_NODE_ID;
			btApkt->counter = btrpkt->counter;
			ackMsg = call AMSendReceiveI.send(ackMsg);
			// send message and store returned pointer to free buffer for next message
		
		//Sender host
		} else if (btrpkt->type == TYPE_ACK && recieveSq == btrpkt->seq ) {

			//ackMsg = call AMSendReceiveI.send(ackMsg);
			ackRecieved = TRUE;
			recieveSq = ( recieveSq + 1 ) % 2;
			//stop timer 1 here
			call Timer1.stop();

		}

		return msg;
	}
}


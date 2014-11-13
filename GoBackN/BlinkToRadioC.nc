#include <Timer.h>
#include "BlinkToRadio.h"
/**
*
*	Author: 	Abdul Al-Faraj
*	Student ID: 110149637
*	Computer Networks - Coursework II : Protocol GO Back N
*	
*	10/05/2013 - School of Electronic and Computer Engineering 
*
**/

//interfaces declaration 
module BlinkToRadioC {
	uses {
		interface Boot;
		interface SplitControl as RadioControl;

		interface Leds;
		interface Timer<TMilli> as Timer0;
		interface Timer<TMilli> as Timer1;
		interface Timer<TMilli> as Timer2;
		interface Timer<TMilli> as Timer3;
		interface Timer<TMilli> as Timer4;
		interface Timer<TMilli> as Timer5;
		interface Timer<TMilli> as Timer6;
		interface Timer<TMilli> as Timer7;		
		
		interface Packet;
		interface AMPacket;
		interface AMSendReceiveI;
	}
}

//variables and fields declaration
implementation {
	
	
	message_t sendMsgBuf[8];
	message_t* message[8];
	
	message_t copyMsgBuf[8];
	message_t* copyMsg[8];
	
	message_t ackMsgBuf;
	message_t* ackMsg0 = &ackMsgBuf; //initially points to ackMsgBuf
	
	message_t recievedMsg;
	
	uint8_t sendSq = 0;
	uint16_t msgsLimit = 0;
	uint8_t recieveSq = 0;
	uint8_t ackCounter = 0;
	uint16_t counter = 0;		// Check when testing!!!!
	uint8_t WindowSize = 3; 	// initially window size 0-3
	uint8_t N = 0;				// current window size 
	uint8_t expectedSq = 0;
	
	// booleans array to keep track of acknowledged messages.
	bool acks[8];

	//prototypes
	void resend_MSG(uint8_t);
	task void sendMsg0_Task();

	
	/**
	*
	*Resend the lost messages through this function
	*it takes an int for parameter and it send it and start the timer for it
	*/
	void resend_MSG(uint8_t index){
				
		if(acks[index]==FALSE){		
			BlinkToRadioMsg* btrpkt0;
			BlinkToRadioMsg* btCpkt0;
			
			call AMPacket.setType(message[index], AM_BLINKTORADIO);
			call AMPacket.setDestination(message[index], DEST_ECHO);
			call AMPacket.setSource(message[index], TOS_NODE_ID);
			call Packet.setPayloadLength(message[index], sizeof(BlinkToRadioMsg));
	
			btCpkt0 = (BlinkToRadioMsg*)(call Packet.getPayload(copyMsg[index], sizeof (BlinkToRadioMsg)));
			btrpkt0 = (BlinkToRadioMsg*)(call Packet.getPayload(message[index], sizeof (BlinkToRadioMsg)));
	
			btrpkt0->type = btCpkt0->type;
			btrpkt0->seq = btCpkt0->seq; //gives 0 or 1
			btrpkt0->nodeid = btCpkt0->nodeid;
			btrpkt0->counter = btCpkt0->counter;
	
			message[index] = call AMSendReceiveI.send(message[index]);
		}
		//start timer for the sent message again, in case of it got lost
			if ( index ==0){
				call Timer0.startOneShot(1000);	
			}else if (index ==1 ){
				call Timer1.startOneShot(1000);	
			}else if ( index == 2){
				call Timer2.startOneShot(1000);	
			}else if (index == 3){
				call Timer3.startOneShot(1000);	
			}else if (index == 4){
				call Timer3.startOneShot(1000);	
			}else if (index == 5){
				call Timer3.startOneShot(1000);	
			}else if (index == 6){
				call Timer3.startOneShot(1000);	
			}else if (index == 7){
				call Timer3.startOneShot(1000);	
			}
	}
	
	
	event void RadioControl.startDone(error_t error) {
		int i;
		
		// to iniate the buffers and the messages
		for ( i=0; i<8;i++){
			message[i]=&sendMsgBuf[i];
			copyMsg[i]=&copyMsgBuf[i];
		}
	
		if (error == SUCCESS) {
			post sendMsg0_Task();
		}
	}
	
	
	//boot event
	event void Boot.booted() {
		call RadioControl.start();
	}

	event void RadioControl.stopDone(error_t error) {/****/};
	

	/**
	**
	**We have 8 timers, at which only 4 AT MAX will be on at one time
	**
	**/
	event void Timer0.fired() {
		resend_MSG(0);
	}
	event void Timer1.fired() {
		resend_MSG(1);
	}
	event void Timer2.fired() {
		resend_MSG(2);
	}
	event void Timer3.fired() {	
		resend_MSG(3);
	}
	event void Timer6.fired(){
		resend_MSG(4);
	}
	event void Timer5.fired(){
		resend_MSG(5);
	}
	event void Timer4.fired(){
		resend_MSG(6);
	}
	event void Timer7.fired(){
		resend_MSG(7);
	}
	

	task void sendMsg0_Task(){
		/**
		 * Send 4 Messages before blocking
		 * then increase the window size by 1 everytime we get vaild acknowledgment
		 */
			
				while(N <= WindowSize){
			

					BlinkToRadioMsg* btrpkt0; 	// message
					BlinkToRadioMsg* btCpkt0;	//copy of message
					
					//create the message and send it
					call AMPacket.setType(message[sendSq], AM_BLINKTORADIO);
					call AMPacket.setDestination(message[sendSq], DEST_ECHO);
					call AMPacket.setSource(message[sendSq], TOS_NODE_ID);
					call Packet.setPayloadLength(message[sendSq], sizeof(BlinkToRadioMsg));

					btrpkt0 = (BlinkToRadioMsg*)(call Packet.getPayload(message[sendSq], sizeof (BlinkToRadioMsg)));

					btrpkt0->type = TYPE_DATA;
					btrpkt0->seq = sendSq; //gives 0 to 7
					btrpkt0->nodeid = TOS_NODE_ID;
					btrpkt0->counter = counter;

					
					//the copy of the message
					call AMPacket.setType(copyMsg[sendSq], AM_BLINKTORADIO);
					call AMPacket.setDestination(copyMsg[sendSq], DEST_ECHO);
					call AMPacket.setSource(copyMsg[sendSq], TOS_NODE_ID);
					call Packet.setPayloadLength(copyMsg[sendSq], sizeof(BlinkToRadioMsg));

					btCpkt0 = (BlinkToRadioMsg*)(call Packet.getPayload(copyMsg[sendSq], sizeof (BlinkToRadioMsg)));

					btCpkt0->type = btrpkt0->type;
					btCpkt0->seq = btrpkt0->seq; //gives 0 or 1
					btCpkt0->nodeid = btrpkt0->nodeid;
					btCpkt0->counter = btrpkt0->counter;

					// send message and store returned pointer to free buffer for next message
					// once the message is send, it will start it's timer
					message[sendSq] = call AMSendReceiveI.send(message[sendSq]);

					//check which message sequence we sent and start the timer for it
						if ( sendSq ==0){
							call Timer0.startOneShot(1000);	
						}else if (sendSq ==1 ){
							call Timer1.startOneShot(1000);	
						}else if ( sendSq == 2){
							call Timer2.startOneShot(1000);	
						}else if (sendSq == 3){
							call Timer3.startOneShot(1000);	
						}else if (sendSq == 4){
							call Timer3.startOneShot(1000);	
						}else if (sendSq == 5){
							call Timer3.startOneShot(1000);	
						}else if (sendSq == 6){
							call Timer3.startOneShot(1000);	
						}else if (sendSq == 7){
							call Timer3.startOneShot(1000);	
						}
						
					acks[sendSq]=FALSE;	
					counter++;
					sendSq = (sendSq+1)%7; // give us a rang between 0-7
					N++;
			}
			post sendMsg0_Task();
	}
	
	//this event behaves as the receiver.
	// there are two parts, one part behaves as receiver host and send host.
	//receiver host, when we receive data, we send an acknowledgement.
	//sender host is when we receive an acknowledgement we send the next data.
	event message_t* AMSendReceiveI.receive(message_t* msg) {
		uint8_t len = call Packet.payloadLength(msg);
		BlinkToRadioMsg* btrpkt0 = (BlinkToRadioMsg*)(call Packet.getPayload(msg, len));

		//Receiver Host
		if ( btrpkt0->type == TYPE_DATA ){
			
				
			BlinkToRadioMsg* btApkt;
			call Leds.set(btrpkt0->counter);
			call AMPacket.setType(ackMsg0, AM_BLINKTORADIO);
			call AMPacket.setDestination(ackMsg0, DEST_ECHO);
			call AMPacket.setSource(ackMsg0, TOS_NODE_ID);
			call Packet.setPayloadLength(ackMsg0, sizeof(BlinkToRadioMsg));

			btApkt = (BlinkToRadioMsg*)(call Packet.getPayload(ackMsg0, sizeof (BlinkToRadioMsg)));
			
			if(btrpkt0->seq == expectedSq){
				//if we recieve the correct packet, send a new one
				btApkt->type = TYPE_ACK;
				btApkt->seq = btrpkt0->seq;
				btApkt->nodeid = TOS_NODE_ID;
				btApkt->counter = btrpkt0->counter;
		
				
				
				
			}else{
				//if the message doesn't have the same expected squence, then return it with
				//the last vaild squence
				btApkt->type = TYPE_ACK;
				btApkt->seq = expectedSq;
				btApkt->nodeid = TOS_NODE_ID;
				btApkt->counter = expectedSq;
			}
			
			//Send the message
			ackMsg0 = call AMSendReceiveI.send(ackMsg0);
			
		//Sender host
		} else if (btrpkt0->type == TYPE_ACK) {

			//Check if the expect squence is the same as the echo squance
			if(btrpkt0->seq == expectedSq) 
					expectedSq =( expectedSq + 1 )% 7;
				
				
				//check what is the sequence then stop the timer and free that certain slot
					if(btrpkt0->seq == 0){
						call Timer0.stop();
						acks[0]=TRUE;

					}else if(btrpkt0->seq == 1){
						acks[1]=TRUE;
						call Timer1.stop();
						
					}else if(btrpkt0->seq == 2){
						acks[2]=TRUE;
						call Timer2.stop();
					
					}else if(btrpkt0->seq == 3){
						acks[3]=TRUE;						
						call Timer3.stop();

					}else if(btrpkt0->seq == 4){
						acks[4]=TRUE;
						call Timer4.stop();

					}else if(btrpkt0->seq == 5){
						acks[5]=TRUE;
						call Timer5.stop();

					}else if(btrpkt0->seq == 6){	
						acks[6]=TRUE;
						call Timer6.stop();						
					}else if(btrpkt0->seq == 7){
						acks[7]=TRUE;
						call Timer7.stop();
					}
					
					//increase the window size and re-post the task
					WindowSize++;
					post sendMsg0_Task();
		} 
		return msg;		
	}
}


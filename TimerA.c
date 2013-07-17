#include "TimerA.h"

//global vars
#define ON 1
#define OFF 0

volatile uint16_t TimerA_codesToSend = 0, TimerA_waits = 0, TimerA_tvFrequency = 0, TimerA_usOnTime = 0, TimerA_usOffTime = 0;
volatile uint8_t TimerA_state = STATE_DONE, onOffState = ON;

//interrupts every 10us
#pragma vector=TIMER0_A0_VECTOR
__interrupt void TimerA_isrCompare(void)
{
	   if (TimerA_state == STATE_EXECUTE_CODE)
	   {
	       if (onOffState == ON)
	       {
		      //decrement every ten us
			  --TimerA_usOnTime;
			  if (TimerA_usOnTime == 0)
			  {
				  IR_LED_DIR &= ~(1 << IR_LED);
				  onOffState = OFF;
				  CircularBuffer_getWord(&TimerA_usOffTime);

				  if (TimerA_usOffTime == 0)
				  {
					  TimerA_state = STATE_DONE;
					  onOffState = ON;
				  }
				  return;
			  }
	       }
		   else if (onOffState == OFF)
		   {
			   --TimerA_usOffTime;
			   if (TimerA_usOffTime == 0)
			   {
				   IR_LED_DIR |= (1 << IR_LED);
				   onOffState = ON;
				   CircularBuffer_getWord(&TimerA_usOnTime);
			   }
		   }
       }
}



/*
 			   --TimerA_codesToSend;
			   //another way to exit
			   if (TimerA_codesToSend == 0)
			   {
                  IR_LED_DIR &= ~(1 << IR_LED);
				  P1OUT |= (1 << RED_LED);
				  TA1CCR0 = 0;
			      TimerA_state = STATE_DONE;
			      onOffState = ON;
			   }

 */

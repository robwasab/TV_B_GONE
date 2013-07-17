/*
 * CHander.c
 *
 *  Created on: May 1, 2013
 *      Author: Robby Tong
 */

#include "CHandler.h"

uint16_t main(void) {
	FATFS fatfs;

	CircularBuffer_init("SD", &fatfs);

	TimerA_state = STATE_DONE;
    uint16_t b;
	//main loop
	while (1)
    {
	   int res = CircularBuffer_getWordsRemaining();
	   if (!res) { break; }

       if (TimerA_state == STATE_DONE)
       {
		   CircularBuffer_getWord(&b);
		   if (b == 0xffff)
		   {

			   CircularBuffer_getWord(&b);
			   if (b == 0xffff)
			   {

				  //put the frequency into a variable so I can use it for later
				  CircularBuffer_getWord(&TimerA_tvFrequency);
				  printInt((uint8_t *)&TimerA_tvFrequency, sizeof(TimerA_tvFrequency));

				  //get the divider, use variable b as a dummy
				  CircularBuffer_getWord(&b);
                  printInt((uint8_t *)&b, sizeof(b));

				  //clear the current divider for prescale of 1
				  TA1CTL &= ~(ID0 | ID1);

				  CircularBuffer_getWord(&TimerA_codesToSend);
				  printInt((uint8_t *)&TimerA_codesToSend, sizeof(TimerA_codesToSend));

				  //wait some time before sending the next code???

				  //The timer isr will change the state back to STATE_DONE now
                  TA1CCR0 = TimerA_tvFrequency;
                  IR_LED_DIR |= (1 << IR_LED);

                  CircularBuffer_getWord(&TimerA_usOnTime);
				  TimerA_state = STATE_EXECUTE_CODE;
			   }
		   }
       }
   res = CircularBuffer_task();
   }
   TimerA_state = STATE_DONE;
   TA1CCR0 = 0;
   print("DONE!\n\rWaits: ");
   printInt((uint8_t *)&TimerA_waits, 2);
   while(1);
   return 0xaa55;
}

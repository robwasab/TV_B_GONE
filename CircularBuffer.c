/*
 * CircularBuffer.c
 *
 *  Created on: Jul 11, 2013
 *      Author: Robby Tong
 */
#include "CircularBuffer.h"

void die (		// Stop with dying message
	FRESULT rc	// FatFs return value
)
{
	switch (rc)
	{
	case 0:
		return;

	case 1:
		print("DISK ERROR");
	    break;
	case 2:
		print("NOT READY");
	    break;
	case 3:
		print("NO FILE");
	    break;
	case 4:
		print("NO PATH");
	    break;
	case 5:
		print("NOT OPENED");
	    break;
	case 6:
		print("NOT ENABLED");
	    break;
	case 7:
		print("NO FILE SYS");
	    break;
	}
	RET();

	while(1);
   }

#define STATE_FILL_DEQUEUED 0
#define STATE_FILLED_DEQUEUED 1
#define STATE_SOURCE_EXAUSTED 2
#define SIZE 60

uint16_t buf0[SIZE];
uint16_t buf1[SIZE];

//pointer to the buffer that timer interrupts will use
uint16_t * queued;

//pointer to the buffer that needs to be filled
uint16_t * dequeued;

uint8_t offset;
uint16_t wordsAvailable;

uint8_t state;

void CircularBuffer_init(char * file, FATFS * fatfs)
{

    //fill the buffer
	FRESULT rc = pf_mount(fatfs);
	if (rc) die(rc);

	rc = pf_open(file);
    if (rc) die(rc);

    print("SD card initialized, opened ");
    print(file);
    RET();

    WORD br;
    rc = pf_read(buf0, sizeof(buf0), &br);
    die(rc);

    //set breakpoint see if dissasembly is shift right
    wordsAvailable = br >> 1;   //div by two

    rc = pf_read(buf1, sizeof(buf1), &br);
    die(rc);
    wordsAvailable += br >> 1;  //div by two

    offset = 0;
    //set the queued pointer to buf0
    queued = buf0;
    dequeued = buf1;
    state = STATE_FILLED_DEQUEUED;
}

uint16_t CircularBuffer_getWordsRemaining(void)
{
	return wordsAvailable;
}

int CircularBuffer_getWord(volatile uint16_t * ret)
{
	*ret = queued[offset];
	++offset;
    --wordsAvailable;

    if (offset >= SIZE)
    {
       if (state == STATE_FILL_DEQUEUED)
       {
    	   //undo the changes so that the next time this is called
    	   //get the same effect
    	   --offset;
    	   ++wordsAvailable;
    	   //return with error
    	   ++TimerA_waits;
    	   return -1;
       }
       else if (state == STATE_SOURCE_EXAUSTED)
       {
    	   //undo the changes so that the next time this is called
    	   //get the same effect
    	   --offset;
    	   ++wordsAvailable;
    	   //return with error
    	   return -2;
       }
       else if (state == STATE_FILLED_DEQUEUED)
       {
          offset = 0;

          //swap the queued and dequeued buffers
          uint16_t * temp;
          temp = dequeued;
          dequeued = queued;
          queued = temp;
          state = STATE_FILL_DEQUEUED;
       }
    }
    return 0;
}

int CircularBuffer_task(void)
{
	if (state == STATE_SOURCE_EXAUSTED) return -1;

	if (state == STATE_FILL_DEQUEUED)
	{
	   WORD bytesRead;
	   FRESULT rc;
       rc = pf_read(dequeued, sizeof(uint16_t) * SIZE, &bytesRead);
       die(rc);

       if (bytesRead < (sizeof(uint16_t) * SIZE))
       {
    	   state = STATE_SOURCE_EXAUSTED;
       }

       //divide by two
       wordsAvailable += bytesRead >> 1;
       state = STATE_FILLED_DEQUEUED;
	}
	return 0;
}

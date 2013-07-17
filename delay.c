/*
 * delay.c
 *
 *  Created on: Jul 8, 2013
 *      Author: Robby Tong
 */
#include "delay.h"

//determined by trial and error, no serious math involved
void delay_us(uint32_t time)
{
	do {
		asm("nop");
	} while(--time);
}

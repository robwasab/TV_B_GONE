/*
 * TimerA.h
 *
 *  Created on: Jul 9, 2013
 *      Author: Robby Tong
 */

#ifndef TIMERA_H_
#define TIMERA_H_

#include "CHandler.h"

extern volatile uint16_t TimerA_codesToSend, TimerA_tvFrequency, TimerA_usOnTime, TimerA_usOffTime;
extern volatile uint8_t TimerA_state;
extern volatile uint16_t TimerA_waits;
#define STATE_DONE 0
#define STATE_EXECUTE_CODE 1
#endif /* TIMERA_H_ */

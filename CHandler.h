/*
 * CHander.h
 *
 *  Created on: May 1, 2013
 *      Author: Robby Tong
 */

#ifndef CHANDER_H_
#define CHANDER_H_

#include <stdint.h>
#include "msp430.h"
#include "USCI.h"
#include "pff.h"
#include "delay.h"
#include "TimerA.h"
#include "CircularBuffer.h"

#define print(s) USCI_printString(s)
#define printLine(s) USCI_printLine(s)
#define putchar(c) USCI_A_uartSend(c)
#define IR_LED_OUT P2OUT
#define IR_LED_SEL P2SEL
#define IR_LED_DIR P2DIR
#define IR_LED 0
#define SD_CARD 4
#define GREEN_LED 6
#define RED_LED 0
uint16_t main(void);
#endif /* CHANDER_H_ */

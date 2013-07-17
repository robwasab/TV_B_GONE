/*
 * USCI.h
 *
 *  Created on: Jun 20, 2013
 *      Author: Robby Tong
 */

#ifndef USCI_H_
#define USCI_H_
#include "CHandler.h"
/*
 * USCI_printString uses a generic byte output stream, define the output
 * communication function to be used here!
 */
#define GENERIC_OUTPUT(foo) USCI_A_uartSend(foo)
#define USCI_putChar(foo) USCI_A_uartSend(foo)
uint8_t USCI_B_spiXmit(uint8_t data);
void USCI_A_uartSend(uint8_t data);
uint8_t USCI_A_uartRecieve(void);
void USCI_printString(char * s);
void USCI_printLine(char * s);

void printInt(void * foo, uint8_t bytes);
#define RET() USCI_printString("\n\r")

#endif /* USCI_H_ */

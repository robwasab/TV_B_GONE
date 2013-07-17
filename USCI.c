#include "USCI.h"

/*
 * Uses USCI A module configured in UART mode
 * Initialization is done in main.asm in assembly code
 * @param data byte to send
 */
void USCI_A_uartSend(uint8_t data)
{
	while (UCBUSY & UCA0STAT);   //wait until the uart module isn't busy
	UCA0TXBUF = data;
}

/*
 * Uses USCI A module configured in UART mode
 * Initialization is done in main.asm in assembly code
 * @return byte from recieve buffer/register
 */
uint8_t USCI_A_uartRecieve(void)
{
	while (UCBUSY & UCA0STAT);   //wait until the uart module isn't busy
	return UCA0RXBUF;
}

/*
 * No suffix A or B because this is a generic function
 */
void USCI_printString(char * s)
{
	while(*s != '\0')
	{
		GENERIC_OUTPUT(*s);
		++s;
	}
}

void USCI_printLine(char * s)
{
	while(*s != '\0' || *s != '\n')
	{
		GENERIC_OUTPUT(*s);
		++s;
	}
}


void printNibble(uint8_t b)
{
	b &= 0x0f;
	if (b < 0x0a)
	{
		USCI_putChar(0x30 | b);
	}
	else
	{
		b -= 9;
		USCI_putChar(0x40 | b);
	}
}

void printInt(void * foo, uint8_t bytes)
{
	uint8_t * b = (uint8_t *) foo;
    bytes -= 1;
	USCI_printString("0x");
	do {
	   printNibble(b[bytes] >> 4);
	   printNibble(b[bytes]);
	}
	while (bytes--);
	RET();
}

/*
 * Uses USCI B module configured in SPI mode.
 * Initialization is done in main.asm in assembly code
 * @param data byte to send
 * @return byte from the recieve buffer
 */
uint8_t USCI_B_spiXmit(uint8_t data)
{
	//while (UCBUSY & UCB0STAT); //wait until the usci module isn't busy
	UCB0TXBUF = data;
	while (UCBUSY & UCB0STAT); //wait until the usci module finishes transmitting;
	return UCB0RXBUF;
}

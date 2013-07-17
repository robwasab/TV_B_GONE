/*
 * CircularBuffer.h
 *
 *  Created on: Jul 11, 2013
 *      Author: Robby Tong
 */

#ifndef CIRCULARBUFFER_H_
#define CIRCULARBUFFER_H_

#include "CHandler.h"

void die (FRESULT rc);
void CircularBuffer_init(char * file, FATFS * fatfs);
int CircularBuffer_getWord(volatile uint16_t * ret);
uint16_t CircularBuffer_getWordsRemaining();
int CircularBuffer_task(void);

#define CircularBuffer_slowGetWord(foo)  CircularBuffer_getWord(foo); if (CircularBuffer_task() < 0) continue

#endif /* CIRCULARBUFFER_H_ */

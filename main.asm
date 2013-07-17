;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
			.global GREEN_LED
			.global RED_LED
TX			.set 2
RX			.set 1

CLK			.set 5
MISO		.set 6
MOSI		.set 7
CS          .set 4

GREEN_LED	.set 6
RED_LED		.set 0
LEFT_BUTTON .set 3
BUTTON_3    .set 3
SEG_A		.set 0x01
SEG_B		.set 0x02
SEG_C		.set 0x04
SEG_D		.set 0x08
SEG_E		.set 0x10
SEG_F		.set 0x20
SEG_G		.set 0x40
SEG_UNIT_SEL	.set 0x80
;All the shift register pins are on P2
DS			.set 0x02
OE			.set 0x10
ST_CP		.set 0x04
SH_CP		.set 0x08

;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h","CHandler.h"     ; Include device header file

;-------------------------------------------------------------------------------
            ;.text                           ; Assemble into program memory
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section
            .retainrefs                     ; Additionally retain any sections
                                            ; that have references to current
                                            ; section
;-------------------------------------------------------------------------------
            .data
            .global SECONDS
            .global MICRO_SECONDS
            .global MILLI_SECONDS
            .global USCI_data

DISPLAY:	.word 0x0000
USCI_data:  .word 0x0000

			.text

            .global INIT

INIT:        mov.w   #__STACK_END,SP             ;Initialize stackpointer
StopWDT      mov.w   #WDTPW|WDTHOLD,&WDTCTL      ;Stop watchdog timer
             mov.b   &CALBC1_8MHZ,  &BCSCTL1     ;set up the DCO at 8MHZ, the cpu is already using DCO for MCLK
             bic.b   #SELS, &BCSCTL2             ;Make SCLK use DCO
             mov.b   &CALDCO_8MHZ,  &DCOCTL
PINS_INIT:   ;LED config
             mov.b   #(1 << RED_LED), &P1DIR ;green and red led are outputs
             mov.b   #(1 << RED_LED)   ,&P1OUT   ;turn off all pins on P1
             ;Button config
             ;Button is an input, therefor, P1DIR needs to be input
             ;Button should have a pull up resistor connected
             ;Button should have an interrupt generated on a falling edge
             bic     #(1 << BUTTON_3)  ,&P1DIR
             bis     #(1 << BUTTON_3)  ,&P1REN
             bis     #(1 << BUTTON_3)  ,&P1OUT
             bis     #(1 << BUTTON_3)  ,&P1IES   ;bit = 1 means high to low trans to fire interrupt
             mov.b   #(1 << BUTTON_3)  ,&P1IE    ;enable interrupts on BUTTON_3
             ;SHIFT Register config
             mov.b #(DS | OE | ST_CP | SH_CP), &P2DIR
             mov.b #0x00, &P2OUT

             ;Aux clock config
             ;Setup the LFXT using the 32..khz watch crystal
             ;SELMx = 11 to use LFXT1 as mclk
             ;enable everything, then clear the osc fault flag
             ;delay..
             ;is it enabled? yes->loop until it is cleared
;ACLK_INIT:   bis.b   #XT2OFF, &BCSCTL1   ;BCSCTL1 controls low/high freq mode, and ACLK divider!
             ;use 12pF caps for watch crystal says lab03
;             mov.b   #XCAP_3 , &BCSCTL3  ;BCSCTL3 controls the input clk into LFXT1 the watch crystal is 00 so its left blank, and the capacitance seen by oscillator

OSC_FAULT:   bic     #LFXT1OF, &BCSCTL3  ;clear the osc fault flag
             call    #Delay               ;wait some time
             bit     #LFXT1OF, &BCSCTL3  ;test the osc fault flag
                                         ;if zero, then no osc fault
             jne OSC_FAULT
             ;mov.b   #SELM_3, &BCSCTL2   ;BCSCTL2 controls MCLK source, divider for MCLK, SMCLK source and SMCLK divider

             ;Timer A config
             ;Configure for a period of 10us
             ;Will poll this timer in order to create a 10us Delay
             ;The TACCR0 CCIFG is automatically reset when interrupt is serviced (automatically)
TIMER_A0_INIT:mov.w   #TASSEL1|MC0 |ID_3, &TA0CTL   ;use ACLK,upmode
              mov.w   #0x0009, &TA0CCR0       ;10us
              mov.w   #CCIE, &TA0CCTL0        ;enable interrupt on compare with TACCR0


TIMER_A1_INIT:;OUTMOD bits need to be 100 for toggle mode
              ;use TBCCR0 to load the frequency value
              ;use ID0 ID1 bits on TBCTL to manipulate the divider
              ;ID0 and ID1 take up the bits 0x00C0
              mov.w  #MC0 | TASSEL1 | ID_3, &TA1CTL
              mov.w  #OUTMOD2, &TA1CCTL0
              mov.w  #0xffff, &TA1CCR0
              ;on P1.1 enable TA.0 output
              bis.b  #BIT0, &P2DIR
              bis.b  #BIT0, &P2SEL

             ;software reset the module -> UCSWRST
             ;initialize all the registers while UCSWRST = 1
             ;configure ports
             ;clear UCSWRST with bic
             ;enable interrupts
             ;Interrupt notes:
             ;   the two Universal Serial Communication Interface modules A and B share two interrupt vectors,
             ;   they share a common recieve and a common transmit interrupt vector.
UART_INIT:   mov.b   #UCSWRST, &UCA0CTL1   ;reset the module
             mov.b   #0x00, &UCA0CTL0      ;no parity, NA even/odd parity, LSB first, 8 bit data, one stop bit, UART mode, asynchronous
             bis.b   #UCSSEL1 | UCSSEL0, &UCA0CTL1   ;select SMCLK as the BRCLK. Also, UCRXEIE isn't set, erroneous characters are rejected from the UART and dropped
             ;configuring it for 9600 baud, from table 15-4 pg 435
             mov.b   #0x41, &UCA0BR0
             mov.b   #0x03, &UCA0BR1   ;UCBR0 and UCBR1 make up a 16 bit baud rate value
             mov.b   #UCBRS_2 | UCBRF_0, &UCA0MCTL
             ;todo: enable UART interrupts
             ;bis.b   #UCLISTEN, &UCA0STAT   ;loopback mode, byte sent should be a byte recieved
             ;Configuring Ports
             ;Pins are UCA0RXD = P1.1 and UCA0TXD = P1.2
             ;Setting up UCA0RXD:
             ;P1DIR.1 is set from USCI P1SEL.1 = 1 P1SEL2.1 = 1 all others zero
             ;P1DIR.2 is set from USCI P1SEL.2 = 1 P1SEL2.2 = 1 all others zero
             bis.b #(1 << TX) | (1 << RX), &P1SEL
             bis.b #(1 << TX) | (1 << RX), &P1SEL2
             bis.b #(1 << TX) , &P1DIR
             bic.b #(1 << RX) , &P1DIR
             bic.b   #UCSWRST, &UCA0CTL1

             ;Instructions on initializing USCI for SPI
             ;SET UCSWRST
             ;initialize all registers
             ;configure ports
             ;clear UCSWRST
             ;mode zero, phase and polarity are zero
SPI_INIT:    mov.b #UCSWRST, &UCB0CTL1			;enable reset
             mov.b #UCMST | UCSYNC | UCMSB | UCCKPH, &UCB0CTL0 	;master mode, synchronous mode
             bis.b #UCSSEL1 , &UCB0CTL1			;use smclk as clock
             ;mov.b #UCLISTEN, &UCB0STAT			;enable listening for debugging
             mov.b #0x00, &UCB0BR0
             mov.b #0x00, &UCB0BR1
             ;Transmit buffer is UCTXBUF0
             ;Receive buffer is  UCRXBUF0
             bis.b #(1 << CLK) | (1 << MOSI) | (1 << MISO), &P1SEL
             bis.b #(1 << CLK) | (1 << MOSI) | (1 << MISO), &P1SEL2
             bis.b #(1 << MOSI) | (1 << CLK) | (1 << CS), &P1DIR
             bic.b #(1 << MISO), &P1DIR
             bic.b #UCSWRST, &UCB0CTL1

             eint

FOO:  call #main
      mov.b r12, r4
      call #DISPLAY_TASK   ;uses the register r4 as an input
      jmp FOO   ;infinite loop

Delay: push r4 ;save r4
       mov.w #0x08ff, r4
LOOP1: sub   #1, r4
       jne   LOOP1
       pop r4
       ret

;TIMER_A_STOP: ;MCx = 00 to stop timer

USER_ISR:   call #Delay
            ;must reset the P1IFG back to zero!!!
            bic   #(1 << BUTTON_3), &P1IFG
            push  r4
            mov.b &P1OUT, r4
            xor.b #(1 << RED_LED), r4
            mov.b r4, &P1OUT
            ;infinite loop until button is released
$1:         bit.b #(1 << BUTTON_3), &P1IN
            jz $1   ;jump if zero is set
            pop r4
            inc.w &DISPLAY
            reti

PORT1_ISR: bit #(1 << BUTTON_3), &P1IFG
           jne USER_ISR
           reti

;sends out the LSB first MSB last through the DS pin on P2
DISPLAY_TO_SHIFT_REG:  push r4 ;This relies on the fact that a variable "DISPLAY" has already been allocated in SRAM
                   push r5   ;r5 is a working reg
                   push r6   ;r6 is a counter
                   mov.b &DISPLAY, r4
                   clr r6    ;init r6 to zero
                   clr r5    ;init r5 to zero
$2:                inc.b r6
                   mov.b #0x01, r5   ;mov the LSB position into r5
                   and r4, r5   ;for the given bit position, was the result 1 or 0?
                                ;the result is in the LSB
                                ;DS bit is on in the 0 position
                   bis r5, &P2OUT  ;based off the previous result, set the DS bit in P2
                   rra.b r4     ;shift right once on r4, the data to be sent
                   ;write the data to shift register by pulsing the SH_CP pin
                   bis #SH_CP, &P2OUT
                   bic #SH_CP, &P2OUT
                   ;clear the data line
                   bic #DS, &P2OUT
                   ;have you sent 8 bits yet?
                   cmp #0x08, r6
                   jne $2
                   ;pulse the storage clk pin to update the shift register
                   bis #ST_CP, &P2OUT
                   bic #ST_CP, &P2OUT
                   ;everything back to normal
                   pop r6
                   pop r5
                   pop r4
                   ret

;***************************************************************************
PRINT_0:   bis #SEG_A | SEG_B | SEG_C | SEG_D | SEG_E | SEG_F, &DISPLAY
           call #DISPLAY_TO_SHIFT_REG
           ret

PRINT_1:   bis #SEG_B | SEG_C, &DISPLAY
           call #DISPLAY_TO_SHIFT_REG
           ret

PRINT_2:   bis #SEG_A | SEG_B | SEG_G | SEG_E | SEG_D, &DISPLAY
           call #DISPLAY_TO_SHIFT_REG
           ret

PRINT_3:   bis #SEG_A | SEG_B | SEG_G | SEG_C | SEG_D, &DISPLAY
           call #DISPLAY_TO_SHIFT_REG
           ret

PRINT_4:   bis #SEG_F | SEG_G | SEG_B | SEG_C, &DISPLAY
           call #DISPLAY_TO_SHIFT_REG
           ret

PRINT_5:   bis #SEG_A | SEG_F | SEG_G | SEG_C | SEG_D, &DISPLAY
           call #DISPLAY_TO_SHIFT_REG
           ret

PRINT_6:   bis #SEG_A | SEG_F | SEG_G | SEG_C | SEG_D | SEG_E, &DISPLAY
           call #DISPLAY_TO_SHIFT_REG
           ret

PRINT_7:   bis #SEG_A | SEG_B | SEG_C, &DISPLAY
           call #DISPLAY_TO_SHIFT_REG
           ret

PRINT_8:   bis #0x7f, &DISPLAY
           call #DISPLAY_TO_SHIFT_REG
           ret

PRINT_9:   bis #SEG_A | SEG_B | SEG_C | SEG_C | SEG_F | SEG_G, &DISPLAY
           call #DISPLAY_TO_SHIFT_REG
           ret

PRINT_A:   bis #SEG_A | SEG_B | SEG_C | SEG_E | SEG_F | SEG_G, &DISPLAY
           call #DISPLAY_TO_SHIFT_REG
           ret

PRINT_B:   bis #SEG_F | SEG_E | SEG_D | SEG_C | SEG_G, &DISPLAY
           call #DISPLAY_TO_SHIFT_REG
           ret

PRINT_C:   bis #SEG_A | SEG_F | SEG_E | SEG_D, &DISPLAY
           call #DISPLAY_TO_SHIFT_REG
           ret

PRINT_D:   bis #SEG_B | SEG_C | SEG_D | SEG_E | SEG_G, &DISPLAY
           call #DISPLAY_TO_SHIFT_REG
           ret

PRINT_E:   bis #SEG_A | SEG_F | SEG_G | SEG_E | SEG_D, &DISPLAY
           call #DISPLAY_TO_SHIFT_REG
           ret

PRINT_F:   bis #SEG_A | SEG_F | SEG_G | SEG_E, &DISPLAY
           call #DISPLAY_TO_SHIFT_REG
           ret

RETURN: ret
;PRINT_HEX displays the number passed into r4
;just make sure that the number in r4 doesn't exceed 0x0f
;cmp says dst - src (never writes back to dst though)
PRINT_HEX:   cmp #0x10, r4
             jge RETURN   ;was dst >= src?
             rla.b r4
             and.b #0x80, &DISPLAY   ;clear the lower 7 bits of DISPLAY
             add.w r4, pc ;pc contains the address of the next instruction btw
             jmp PRINT_0
             jmp PRINT_1
             jmp PRINT_2
             jmp PRINT_3
             jmp PRINT_4
             jmp PRINT_5
             jmp PRINT_6
             jmp PRINT_7
             jmp PRINT_8
             jmp PRINT_9
             jmp PRINT_A
             jmp PRINT_B
             jmp PRINT_C
             jmp PRINT_D
             jmp PRINT_E
             jmp PRINT_F

;takes r4 as an argument for the number to display
PRINT_HEX_TO_MSBYTE:   bis.b #SEG_UNIT_SEL, &DISPLAY
                       call #PRINT_HEX
                       ret
;takes r4 as an argument for the number to display
PRINT_HEX_TO_LSBYTE:   bic.b #SEG_UNIT_SEL, &DISPLAY
                       call #PRINT_HEX
                       ret

;call this in the main loop - quickly, uses the r4 as the number to display
DISPLAY_TASK: push r5
              push r6
              mov.b r4, r5   ;will have LSB
              mov.b r4, r6   ;will have MSB
              and.b #0x0f, r5

              rra.b r6
              rra.b r6
              rra.b r6
              rra.b r6
              and.b #0x0f, r6

              mov.b r5, r4
              call #PRINT_HEX_TO_LSBYTE   ;r4 is an argument of what to display
              call #Delay   ;replace with sleep modes later
              mov.b r6, r4
              call #PRINT_HEX_TO_MSBYTE   ;r4 is an argument of waht to display
              call #Delay   ;replace with sleep modes later
              pop r6
              pop r5
              ret
;-------------------------------------------------------------------------------
;           Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect 	.stack

;-------------------------------------------------------------------------------
;           Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short INIT
            .sect   PORT1_VECTOR			;Look at header file
            .short  PORT1_ISR

            .end

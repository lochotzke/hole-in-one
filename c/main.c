/*
 * Copyright © 2012 Constantin Zankl <constantin.zankl@stud.fh-erfurt.de>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include <htc.h>

// external oscillator & watchdog timer off & power-up timer off & code
// protection off
__CONFIG(FOSC_XT & WDTE_OFF & PWRTE_OFF & CP_OFF);

#define TRIGGER_PIN	RA1
#define SENSOR_PIN	RB0
#define MAGNET_PIN	RB2

#define T_DROP		316121

#define TMR_L		TMR0

// data types are small when using picc, see README.md
volatile unsigned int TMR_H = 0;
volatile bit TMR_Z = 0;

static void interrupt isr()
{
	TMR_H++;
	if (TMR_H == 0) {
		TMR_Z = 1;
	}
	T0IF = 0;
}

void main()
{
	// use internal instruction cycle clock as source for TMR0
	T0CS = 0;
	// set TMR0 prescalar to 1:1
	PS0 = 0;
	PS1 = 0;
	PS2 = 0;

	// TRIGGER_PIN is already set as input (datasheet, p. 7)
	// set PINs on PORTB as output (status leds and MAGNET_PIN) and
	// SENSOR_PIN as input
	TRISB = 0b00000001;

	// turn off all leds ignoring sensor (low active) and turn on magnet
	RB1 = 1;
	RB3 = 1;
	RB4 = 1;
	RB5 = 1;
	RB6 = 1;
	RB7 = 1;
	MAGNET_PIN = 1;

	// ram needs to be cleared since it can contain garbage
	unsigned short long t_slot = 0;
	unsigned short long t_round = 0;
	signed short long t_release = 0;

	// enable interrupts
	GIE = 1;

	// show that programm is initialized
	RB1 = 0;

	// poll trigger push
	while (TRIGGER_PIN);

	// show that trigger is pushed
	RB3 = 0;

	// poll trigger release
	while (!TRIGGER_PIN);

	// show that trigger is released
	RB4 = 0;

	// poll slot start
	while (!SENSOR_PIN);

	// initialize and start timer/counter
	TMR_L = 0;
	// enable TMR interrupt
	T0IE = 1;

	// show that timer/counter was started
	RB5 = 0;

	// poll slot end
	while (SENSOR_PIN);

	// change TMR0 source to RA4 to stop timer/counter
	T0CS = 1;
	// disable TMR interrupt
	T0IE = 0;

	// show that counter was stopped
	RB6 = 0;

	// save timer/counter value
	t_slot = TMR_H * 256 + TMR_L;

	// multiply t_slot with 18 to calculate round
	t_round = t_slot * 18;

	// add one slot to countdown
	t_release = T_DROP + t_slot;

	// adjust countdown to cause drop as soon as possible
	while (t_release > 0) {
		t_release -= t_round;
	}

	// initialize countdown
	TMR_H = t_release / 256;
	TMR_L = t_release & 0xff;

	// change TMR0 source back to internal cycle count to start timer/countdown
	T0CS = 0;
	// enable TMR interrupt
	T0IE = 1;

	// show that calculation is done and countdown was started
	RB7 = 0;

	// wait for timer to overflow/countdown to be done
	while (!TMR_Z);

	// drop ball
	MAGNET_PIN = 0;

	// halt
	while (1);
}

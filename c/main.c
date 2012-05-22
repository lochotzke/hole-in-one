// 2012 © Constantin Zankl <constantin.zankl@stud.fh-erfurt.de>

#include <htc.h>

// external oscillator & watchdog timer off & power-up timer off & code protection off
__CONFIG(FOSC_XT & WDTE_OFF & PWRTE_ON & CP_OFF);

#define TRIGGER_PIN	RA1
#define SENSOR_PIN	RB0
#define MAGNET_PIN	RB2

#define T_DROP		316121

#define TMR_L		TMR0

static int TMR_H = 0;
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

	// turn off all leds and turn on magnet (all are low active)
	PORTB = 0b11111110;

	// ram needs to be cleared since it can contain garbage
	int t_slot = 0;
	int t_round = 0;
	int t_release = 0;

	GIE = 1;

	//Set Debug-LED
	RB1 = 0;

	//Wait for trigger button to be pushed
	while (TRIGGER_PIN);
	RB3 = 0;

	//Wait for trigger button to be released
	while (!TRIGGER_PIN);

	//Set Debug-LED
	RB4 = 0;

	//Wait for Hall-Sensor and Calucalte Time
	//Wait for First Sensor signal
	while (!SENSOR_PIN);

	//Set Debug-LED
	RB5 = 0;

	//Start Timer
	TMR0 = 0;
	T0IE = 1;

	while (SENSOR_PIN);
	//Wait for Second Trigger signal

	//Get Timer result
	T0CS = 1;
	T0IE = 0;
	t_slot = (TMR_H << 8) + TMR_L;

	//Calculate perfect droptime in µs
	t_round = t_slot * 18;
	t_release = T_DROP + t_slot;

	//Set Debug-LED
	RB6 = 0;

	while (t_release > 0) {
		t_release -= t_round;
	}

	//Drop ball after droptime
	TMR_H = t_release >> 8;
	TMR0 = t_release & 0xff;
	T0CS = 0;
	T0IE = 1;

	while (!TMR_Z);

	//Set Debug-LED
	RB7 = 0;

	// Release ball
	MAGNET_PIN = 0;

	while (1);
}
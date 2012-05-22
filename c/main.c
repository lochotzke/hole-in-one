// 2012 © Constantin Zankl <constantin.zankl@stud.fh-erfurt.de>

#include <htc.h>
#include <limits.h>

// external oscillator & watchdog timer off & power-up timer off & code protection off
__CONFIG(FOSC_XT & WDTE_OFF & PWRTE_ON & CP_OFF);

#define TRIGGER	RA1
#define SENSOR	RB0
#define MAGNET	RB2

#define T_DROP	316121

#define TMR_L	TMR0

static int TMR_H = 0;
volatile bit TMR_Z = 0;

static void interrupt isr()
{
	if (T0IF) {
		TMR_H++;
		if (TMR_H == 0) {
			TMR_Z = 1;
		}
		T0IF = 0;
	}
}

void main()
{
	//Set Sensorpin (0) to In and Magnet Pin (2) to Out
	TRISB = 0b00000001;

	//Configure Timer
	T0CS = 0;
	PS0 = 0;
	PS1 = 0;
	PS2 = 0;

	//Set Debug LEDs off
	PORTB = 0b11111111;

	//Init Vars
	int iHall = 0;
	int iDroptime = 0;
	int iRoundtime = 0;

	GIE = 1;

	//Set Debug-LED
	RB1 = 0;

	//Wait for trigger button to be pushed
	while(TRIGGER);
	RB3 = 0;

	//Wait for trigger button to be released
	while(!TRIGGER);

	//Set Debug-LED
	RB4 = 0;

	//Wait for Hall-Sensor and Calucalte Time
	//Wait for First Sensor signal
	while(!SENSOR);

	//Set Debug-LED
	RB5 = 0;

	//Start Timer
	TMR0 = 0;
	T0IE = 1;

	while(SENSOR);
	//Wait for Second Trigger signal

	//Get Timer result
	T0CS = 1;
	T0IE = 0;
	iHall = (TMR_H << 8) + TMR_L;

	//Calculate perfect droptime in µs
	iRoundtime = iHall * 18;
	iDroptime = T_DROP + iHall;

	//Set Debug-LED
	RB6 = 0;

	while (iDroptime > 0) {
		iDroptime -= iRoundtime;
	}

	//Drop ball after droptime
	TMR_H = iDroptime >> 8;
	TMR0 = iDroptime & 0xff;
	T0CS = 0;
	T0IE = 1;


	while (!TMR_Z);

	//Set Debug-LED
	RB7 = 0;

	// Release ball
	RB2 = 0;

	while (1);
}
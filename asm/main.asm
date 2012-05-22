; http://pic-projects.net/
; 2012 © André Lochotzke <andre.lochotzke@stud.fh-erfurt.de>

		include		<p16f84a.inc>

		; use decimal as the default radix
		radix		dec

		title		"hole-in-one, v1.0"

		; external oscillator & watchdog timer off & power-up timer off & code protection off
		__config	_XT_OSC & _WDT_OFF & _PWRTE_OFF & _CP_OFF

#define		TRIGGER_PORT	PORTA
#define		TRIGGER_PIN	1
#define		SENSOR_PORT	PORTB
#define		SENSOR_PIN	0
#define		MAGNET_PORT	PORTB
#define		MAGNET_PIN	2

#define		T_DROP		316121
#define		TMR_Z		0

		udata
 
		errorlevel	-231	; "No memory has been reserved by this instruction."
FLAGS		res		1
TMR1		res		1
TMR2		res		1
t_round		res		3
t_slot		res		3
		errorlevel	+231	; "No memory has been reserved by this instruction."

start		code		0
		goto		init

irq		code		4
		goto		isr

isr
		incf		TMR1, F
		btfsc		STATUS, Z
		incf		TMR2, F
		btfsc		STATUS, Z
		bsf		FLAGS, TMR_Z
		; clear TMR interrupt flag
		bcf		INTCON, T0IF
		retfie

init
		errorlevel	-302	; "Register in operand not in bank 0. Ensure bank bits are correct."
		bsf		STATUS, RP0
		; use internal instruction cycle clock as source for TMR0
		bcf		OPTION_REG, T0CS
		; set TMR0 prescalar to 1:1
		bcf		OPTION_REG, PS0
		bcf		OPTION_REG, PS1
		bcf		OPTION_REG, PS2
		; TRIGGER_PIN is already set as input (datasheet, p. 7)
		; set PINs on PORTB as output (status leds and MAGNET_PIN)
		clrf		TRISB
		; set SENSOR_PIN as input
		bsf		TRISB, SENSOR_PIN
		bcf		STATUS, RP0
		errorlevel	+302
		; turn off all leds and turn on magnet (all are low active)
		movlw		h'ff'
		movwf		PORTB
		; ram needs to be cleared since it can contain garbage
		clrf		FLAGS
		clrf		TMR1
		clrf		TMR2
		clrf		t_round
		clrf		t_round + 1
		clrf		t_round + 2
		clrf		t_slot
		clrf		t_slot + 1
		clrf		t_slot + 2
		; enable interrupts
		bsf		INTCON, GIE
		goto		main

main
		; programm is initialized
		bcf		PORTB, 1

		; poll trigger push
main_loop_trigger_start
		btfsc		TRIGGER_PORT, TRIGGER_PIN
		goto		main_loop_trigger_start
main_loop_trigger_stop

		; trigger pushed
		bcf		PORTB, 3

		; poll trigger release
		btfss		TRIGGER_PORT, TRIGGER_PIN
		goto		main_loop_trigger_stop

		; trigger released
		bcf		PORTB, 4

		; poll slot start
main_loop_slot_start
		btfss		SENSOR_PORT, SENSOR_PIN
		goto		main_loop_slot_start

		; count t_slot
		clrf		TMR0
		; enable TMR interrupt
		bsf		INTCON, T0IE

		; counter started
		bcf		PORTB, 5

		; poll slot end
main_loop_slot_end
		btfsc		SENSOR_PORT, SENSOR_PIN
		goto		main_loop_slot_end

		; slot ended
		bcf		PORTB, 6

		; stop timer
		; change TMR0 source to RA4 to stop counter
		bsf		OPTION_REG, T0CS
		; disable TMR interrupt
		bcf		INTCON, T0IE

		; save TMR0:2 to t_slot
		movf		TMR0, W
		movwf		t_slot
		movf		TMR1, W
		movwf		t_slot + 1
		movf		TMR2, W
		movwf		t_slot + 2

		; multiply TMR with 18 (TMR = (TMR * 2 * 2 * 2 + TMR) * 2)
		; TMR *= 2
		rlf		TMR0, F
		rlf		TMR1, F
		rlf		TMR2, F
		; TMR *= 2
		rlf		TMR0, F
		rlf		TMR1, F
		rlf		TMR2, F
		; TMR *= 2
		rlf		TMR0, F
		rlf		TMR1, F
		rlf		TMR2, F
		; TMR += t_slot
		movf		t_slot, W
		addwf		TMR0, F
		movf		t_slot + 1, W
		btfsc		STATUS, C
		incfsz		t_slot + 1, W
		addwf		TMR1, F
		movf		t_slot + 2, W
		btfsc		STATUS, C
		incfsz		t_slot + 2, W
		addwf		TMR2, F
		; TMR *= 2
		rlf		TMR0, F
		rlf		TMR1, F
		rlf		TMR2, F

		; save TMR0:2 to t_round
		movf		TMR0, W
		movwf		t_round
		movf		TMR1, W
		movwf		t_round + 1
		movf		TMR2, W
		movwf		t_round + 2

		; init countdown
		movlw		T_DROP >> 0 & h'ff'
		movwf		TMR0
		movlw		T_DROP >> 8 & h'ff'
		movwf		TMR1
		movlw		T_DROP >> 16 & h'ff'
		movwf		TMR2

		; add t_slot to countdown
		movf		t_slot, W
		addwf		TMR0, F
		movf		t_slot + 1, W
		btfsc		STATUS, C
		incfsz		t_slot + 1, W
		addwf		TMR1, F
		movf		t_slot + 2, W
		btfsc		STATUS, C
		incfsz		t_slot + 2, W
		addwf		TMR2, F

main_loop_calc
		; adjust countdown to cause drop in current or next round
		movf		t_round, W
		subwf		TMR0, F
		movf		t_round + 1, W
		btfss		STATUS, C
		incfsz		t_round + 1, W
		subwf		TMR1, F
		movf		t_round + 2, W
		btfss		STATUS, C
		incfsz		t_round + 2, W
		subwf		TMR2, F
		btfsc		STATUS, C
		goto		main_loop_calc

		; calculation is done
		bcf		PORTB, 7

		; start timer/countdown
		; change TMR0 source back to internal cycle count
		bcf		OPTION_REG, T0CS
		; enable TMR interrupt
		bsf		INTCON, T0IE

		; wait for TMR0:2 to overflow
main_loop_countdown
		btfss		FLAGS, TMR_Z
		goto		main_loop_countdown

		; drop ball
		bcf		MAGNET_PORT, MAGNET_PIN

		; ball was dropped
		bsf		PORTB, 7

		; halt
		goto		$

		end

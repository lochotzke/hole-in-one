; TODO: Fehlerbetrachtung, statische Analyse (Zeitaufwand, Codezeilen...)
; TODO: count T_CALC
; TODO: determine T_RELEASE through trial and error
; TODO: optimize t_countdown away by modifying TMR directly

; 2012 © André Lochotzke <andre.lochotzke@stud.fh-erfurt.de>

; necessary to use code with GPSim since the PIC16F84A is not supported
ifdef		__16F84
		include		<p16f84.inc>
endif

ifdef		__16F84A
		include		<p16f84a.inc>
endif

		; use decimal as the default radix
		radix		dec

		title		"hole-in-one, v0.2"

		; external oscilator & watchdog timer off & power write on & code protection off
		__config	_XT_OSC & _WDT_OFF & _PWRTE_ON & _CP_OFF

#define		TRIGGER_PORT	PORTA
#define		TRIGGER_PIN	4
#define		SENSOR_PORT	PORTB
#define		SENSOR_PIN	0
#define		MAGNET_PORT	PORTB
#define		MAGNET_PIN	2

#define		T_CALC		0
#define 	T_RELEASE	0
#define		T_DROP		316121
#define		TMR_Z		0

		udata
 
		errorlevel	-231	; "No memory has been reserved by this instruction."
FLAGS		res		1
TMR1		res		1
TMR2		res		1
t_countdown	res		4
t_round		res		4
t_slot		res		4
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
		; clear TMR0 interrupt flag
		bsf		INTCON, T0IF
		retfie

init
		errorlevel	-302	; "Register in operand not in bank 0. Ensure bank bits are correct."
		bsf		STATUS, RP0
		; use internal instruction cycle clock as source for TMR0
		bcf		OPTION_REG, T0CS
		; set TMR0 prescalar to 1:1
		bcf		OPTION_REG, PS2
		bcf		OPTION_REG, PS1
		bcf		OPTION_REG, PS0
		; set TRIGGER_PIN as input
		bsf		TRISA, TRIGGER_PIN
		; set TRIGGER_PIN as input
		bsf		TRISB, SENSOR_PIN
		; MAGNET_PIN is already set as output
		bcf		STATUS, RP0
		errorlevel	+302
		; init countdown
		movlw		(T_CALC + T_RELEASE + T_DROP) & H'ff'
		movwf		t_countdown
		movlw		(T_CALC + T_RELEASE + T_DROP) >> 8 & H'ff'
		movwf		t_countdown + 1
		movlw		(T_CALC + T_RELEASE + T_DROP) >> 16 & H'ff'
		movwf		t_countdown + 2
		; enable interrupts
		bsf		INTCON, GIE
		goto		main

main
		; poll trigger push
		btfss		TRIGGER_PORT, TRIGGER_PIN
main_loop_trigger
		; poll trigger release
		btfsc		TRIGGER_PORT, TRIGGER_PIN
		goto		main_loop_trigger

		; poll slot start
main_loop_slot_start
		btfss		SENSOR_PORT, SENSOR_PIN		; 2µs
		goto		main_loop_slot_start

		; count t_slot
		; init TMR to account for delay
		movlw		3				; 1µs
		movwf		TMR0				; 1µs + 2µs (timer delay)
		; enable TMR interrupt
		bsf		INTCON, T0IE			; (1µs)

		; poll slot end
main_loop_slot_end
		btfsc		SENSOR_PORT, SENSOR_PIN		; 2µs
		goto		main_loop_slot_end

		; stop timer
		; change TMR0 source to RA4 to stop counter
		bsf		OPTION_REG, T0CS		; 1µs
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
		bcf		STATUS, C
		; TMR *= 2
		rlf		TMR0, F
		rlf		TMR1, F
		rlf		TMR2, F
		bcf		STATUS, C
		; TMR *= 2
		rlf		TMR0, F
		rlf		TMR1, F
		rlf		TMR2, F
		bcf		STATUS, C
		; TMR += t_slot
		movf		t_slot, W
		addwf		TMR0, F
		btfsc		STATUS, C
		incf		TMR1, F
		movf		t_slot + 1, W
		addwf		TMR1, F
		btfsc		STATUS, C
		incf		TMR2, F
		movf		t_slot + 2, W
		addwf		TMR2, F
		; TMR *= 2
		rlf		TMR0, F
		rlf		TMR1, F
		rlf		TMR2, F
		bcf		STATUS, C

		; save TMR0:2 to t_round
		movf		TMR0, W
		movwf		t_round
		movf		TMR1, W
		movwf		t_round + 1
		movf		TMR2, W
		movwf		t_round + 2

		; add t_slot to t_countdown
		movf		t_slot, W
		addwf		t_countdown, F
		movf		t_slot + 1, W
		btfsc		STATUS, C
		incf		t_slot + 1, W
		addwf		t_countdown + 1, F
		movf		t_slot + 2, W
		btfsc		STATUS, C
		incf		t_slot + 2, W
		addwf		t_countdown + 2, F

main_loop_calc
		; adjust t_countdown to cause drop in current or next round
		movf		t_round, W
		subwf		t_countdown, F
		movf		t_round + 1, W
		btfss		STATUS, C
		incfsz		t_round + 1, W
		subwf		t_countdown + 1, F
		movf		t_round + 2, W
		btfss		STATUS, C
		incfsz		t_round + 2, W
		subwf		t_countdown + 2, F
		btfss		STATUS, C
		goto		main_loop_calc

		; init and start timer/countdown
		movf		t_countdown, W
		movwf		TMR0
		movf		t_countdown + 1, W
		movwf		TMR1
		movf		t_countdown + 2, W
		movwf		TMR2
		; change TMR0 source back to internal cycle count
		bcf		OPTION_REG, T0CS
		; enable TMR interrupt
		bsf		INTCON, T0IE

		; wait for TMR0:2 to overflow
main_loop_countdown
		btfss		FLAGS, TMR_Z
		goto		main_loop_countdown

		; drop ball
		bsf		MAGNET_PORT, MAGNET_PIN

		; halt
		goto		$

		end

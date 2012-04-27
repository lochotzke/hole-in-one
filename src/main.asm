; TODO: Fehlerbetrachtung, statische Analyse (Zeitaufwand, Codezeilen, Speicherverbrauch, ...)
; TODO: document calculations (round and countdown)
; TODO: determine T_RELEASE through trial and error

; 2012 © André Lochotzke <andre.lochotzke@stud.fh-erfurt.de>

		include		<p16f84a.inc>

		; use decimal as the default radix
		radix		dec

		title		"hole-in-one, v0.3"

		; external oscilator & watchdog timer off & power write on & code protection off
		__config	_XT_OSC & _WDT_OFF & _PWRTE_ON & _CP_OFF

#define		TRIGGER_PORT	PORTA
#define		TRIGGER_PIN	4
#define		SENSOR_PORT	PORTB
#define		SENSOR_PIN	0
#define		MAGNET_PORT	PORTB
#define		MAGNET_PIN	2

#define		T_COMPUTE	79
#define 	T_RELEASE	0
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
		bcf		OPTION_REG, PS2
		bcf		OPTION_REG, PS1
		bcf		OPTION_REG, PS0
		; set TRIGGER_PIN as input
		bsf		TRISA, TRIGGER_PIN
		; set SENSOR_PIN as input
		bsf		TRISB, SENSOR_PIN
		; MAGNET_PIN is already set as output
		bcf		STATUS, RP0
		errorlevel	+302
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
		btfss		SENSOR_PORT, SENSOR_PIN		; 2µs (start slot)
		goto		main_loop_slot_start

		; count t_slot
		; init TMR to account for delay
		movlw		3				; 1µs
		movwf		TMR0				; 1µs + 2µs (timer delay) (start counter)
		; enable TMR interrupt
		bsf		INTCON, T0IE			; (1µs)

		; poll slot end
main_loop_slot_end
		btfsc		SENSOR_PORT, SENSOR_PIN		; 2µs (end slot)
		goto		main_loop_slot_end

		; stop timer
		; change TMR0 source to RA4 to stop counter
		bsf		OPTION_REG, T0CS		; 1µs (end counter)
		; disable TMR interrupt
		bcf		INTCON, T0IE			; 1µs (start COMPUTE)

		; save TMR0:2 to t_slot
		movf		TMR0, W				; 6µs
		movwf		t_slot
		movf		TMR1, W
		movwf		t_slot + 1
		movf		TMR2, W
		movwf		t_slot + 2

		; multiply TMR with 18 (TMR = (TMR * 2 * 2 * 2 + TMR) * 2)
		; TMR *= 2
		rlf		TMR0, F				; 3µs
		rlf		TMR1, F
		rlf		TMR2, F
		; TMR *= 2
		rlf		TMR0, F				; 3µs
		rlf		TMR1, F
		rlf		TMR2, F
		; TMR *= 2
		rlf		TMR0, F				; 3µs
		rlf		TMR1, F
		rlf		TMR2, F
		; TMR += t_slot
		movf		t_slot, W			; 10µs
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
		rlf		TMR0, F				; 3µs
		rlf		TMR1, F
		rlf		TMR2, F

		; save TMR0:2 to t_round
		movf		TMR0, W				; 6µs
		movwf		t_round
		movf		TMR1, W
		movwf		t_round + 1
		movf		TMR2, W
		movwf		t_round + 2

		; init countdown				; 6µs
		movlw		(T_COMPUTE + T_RELEASE + T_DROP) >> 0 & H'ff'
		movwf		TMR0
		movlw		(T_COMPUTE + T_RELEASE + T_DROP) >> 8 & H'ff'
		movwf		TMR1
		movlw		(T_COMPUTE + T_RELEASE + T_DROP) >> 16 & H'ff'
		movwf		TMR2

		; add t_slot to countdown
		movf		t_slot, W			; 10µs
		addwf		TMR0, F
		movf		t_slot + 1, W
		btfsc		STATUS, C
		incf		t_slot + 1, W
		addwf		TMR1, F
		movf		t_slot + 2, W
		btfsc		STATUS, C
		incf		t_slot + 2, W
		addwf		TMR2, F

main_loop_calc
		; adjust countdown to cause drop in current or next round
		movf		t_round, W			; min. 12µs max. 25µs
		subwf		TMR0, F
		movf		t_round + 1, W
		btfss		STATUS, C
		incfsz		t_round + 1, W
		subwf		TMR1, F
		movf		t_round + 2, W
		btfss		STATUS, C
		incfsz		t_round + 2, W
		subwf		TMR2, F
		btfss		STATUS, C
		goto		main_loop_calc

		; start timer/countdown
		; change TMR0 source back to internal cycle count
		bcf		OPTION_REG, T0CS		; 1µs + 2µs (delay)
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

; 2011-2012 © André Lochotzke <andre.lochotzke@stud.fh-erfurt.de>

		title		"hole-in-one, v0.1"

; external oscilator & watchdog timer off & power write on & code protection off
		__config	_XT_OSC & _WDT_OFF & _PWRTE_ON & _CP_OFF

include		"common.inc"
include		"sleep.inc"
include		"math.inc"

#define		F24_MAX		16777215	; h'ffffff'
#define		TMR_Z		0

		udata
 
		errorlevel	-231	; "No memory has been reserved by this instruction."
FLAGS		res		1
TMR1		res		1
TMR2		res		1
t_drop		res		4
t_round		res		0
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
		movlf		T_DROP, t_drop, 4	; TODO: add T_RELEASE to T_DROP
		; enable interrupts
		bsf		INTCON, GIE
		goto		main

main
; TODO: Fehlerbetrachtung, statische Analyse (Zeitaufwand, Codezeilen...)
; TODO: wait until ball is actually able to fall through/disk spins slowly enough -> Schlitzlänge messen

		; poll trigger push
		btfss		TRIGGER_PORT, TRIGGER_PIN
main_loop_trigger
		; poll trigger release
		btfsc		TRIGGER_PORT, TRIGGER_PIN
		goto		main_loop_trigger

		; poll slot start
main_loop_slot_start
		btfss		SENSOR_PORT, SENSOR_PIN
		goto		main_loop_slot_start

		; start timer
		; reset TMR0
		clrf		TMR0
		; enable TMR0 interrupt
		bsf		INTCON, T0IE

		; poll slot end
main_loop_slot_end
		btfsc		SENSOR_PORT, SENSOR_PIN
		goto		main_loop_slot_end

		; stop timer
		; change TMR0 source to RA4 to stop counter
		bsf		OPTION_REG, T0CS
		; disable interrupts
		bcf		INTCON, GIE

		; save TMR0:2
		movf		TMR0, W
		movwf		t_slot
		movf		TMR1, W
		movwf		t_slot + 1
		movf		TMR2, W
		movwf		t_slot + 2

		; TODO: math

		; wait for TMR0:2 to reach F24_MAX
main_loop_countdown
		btfss		FLAGS, TMR_Z
		goto		main_loop_countdown

		; drop ball
		bsf		MAGNET_PORT, MAGNET_PIN

		; halt
		goto		$

		; count until sensor pin is down
;main_loop_slot
;		movlw		13	; TODO: add addwf32 time
;		addwf32		t_slot, F
;		btfsc		SENSOR_PORT, SENSOR_PIN
;		goto		main_loop_slot
;		; pass is always possible
;		mullf32		t_slot, MULTIPLIER
;; release = round - drop time (32bit math)
;; if release
;;  < 0 -> release += round and repeat
;;  > 0 || == 0 release in release µs
;		call		sleep_us ; delay release
;; release
;		goto		main

		end

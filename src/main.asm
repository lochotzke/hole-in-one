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
#define		TRIGGER_PIN	1
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
;n		res		1
		errorlevel	+231	; "No memory has been reserved by this instruction."

start		code		0
		goto		init

irq		code		4
		goto		isr

isr
; http://www.pic-projects.net/index.php?option=com_content&view=article&id=53:multi-byte-increment&catid=38:arithmetic&Itemid=57
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
; FIXME: make nicer
		movlw		H'00'
		movwf		TRISB
		; set SENSOR_PIN as input
		bsf		TRISB, SENSOR_PIN
		bcf		STATUS, RP0
		errorlevel	+302
		; MAGNET_PIN is already set as output, but needs to be turned on
		; set all to one
		movlw		H'FF'
		movwf		PORTB
		; enable interrupts
		bsf		INTCON, GIE
		goto		main

main
		; poll trigger push
; DEBUG
		bcf		PORTB, 1

main_loop_trigger_start
		btfsc		TRIGGER_PORT, TRIGGER_PIN
		goto		main_loop_trigger_start
main_loop_trigger_stop
; DEBUG
		bsf		PORTB, 1
		bcf		PORTB, 3
		
		; poll trigger release
		btfss		TRIGGER_PORT, TRIGGER_PIN
		goto		main_loop_trigger_stop

; DEBUG
		bsf		PORTB, 3
		bcf		PORTB, 4

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

; DEBUG
		bsf		PORTB, 4
		bcf		PORTB, 5

		; poll slot end
main_loop_slot_end
		btfsc		SENSOR_PORT, SENSOR_PIN		; 2µs (end slot)
		goto		main_loop_slot_end

; DEBUG
		bsf		PORTB, 5
		bcf		PORTB, 6

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
; movf    A0,W
;         addwf   R0,F
;         movf    A1,W
;         btfsc   STATUS,C
;         incfsz  A1,W
;         addwf   R1,F
;         movf    A2,W
;         btfsc   STATUS,C
;         incfsz  A2,W
;         addwf   R2,F
; TODO: another math fix?
; http://www.pic-projects.net/index.php?option=com_content&view=article&id=57:multi-byte-addition-a-subtraction&catid=38:arithmetic&Itemid=57
		movf		t_slot, W			; 10µs
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

; movf    A0,W
;         addwf   R0,F
;         movf    A1,W
;         btfsc   STATUS,C
;         incfsz  A1,W
;         addwf   R1,F
;         movf    A2,W
;         btfsc   STATUS,C
;         incfsz  A2,W
;         addwf   R2,F

; TODO: another math fix?
		; add t_slot to countdown
		movf		t_slot, W			; 10µs
		addwf		TMR0, F
		movf		t_slot + 1, W
		btfsc		STATUS, C
		incfsz		t_slot + 1, W
		addwf		TMR1, F
		movf		t_slot + 2, W
		btfsc		STATUS, C
		incfsz		t_slot + 2, W
		addwf		TMR2, F

;         movf    A0,W
;         subwf   R0,F
;         movf    A1,W
;         btfss   STATUS,C
;         incfsz  A1,W
;         subwf   R1,F
;         movf    A2,W
;         btfss   STATUS,C
;         incfsz  A2,W
;         subwf   R2,F
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
; TODO: maybe btfsc is the fix?
		btfsc		STATUS, C
		goto		main_loop_calc

; 		clrf		n
; ;FIXME: count instructions
; main_loop_count
; 		incf		n
; 		; adjust countdown to cause drop in current or next round
; 		movf		t_round, W			; min. 12µs max. 25µs
; 		subwf		TMR0, F
; 		movf		t_round + 1, W
; 		btfss		STATUS, C
; 		incfsz		t_round + 1, W
; 		subwf		TMR1, F
; 		movf		t_round + 2, W
; 		btfss		STATUS, C
; 		incfsz		t_round + 2, W
; 		subwf		TMR2, F
; 		btfss		STATUS, C
; 		goto		main_loop_count
; 
; main_loop_adjust
; 		; adjust countdown to cause drop in current or next round
; 		decf		n
; 		btfsc		STATUS, Z
; 		goto		main_loop_adjust_done
; 		movf		t_round, W			; min. 12µs max. 25µs
; 		subwf		TMR0, F
; 		movf		t_round + 1, W
; 		btfss		STATUS, C
; 		incfsz		t_round + 1, W
; 		subwf		TMR1, F
; 		movf		t_round + 2, W
; 		btfss		STATUS, C
; 		incfsz		t_round + 2, W
; 		subwf		TMR2, F
; 		btfss		STATUS, C
; 		goto		main_loop_adjust
; main_loop_adjust_done

; DEBUG
		bsf		PORTB, 6
		bcf		PORTB, 7

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
		bcf		MAGNET_PORT, MAGNET_PIN

		; re-run
		goto		init

		end

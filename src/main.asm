; 2011 © André Lochotzke <andre.lochotzke@stud.fh-erfurt.de>

; external oscilator & watchdog timer off & power write on & code protection off
		__config	_XT_OSC & _WDT_OFF & _PWRTE_ON & _CP_OFF

include		"common.inc"
include		"util.inc"

		udata
 
		errorlevel	-231	; "No memory has been reserved by this instruction."
; isr_w		res		1
; isr_status	res		1
; isr_pclath	res		1
; isr_fsr		res		1
time		res		2
		errorlevel	+231	; "No memory has been reserved by this instruction."

start		code		0
		goto		init

irq		code		4
		goto		isr

; http://www.piclist.com/techref/microchip/isrregs.htm
; PCLATH must not be safed since it is not manipulated
; STATUS, WREG, FSR are also not changed
isr
; save
; 		movwf		isr_w
; 		swapf		STATUS, W
; 		movwf		isr_status
; 		clrf		STATUS
; 		movf		PCLATH, W
; 		movwf		isr_pclath
; 		clrf		PCLATH
; 		movf		FSR, W
; 		movwf		isr_fsr
; work

; restore
; 		movf		isr_fsr, W
; 		movwf		FSR
; 		movf		isr_pclath, W
; 		movwf		PCLATH
; 		swapf		isr_status, W
; 		movwf		STATUS
; 		swapf		isr_w, F
; 		swapf		isr_w, W
		retfie

init
		errorlevel	-302	; "Register in operand not in bank 0. Ensure bank bits are correct."
		bsf		STATUS, RP0
		movlw		TRIGGER_PIN
		movwf		TRISA
		movlw		SENSOR_PIN | MAGNET_PIN
		movwf		TRISB
		;; PIC16F84A Data Sheet 2.3.2 p. 9
		;; PSA must be set and PS2:PS0 cleared for a TMR0 prescaler of 1:1
		;bsf		OPTION_REG, PSA
		bcf		STATUS, RP0
		errorlevel	+302
		bcf		INTCON, GIE
		; bsf		INTCON, T0IF
		goto		main

main
; poll taster
; poll sensor for up
; start counting
; poll sensor for down
; stop counting
; calc 

		goto		main

		end

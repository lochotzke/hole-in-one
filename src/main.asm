; 2011-2012 © André Lochotzke <andre.lochotzke@stud.fh-erfurt.de>

; external oscilator & watchdog timer off & power write on & code protection off
		__config	_XT_OSC & _WDT_OFF & _PWRTE_ON & _CP_OFF

include		"common.inc"
include		"sleep.inc"
include		"math.inc"

		udata
 
		errorlevel	-231	; "No memory has been reserved by this instruction."
t_drop		res		4
t_slot		res		4
		errorlevel	+231	; "No memory has been reserved by this instruction."

start		code		0
		goto		init

irq		code		4
		goto		isr

isr
		retfie

init
		errorlevel	-302	; "Register in operand not in bank 0. Ensure bank bits are correct."
		bsf		STATUS, RP0
		movlw		IN << TRIGGER_PIN
		movwf		TRISA
		movlw		(IN << SENSOR_PIN) | (OUT << MAGNET_PIN)
		movwf		TRISB
		bcf		STATUS, RP0
		errorlevel	+302
		movlf		T_DROP, t_drop, 4	; TODO: add T_RELEASE to T_DROP
		goto		main

main
; TODO: Fehlerbetrachtung, statische Analyse (Zeitaufwand, Codezeilen...)
; TODO: wait until ball is actually able to fall through/disk spins slowly enough -> Schlitzlänge messen
		waituntil	TRIGGER_PORT, TRIGGER_PIN, UP	; poll taster
		waituntil	SENSOR_PORT, SENSOR_PIN, UP	; poll sensor for up

; start counting
; poll sensor for down
; stop counting
; check if pass is possible -> goto poll taster or continue
; calc round
; release = round - drop time (32bit math)
; if release
;  < 0 -> release += round and repeat
;  > 0 || == 0 release in release µs
		call		sleep_us ; delay release
; release
		goto		main

		end

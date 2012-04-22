; 2012 © André Lochotzke <andre.lochotzke@stud.fh-erfurt.de>

include		"common.inc"

; functions
		global		sleep_us
; variables
		global		sleep_count

		udata

; "No memory has been reserved by this instruction."
		errorlevel	-231
sleep_count	res		4
		errorlevel	+231

		code

; min. 21µs, error max. +1µs to +6µs
sleep_us
		movlw		-21
sleep_us_count
		addwf		sleep_count, F
		btfsc		STATUS, C
		goto		sleep_us_count1
		movlw		-6
		goto		sleep_us_count
sleep_us_count1
		movlw		-9
		decf		sleep_count + 1, F
		btfss		STATUS, C
		goto		sleep_us

		movlw		-13
		decf		sleep_count + 2, F
		btfss		STATUS, C
		goto		sleep_us

		movlw		-17
		decf		sleep_count + 3, F
		btfss		STATUS, C
		goto		sleep_us

		return

		end

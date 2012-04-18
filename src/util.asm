; 2011 © André Lochotzke <andre.lochotzke@stud.fh-erfurt.de>

include		"common.inc"
include		"math.inc"

; functions
		global		util_delay_1s
		global		util_delay_25us
		global		util_delay_98us

		udata

; "No memory has been reserved by this instruction."
		errorlevel	-231
counter		res		2
		errorlevel	+231

		code

; (6 + 250 * (5 + 222 * 18 - 1) - 1) / 1000000 = 1.000005
util_delay_1s
		movlw		250
		movwf		counter
util_delay_1s_outer_loop
		movlw		222
		movlw		counter + 1
util_delay_1s_inner_loop
		nops		14
		decf		counter + 1, F
		btfss		_Z
		goto		util_delay_1s_inner_loop
		decfsz		counter, F
		goto		util_delay_1s_outer_loop
		return

; 2µs (call) + 2µs + (5 * 4 - 1)µs (loop) + 2µs (return) = 25µs
util_delay_25us
		movlw		5
		movwf		counter
util_delay_25us_loop
		nop
		decfsz		counter, F
		goto		util_delay_25us_loop
		return

; 2µs (call) + 2µs + (31 * 3 - 1)µs (loop) + 2µs (return) = 98µs
; since computation between delays from calling source takes 4-8µs, this leads
; to an error of 2% ((98 + 4 + 98 + 8 - 2 * 104) / 104)
util_delay_98us
		movlw		31
		movwf		counter
util_delay_98us_loop
		decfsz		counter, F
		goto		util_delay_98us_loop
		return

		end

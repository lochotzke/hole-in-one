; 2011 © André Lochotzke <andre.lochotzke@stud.fh-erfurt.de>

; http://www.sprut.de/electronic/pic/math/math.htm

include		"common.inc"

; functions
		global		math_add
		global		math_sub
; variables
		global		math_term0
		global		math_term1

		udata

		errorlevel	-231	; "No memory has been reserved by this instruction."
math_term0	res		0
term0		res		2
math_term1	res		0
term1		res		2
		errorlevel	+231

		code

; result = term0 += term1
math_add
		movf		term1, W
		addwf		term0, F
		btfsc		_C
		incf		term1 + 1, W
		addwf		term0 + 1, F
		return

; result = term0 -= term1
math_sub
		movf		term1, W
		subwf		term0, F
		movf		term1 + 1, W
		btfss		_C
		incfsz		term1 + 1, W
		subwf		term0 + 1, F
		return

	end

; 2011-2012 © André Lochotzke <andre.lochotzke@stud.fh-erfurt.de>

; http://www.piclist.com/techref/microchip/math/basic.htm
; http://www.sprut.de/electronic/pic/math/math.htm

include		"common.inc"

; functions
		global		math_add16
		global		math_sub16
		global		math_add32
; TODO: inc32
; variables
		global		math_term0
		global		math_term1

		udata

		errorlevel	-231	; "No memory has been reserved by this instruction."
math_term0	res		0
term0		res		4
math_term1	res		0
term1		res		4
		errorlevel	+231

		code

; result = term0 += term1
math_add16
		movf		term1, W
		addwf		term0, F
		btfsc		STATUS, C
		incf		term1 + 1, W
		addwf		term0 + 1, F
		return

; result = term0 -= term1
math_sub16
		movf		term1, W
		subwf		term0, F
		movf		term1 + 1, W
		btfss		STATUS, C
		incfsz		term1 + 1, W
		subwf		term0 + 1, F
		return

math_add32				; 32-bit add: f = f + xw
;         movf    xw0,W           ; low byte 
;         addwf   f0,F            ; low byte add
;         movf    xw1,W           ; next byte 
;         btfsc   STATUS,C        ; überspringe falls C nicht gesetzt 
;         incfsz  xw1,W           ; addiere C falls gesetzt 
;         addwf   f1,F            ; next byte add wenn NZ
; 
;         movf    xw2,W           ; next byte 
;         btfsc   STATUS,C        ; überspringe falls C nicht gesetzt 
;         incfsz  xw2,W           ; addiere C falls gesetzt 
;         addwf   f2,F            ; next byte add wenn  NZ
; 
;         movf    xw3,W           ; high byte 
;         btfsc   STATUS,C        ; überspringe falls C nicht gesetzt 
;         incfsz  xw3,W           ; addiere C falls gesetzt 
;         addwf   f3,F            ; high byte add wenn  NZ
; 
		return

		end

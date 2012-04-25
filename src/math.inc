; 2011-2012 © André Lochotzke <andre.lochotzke@stud.fh-erfurt.de>

; functions
		extern		math_add
		extern		math_sub
; variables
		extern		math_term0
		extern		math_term1

; macros
; http://www.sprut.de/electronic/pic/math/math.htm#32bitadd
; TODO: cycles =
;Add32                           ; 32-bit add: f = f + xw 
;        movf    xw0,W           ; low byte 
;        addwf   f0,F            ; low byte add
;        movf    xw1,W           ; next byte 
;        btfsc   STATUS,C        ; überspringe falls C nicht gesetzt 
;        incfsz  xw1,W           ; addiere C falls gesetzt 
;        addwf   f1,F            ; next byte add wenn NZ
;
;        movf    xw2,W           ; next byte 
;        btfsc   STATUS,C        ; überspringe falls C nicht gesetzt 
;        incfsz  xw2,W           ; addiere C falls gesetzt 
;        addwf   f2,F            ; next byte add wenn  NZ
;
;        movf    xw3,W           ; high byte 
;        btfsc   STATUS,C        ; überspringe falls C nicht gesetzt 
;        incfsz  xw3,W           ; addiere C falls gesetzt 
;        addwf   f3,F            ; high byte add wenn  NZ
;
;        return                  ; fertig
addwf32		macro		addr
		endm

; TODO: cycles =
mullf32		macro		addr, factor
		local		i
i		set		0
		while		i < factor
		; ???
i		set		i + 1
		endw
		endm
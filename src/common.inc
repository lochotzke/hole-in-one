; 2011 © André Lochotzke <andre.lochotzke@stud.fh-erfurt.de>

; necessary to use code with GPSim since the PIC16F84A is not supported
ifdef		__16F84
		include		<p16f84.inc>
endif

ifdef		__16F84A
		include		<p16f84a.inc>
endif

; use decimal as the default radix
		radix		dec

; language extensions
#define		_C		STATUS, C
#define		_Z		STATUS, Z

; saves all 14 bits of the PC
addrof		macro		address, to
		movlw		low address
		movwf		to
		movlw		high address
		movwf		to + 1
		endm

; clears N bytes in RAM
clear		macro		address, size
		local		offset
offset		set		0
		while		offset < size
		clrf		address + offset
offset		set		offset + 1
		endw
		endm

; like comf for W
comw		macro
		xorlw		B'11111111'
		endm

; like decf for W
decw		macro
		addlw		-1
		endm

; like incf for W
incw		macro
		addlw		1
		endm

; copy N bytes from one RAM address to another
move		macro		from, to, size
		local		offset
offset		set		0
		while		offset < size
		movf		from + offset, W
		movwf		to + offset
offset		set		offset + 1
		endw
		endm

; counterpart of clrf
setf		macro		address
		clrf		address
		comf		address, F
		endm

; counterpart of clrw
setw		macro
		movlw		B'11111111'
		endm

; executes a command N times
; unfortunately this does not work
; exec		macro		command, n
; 		local		i
; i		set		0
; 		while		i < n
; 		command
; i		set		i + 1
; 		endw
; 		endm

; stops the program
halt		macro
		goto		$
		endm

; generates multiple NOPs
nops		macro		n
		local		i
i		set		0
		while		i < (n / 2)
		goto		$ + 1
i		set		i + 1
		endw
		if		n % 2 == 1
		nop
		endif
		endm

; hardware and software setup
#define		TRIGGER		PORTA, 4
#define		TRIGGER_PIN	B'00010000'

#define		SENSOR		PORTB, 0
#define		SENSOR_PIN	B'00000001'

#define		MAGNET		PORTB, 2
#define		MAGNET_PIN	B'000000000'

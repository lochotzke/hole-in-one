; 2011-2012 © André Lochotzke <andre.lochotzke@stud.fh-erfurt.de>

; necessary to use code with GPSim since the PIC16F84A is not supported
ifdef		__16F84
		include		<p16f84.inc>
endif

ifdef		__16F84A
		include		<p16f84a.inc>
endif

; http://www.retards.org/library/technology/electronics/pic/libraries/karl_lunt/picmacro.pdf
; http://www.seanet.com/~karllunt/picmacro.zip
		include		"macros.inc"

; use decimal as the default radix
		radix		dec

; language extensions

#define		IN		1
#define		OUT		0

#define		UP		1
#define		DOWN		0

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
mov		macro		from, to, size
		local		offset
offset		set		0
		while		offset < size
		movf		from + offset, W
		movwf		to + offset
offset		set		offset + 1
		endw
		endm

; MPASM™ Assembler, MPLINK™ Object Linker MPLIB™ Object Librarian User's Guide [2009], p. 153
; init N bytes with literal
movlf		macro		value, address, size
		local		offset
offset		set		0
		movlw		address
		movwf		FSR
		while		offset < size
		movlw		(value >> (8 * offset)) & H'FF'
		if		offset > 0
		incf		FSR, F
		endif
		movwf		INDF
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
#define		TRIGGER_PORT	PORTA
#define		TRIGGER_PIN	4

#define		SENSOR_PORT	PORTB
#define		SENSOR_PIN	0

#define		MAGNET_PORT	PORTB
#define		MAGNET_PIN	2

#define		T_DROP		316121

#define		MULTIPLIER	18

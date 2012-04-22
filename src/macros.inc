;
;  PIC macro library
;  Developed by Karl Lunt, May 1999
;

	messg	"Karl Lunt's PIC macro library, version 1.0"

;
;  This library provides macros for program structures such
;  as FOR-NEXT, REPEAT-ALWAYS, REPEAT-UNTIL, and others.
;
;  To incorporate this library in your PIC assembler program,
;  add the following INCLUDE statement immediately after the
;  INCLUDE statement that adds the Microchip equates for your
;  specific processor:
;
;	include		"macros.asm"
;
;  For example, if you are developing code for the 12c672,
;  you would use equates similar to:
;
;	include		".\p12c672.inc"
;	include		".\macros.asm"
;

;
;  Version 1.0   29 May 1999
;  Initial release.  Includes WAITWHILE, WAITUNTIL, and POLL-ENDPOLL.
;  Changed movfw to movf, to support older MCUs.  Will still give errors
;  in NEXTL macro on older PICs, since that macro uses the addlw
;  instruction.
;


;
;  Declare some variables used by the macro library.
;

	variable	_forknt=0
	variable	_nxtknt=0
	variable	_rptknt=0
	variable	_alwknt=0
	variable	_untknt=0
	variable	_seltot=0
	variable	_selknt=0
	variable	_castot=0
	variable	_casknt=0
	variable	_waitk=0
	variable	_pollk=0
	variable	_pollt=0



;
;  Define the BEQ (branch-if-equal)
;
;  Syntax:
;		beq	label
;
;  The BEQ macro tests the current state of the Z-bit.  It
;  does not alter W or any registers.
;

beq	macro	addr
	btfsc	STATUS,Z
	goto	addr
	endm


;
;  BNE (branch-if-not-equal)
;
;  Syntax:
;		bne	label
;
;  The BNE macro tests the current state of the Z-bit.  It
;  does not alter W or any registers.
;

bne	macro	addr
	btfss	STATUS,Z
	goto	addr
	endm


;
;  FOR (start of FOR-NEXT loop)
;
;  Syntax:
;		for	var,begl,endl
;
;  The FOR macro starts a FOR-NEXT loop.  The arguments are:
;  var is a RAM variable used as the loop index,
;  begl is a literal value used as the initial index value,
;  endl is a literal value used as the ending index value.
;
;  Control will run through the FOR-NEXT loop until the value
;  in var EQUALS the endl literal value; the value is tested
;  at the top of the loop.  At this point, control exits the
;  loop at the corresponding NEXT macro.
;
;  This macro destroys the contents of the W register.
;
;  You may terminate a FOR loop with NEXT, NEXTL, or NEXTF.
;

for	macro	var,begl,endl
	movlw	begl
	movwf	var
_for#v(_forknt)
	movlw	endl
	subwf	var,w
;	movf	var,w
;	sublw	endl
	beq	_next#v(_forknt)
_forknt	set	_forknt+1
_nxtknt	set	_forknt
	endm


;
;  FORF (start of FORF-NEXT loop)
;
;  Syntax:
;		forf	var,begl,endf
;
;  The FORF macro starts a FORF-NEXT loop.  The arguments are:
;  var is a RAM variable used as the loop index,
;  begl is a literal value used as the initial index value,
;  endf is a flag or RAM variable used as the ending index
;  value.
;
;  Control will run through the FORF-NEXT loop until the value
;  in var EQUALS the endf variable value; the value is tested
;  at the top of the loop.  At this point, control exits the
;  loop at the corresponding NEXT macro.
;
;  This macro destroys the contents of the W register.
;
;  You may terminate a FORF loop with NEXT, NEXTL, or NEXTF.
;

forf	macro	var,begl,endf
	movlw	begl
	movwf	var
_for#v(_forknt)
	movf	var,w
	subwf	endf
	beq	_next#v(_forknt)
_forknt	set	_forknt+1
_nxtknt	set	_forknt
	endm


;
;  NEXT (end of a FOR-NEXT loop)
;
;  Syntax:
;		next	var
;
;  The NEXT macro terminates a FOR-NEXT loop.  The 
;  argument is:
;  var is a RAM variable that is the index of the FOR-NEXT loop.
;
;  Control will increment the value in var, then go back to
;  the top of the FOR-NEXT loop for testing.  Note that the var
;  argument for the NEXT macro must match the var argument for
;  the corresponding FOR macro.  The macro library does not perform
;  this check for you; you have to get it right yourself!
;
;  This macro alters the contents of the W register and the index
;  variable var.
;
;  You may use NEXT to terminate a FOR-NEXT, FORF-NEXT, or
;  FORL-NEXT loop.
;

next	macro	var
_nxtknt	set	_nxtknt-1
	incf	var,f
	goto	_for#v(_nxtknt)
_next#v(_nxtknt)
	endm


;
;  NEXTL (end of a FOR-NEXTL loop)
;
;  Syntax:
;		nextl	var,incl
;
;  The NEXTL macro terminates a FOR-NEXTL loop.  The 
;  arguments are:
;  var is a RAM variable that is the index of the FOR-NEXTL loop,
;  incl is a literal value used to modify the index.
;
;  Control will add the literal incl to the value in var, then
;  go back to the top of the FOR-NEXTL loop for testing.  Note
;  that the var argument for the NEXTL macro must match the var
;  argument for the corresponding FOR macro.  The macro library
;  does not perform this check for you; you have to get it right
;  yourself!
;
;  This macro alters the contents of the W register and the index
;  variable var.
;
;  You may use NEXTL to terminate a FOR-NEXTL, FORF-NEXTL, or
;  FORL-NEXTL loop.
;
;  NOTE:  This macro uses the addlw instruction, which is not
;  supported on the older PICs, such as the 16c54.  Using this
;  macro in a source file for such a chip will generate assembler
;  errors.
;

nextl	macro	var,incl
_nxtknt	set	_nxtknt-1
	movf	var,w
	addlw	incl
	movwf	var
	goto	_for#v(_nxtknt)
_next#v(_nxtknt)
	endm


;
;  NEXTF (end of a FOR-NEXTF loop)
;
;  Syntax:
;		nextf	var,incf
;
;  The NEXTF macro terminates a FOR-NEXTF loop.  The 
;  arguments are:
;  var is a RAM variable that is the index of the FOR-NEXTL loop,
;  incf is a register whose value is used to modify the index.
;
;  Control will add the value in incf to the value in var, then
;  go back to the top of the FOR-NEXTF loop for testing.  Note
;  that the var argument for the NEXTF macro must match the var
;  argument for the corresponding FOR macro.  The macro library
;  does not perform this check for you; you have to get it right
;  yourself!
;
;  This macro alters the contents of the W register and the index
;  variable var.
;
;  You may use NEXTF to terminate a FOR-NEXTF, FORF-NEXTF, or
;  FORL-NEXTF loop.
;

nextf	macro	var,incf
_nxtknt	set	_nxtknt-1
	movf	var,w
	addwf	incf,f
	goto	_for#v(_nxtknt)
_next#v(_nxtknt)
	endm


;
;  REPEAT (start of a REPEAT-ALWAYS or REPEAT-UNTIL loop)
;
;  Syntax:
;		repeat
;
;  The REPEAT macro marks the start of a REPEAT-ALWAYS or
;  REPEAT-UNTILEQ or REPEAT-UNTILNE loop.  Control will always
;  return to the start of the REPEAT macro if the loop is
;  terminated with an ALWAYS macro.  Control will conditionally
;  return to the start of the REPEAT macro if the loop is
;  terminated with an UNTILEQ or UNTILNE macro.
;
;  This macro does not alter the W register.
;

repeat	macro
_rpt#v(_rptknt)
_rptknt	set	_rptknt+1
_alwknt	set	_rptknt
_untknt	set	_rptknt
	endm


;
;  ALWAYS (returns to corresponding REPEAT macro)
;
;  Syntax:
;		always
;
;  The ALWAYS macro marks the end of a REPEAT-ALWAYS loop.
;  Control is automatically passed back to the corresponding
;  REPEAT macro.
;
;  This macro does not alter the W register.
;

always	macro
_alwknt	set	_alwknt-1
	goto	_rpt#v(_alwknt)
	endm


;
;  UNTILEQ (conditionally returns to corresponding REPEAT macro)
;
;  Syntax:
;		untileq
;
;  The UNTILEQ macro marks the end of a REPEAT-UNTILEQ loop.
;  Control is passed back to the corresponding REPEAT macro only
;  if the Z-bit is cleared at the time the UNTILEQ macro is
;  processed.
;
;  This macro does not alter the W register.
;

untileq	macro
_untknt	set	_untknt-1
	bne	_rpt#v(_untknt)
	endm


;
;  UNTILNE (conditionally returns to corresponding REPEAT macro)
;
;  Syntax:
;		untilne
;
;  The UNTILEQ macro marks the end of a REPEAT-UNTILNE loop.
;  Control is passed back to the corresponding REPEAT macro only
;  if the Z-bit is set at the time the UNTILNE macro is processed.
;
;  This macro does not alter the W register.
;

untilne	macro
_untknt	set	_untknt-1
	beq	_rpt#v(_untknt)
	endm


;
;  SELECT (declares start of SELECT-ENDSELECT structure)
;
;  Syntax:
;		select
;
;  The SELECT macro marks the beginning of a SELECT-ENDSELECT
;  structure.  A typical SELECT-ENDSELECT structure looks like this:
;
;	select			; start of SELECT block
;	case	5		; if W = 5...
;	  .			; do something
;	endcase			; end of W = 5 clause
;	casef	foo		; if W = foo
;	  .			; do something else
;	endcase			; end of W = foo clause
;	  .			; default action (all cases fail)
;	endselect		; end of SELECT block
;
;  This macro does not alter the W register.
;

select	macro
_seltot	set	_seltot+1
_selknt	set	_seltot
	endm


;
;  ENDSELECT (declares end of SELECT-ENDSELECT structure)
;
;  Syntax:
;		endselect
;
;  The ENDSELECT macro marks the end of a SELECT-ENDSELECT
;  structure.  You must terminate each SELECT macro with
;  a matching ENDSELECT macro or MPASM will report errors.
;
;  This macro does not alter the W register.
;

endselect	macro
sel#v(_selknt)
_selknt	set	_selknt-1
	endm


;
;  CASE (declares start of a CASE-ENDCASE structure)
;
;  Syntax:
;		case	lit
;
;  where lit is a literal value used as the CASE selector.
;
;  When the CASE macro is executed, the value in W is compared
;  with the literal value lit.  If W equals lit, code following
;  the CASE macro is executed.  If W does not equal lit, control
;  passes to the code following the corresponding ENDCASE macro.
;
;  W is preserved in the CASE macro.
;

case	macro	lit
_castot set	_castot+1
_casknt	set	_castot
	xorlw	lit
	beq	cas#v(_casknt)
	xorlw	lit
	goto	ecas#v(_casknt)
cas#v(_casknt)
	xorlw	lit
	endm


;
;  CASEF (declares start of a CASEF-ENDCASE structure)
;
;  Syntax:
;		casef	var
;
;  where var is a register or variable used as the CASEF selector.
;
;  When the CASEF macro is executed, the value in W is compared
;  with the value in var.  If W equals var, code following
;  the CASEF macro is executed.  If W does not equal var, control
;  passes to the code following the corresponding ENDCASE macro.
;
;  W is preserved in the CASEF macro.
;

casef	macro	var
_castot set	_castot+1
_casknt	set	_castot
	xorwf	var,w
	beq	cas#v(_casknt)
	xorwf	var,w
	goto	ecas#v(_casknt)
cas#v(_casknt)
	xorwf	var,w
	endm


;
;  ENDCASE (declares end of a CASE-ENDCASE or CASEF-ENDCASE structure)
;
;  Syntax:
;		endcase
;
;  The ENDCASE macro marks the end of a CASE-ENDCASE or CASEF-ENDCASE
;  structure.  This macro serves as a jump address for the corresponding
;  CASE or CASEF macro.
;
;  You must have an ENDCASE macro for each CASE or CASEF macro.  If
;  not, MPASM will report errors when it assembles your code.
;
;  This macro preserves the W register.
;

endcase	macro
	goto	sel#v(_selknt)
ecas#v(_casknt)
_casknt	set	_casknt-1
	endm


;
;  WAITWHILE (declares a high-speed WAIT-WHILE loop)
;
;  Syntax:
;
;  		waitwhile	addr,andl,xorl
;
;  The WAITWHILE macro creates a tight loop that reads the byte
;  in address addr, ANDs it with the literal andl, then XORs the
;  result with the literal xorl.  If the result is TRUE (non-zero),
;  the loop repeats.  If the result is FALSE (zero), control exits
;  the macro.
;
;  This macro destroys the W register.  It does not modify addr.
;

waitwhile	macro	addr,andl,xorl
waitw#v(_waitk)
	movf	addr,w
	andlw	andl
	if	xorl != 0
	xorlw	xorl
	endif
	bne	waitw#v(_waitk)
_waitk	set	_waitk+1
	endm


;
;  WAITUNTIL (declares a high-speed WAIT-UNTIL loop)
;
;  Syntax:
;
;  		waituntil	addr,andl,xorl
;
;  The WAITUNTIL macro creates a tight loop that reads the byte
;  in address addr, ANDs it with the literal andl, then XORs the
;  result with the literal xorl.  If the result is TRUE (non-zero),
;  control exits the macro.  If the result is FALSE (zero),
;  the loop repeats.
;
;  This macro destroys the W register.  It does not modify addr.
;


waituntil	macro	addr,andl,xorl
waitw#v(_waitk)
	movf	addr,w
	andlw	andl
	if	xorl != 0
	xorlw	xorl
	endif
	beq	waitw#v(_waitk)
_waitk	set	_waitk+1
	endm


;
;  POLL (starts a POLL-ENDPOLL structure)
;
;  Syntax:
;
;  		poll	addr,andl,xorl
;
;  The POLL macro reads the byte in address addr, ANDs it with
;  the literal andl, then XORs the result with the literal xorl.
;  If the result is TRUE (non-zero), control passes to the code
;  immediately following the macro.  If the result is FALSE
;  (zero), control jumps to the corresponding ENDPOLL macro.
;
;  For example, the following POLL command will test the address
;  SPORT for bit 3 high:
;
;	poll	SPORT,8,0		test bit 3
;	nop				do this if bit 3 is high
;	endpoll
;
;  The following POLL command will test the address SPORT for
;  bit 3 high while either bits 2 or 1 are low:
;
;	poll	SPORT,0x0e,0x06		test bits 1-3
;	nop				do if 3 is high, 1 or 2 is low
;	endpoll
;
;  This macro destroys the W register.  It does not modify addr.
;


poll	macro	addr,andl,xorl
_pollt	set	_pollt+1
_pollk	set	_pollt
	movf	addr,w
	andlw	andl
	xorlw	xorl
	beq	poll#v(_pollk)
	endm


;
;  ENDPOLL (marks end of a POLL-ENDPOLL structure)
;
;  The ENDPOLL macro terminates a POLL-ENDPOLL structure.
;  Control reaches this macro if the associated POLL macro
;  fails.
;

endpoll	macro
poll#v(_pollk)
_pollk	set	_pollk-1
	endm




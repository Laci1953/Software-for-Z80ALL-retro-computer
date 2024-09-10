;
;	Graphic characters	
;

	psect	bss

Fonts_0_10:	defs	11 * 8

	psect	data
CUSTOM0:	defb	11111111B
		defb	10000001B
		defb	10000001B
		defb	10000001B
		defb	10000001B
		defb	10000001B
		defb	10000001B
		defb	11111111B
;
CUSTOM1:	defb	00111100B
		defb	01000010B
		defb	10000001B
		defb	10000001B
		defb	10000001B
		defb	10000001B
		defb	01000010B
		defb	00111100B
;
CUSTOM2:	defb	10000001B
		defb	10000001B
		defb	01000010B
		defb	00111100B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
CUSTOM3:	defb	00000011B
		defb	00000100B
		defb	00001000B
		defb	00001000B
		defb	00001000B
		defb	00001000B
		defb	00000100B
		defb	00000011B
;
CUSTOM4:	defb	00001000B
		defb	00001000B
		defb	00000100B
		defb	00000011B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
CUSTOM5:	defb	00000000B
		defb	00000000B
		defb	00111100B
		defb	01000010B
		defb	10000001B
		defb	10000001B
		defb	10000001B
		defb	10000001B
;
CUSTOM6:	defb	10000001B
		defb	10000001B
		defb	10000001B
		defb	10000001B
		defb	01000010B
		defb	00111100B
		defb	00000000B
		defb	00000000B
;
CUSTOM7:	defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00111100B
		defb	01000010B
		defb	10000001B
		defb	10000001B
;
CUSTOM8:	defb	00000000B
		defb	00000000B
		defb	00000011B
		defb	00000100B
		defb	00001000B
		defb	00001000B
		defb	00001000B
		defb	00001000B
;
CUSTOM9:	defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000011B
		defb	00000100B
		defb	00001000B
		defb	00001000B
;
CUSTOM10:	defb	00001000B
		defb	00001000B
		defb	00001000B
		defb	00001000B
		defb	00000100B
		defb	00000011B
		defb	00000000B
		defb	00000000B

	psect	text
;
;	Save fonts (11 chars)
;
_Save_0_to_10::
	ld	e,11 * 8		;counter
	ld	c,0EH			;character values 0x40 to ...
	ld	b,0			;(40H)
	ld	hl,Fonts_0_10
1:
	in	a,(c)
	ld	(hl),a
	inc	hl
	inc	b
	dec	e
	jr	nz,1b
	ret
;
;	Load fonts 
;
_Load_0_to_10::
	ld	hl,CUSTOM0		;font bitmaps
Load_0:
	ld	e,11 * 8		;counter
	ld	c,0EH			;character values 0x40 to ...
	ld	b,0			;(0H)
1:
	ld	a,(hl)
	out	(c),a
	inc	hl
	inc	b
	dec	e
	jr	nz,1b
	ret
;
;	Restore fonts 
;
_Restore_0_to_10::
	ld	hl,Fonts_0_10
	jr	Load_0
;

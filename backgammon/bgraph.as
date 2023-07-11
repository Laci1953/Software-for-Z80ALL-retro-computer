;
;	Graphic characters	
;

	global	_Save_fonts
	global	_Load_fonts
	global	_Restore_fonts

	psect	data

Fonts:	defs	4 * 8

CUSTOM1:	defb	00000011B
		defb	00000111B
		defb	00001111B
		defb	00001111B
		defb	00001111B
		defb	00001111B
		defb	00000111B
		defb	00000011B
;
CUSTOM2:	defb	11000000B
		defb	11100000B
		defb	11110000B
		defb	11110000B
		defb	11110000B
		defb	11110000B
		defb	11100000B
		defb	11000000B
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
CUSTOM4:	defb	11000000B
		defb	00100000B
		defb	00010000B
		defb	00010000B
		defb	00010000B
		defb	00010000B
		defb	00100000B
		defb	11000000B
;

	psect	text
;
;	Save fonts (23H to 26H)
;
_Save_fonts:
	ld	e,4 * 8			;counter
	ld	c,0DH			;character values 0x20 to 0x3F
	ld	b,24			;+3
	ld	hl,Fonts
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
_Load_fonts:
	ld	hl,CUSTOM1		;font bitmaps
Load_1:
	ld	e,4 * 8			;counter
	ld	c,0DH			;character values 0x20 to 0x3F
	ld	b,24			;+3
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
_Restore_fonts:
	ld	hl,Fonts
	jr	Load_1
;

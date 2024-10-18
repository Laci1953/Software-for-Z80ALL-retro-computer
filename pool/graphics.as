;
;	Graphic characters	
;

	psect	bss

Fonts_0_11:	defs	12 * 8

	psect	data
;
CUSTOM0:	defb	00111100B
		defb	01111110B
		defb	11111111B
		defb	11111111B
		defb	11111111B
		defb	11111111B
		defb	01111110B
		defb	00111100B

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
; second set

BCUSTOM0:	defb	00111100B
		defb	01000010B
		defb	10000001B
		defb	10000001B
		defb	10000001B
		defb	10000001B
		defb	01000010B
		defb	00111100B
;
BCUSTOM1:	defb	00111100B
		defb	01111110B
		defb	11111111B
		defb	11111111B
		defb	11111111B
		defb	11111111B
		defb	01111110B
		defb	00111100B
;
BCUSTOM2:	defb	11111111B
		defb	11111111B
		defb	01111110B
		defb	00111100B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
BCUSTOM3:	defb	00000011B
		defb	00000111B
		defb	00001111B
		defb	00001111B
		defb	00001111B
		defb	00001111B
		defb	00000111B
		defb	00000011B
;
BCUSTOM4:	defb	00001111B
		defb	00001111B
		defb	00000111B
		defb	00000011B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
BCUSTOM5:	defb	00000000B
		defb	00000000B
		defb	00111100B
		defb	01111110B
		defb	11111111B
		defb	11111111B
		defb	11111111B
		defb	11111111B
;
BCUSTOM6:	defb	11111111B
		defb	11111111B
		defb	11111111B
		defb	11111111B
		defb	01111110B
		defb	00111100B
		defb	00000000B
		defb	00000000B
;
BCUSTOM7:	defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00111100B
		defb	01111110B
		defb	11111111B
		defb	11111111B
;
BCUSTOM8:	defb	00000000B
		defb	00000000B
		defb	00000011B
		defb	00000111B
		defb	00001111B
		defb	00001111B
		defb	00001111B
		defb	00001111B
;
BCUSTOM9:	defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000011B
		defb	00000111B
		defb	00001111B
		defb	00001111B
;
BCUSTOM10:	defb	00001111B
		defb	00001111B
		defb	00001111B
		defb	00001111B
		defb	00000111B
		defb	00000011B
		defb	00000000B
		defb	00000000B
;
CH_BASE:
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	10000000B
		defb	11000000B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	10000000B
		defb	11000000B
		defb	10000000B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	10000000B
		defb	11000000B
		defb	10000000B
		defb	00000000B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	10000000B
		defb	11000000B
		defb	10000000B
		defb	00000000B
		defb	00000000B
;
		defb	00000000B
		defb	00000000B
		defb	10000000B
		defb	11000000B
		defb	10000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00000000B
		defb	10000000B
		defb	11000000B
		defb	10000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	10000000B
		defb	11000000B
		defb	10000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	11000000B
		defb	10000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;+8*8
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	01000000B
		defb	11100000B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	01000000B
		defb	11100000B
		defb	01000000B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	01000000B
		defb	11100000B
		defb	01000000B
		defb	00000000B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	01000000B
		defb	11100000B
		defb	01000000B
		defb	00000000B
		defb	00000000B
;
		defb	00000000B
		defb	00000000B
		defb	01000000B
		defb	11100000B
		defb	01000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00000000B
		defb	01000000B
		defb	11100000B
		defb	01000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	01000000B
		defb	11100000B
		defb	01000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	11100000B
		defb	01000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;+16*8
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00100000B
		defb	01110000B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00100000B
		defb	01110000B
		defb	00100000B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00100000B
		defb	01110000B
		defb	00100000B
		defb	00000000B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00100000B
		defb	01110000B
		defb	00100000B
		defb	00000000B
		defb	00000000B
;
		defb	00000000B
		defb	00000000B
		defb	00100000B
		defb	01110000B
		defb	00100000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00000000B
		defb	00100000B
		defb	01110000B
		defb	00100000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00100000B
		defb	01110000B
		defb	00100000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	01110000B
		defb	00100000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;+24*8
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00010000B
		defb	00111000B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00010000B
		defb	00111000B
		defb	00010000B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00010000B
		defb	00111000B
		defb	00010000B
		defb	00000000B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00010000B
		defb	00111000B
		defb	00010000B
		defb	00000000B
		defb	00000000B
;
		defb	00000000B
		defb	00000000B
		defb	00010000B
		defb	00111000B
		defb	00010000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00000000B
		defb	00010000B
		defb	00111000B
		defb	00010000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00010000B
		defb	00111000B
		defb	00010000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00111000B
		defb	00010000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;+32*8
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00001000B
		defb	00011100B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00001000B
		defb	00011100B
		defb	00001000B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00001000B
		defb	00011100B
		defb	00001000B
		defb	00000000B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00001000B
		defb	00011100B
		defb	00001000B
		defb	00000000B
		defb	00000000B
;
		defb	00000000B
		defb	00000000B
		defb	00001000B
		defb	00011100B
		defb	00001000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00000000B
		defb	00001000B
		defb	00011100B
		defb	00001000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00001000B
		defb	00011100B
		defb	00001000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00011100B
		defb	00001000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;+40*8
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000100B
		defb	00001110B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000100B
		defb	00001110B
		defb	00000100B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000100B
		defb	00001110B
		defb	00000100B
		defb	00000000B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000100B
		defb	00001110B
		defb	00000100B
		defb	00000000B
		defb	00000000B
;
		defb	00000000B
		defb	00000000B
		defb	00000100B
		defb	00001110B
		defb	00000100B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00000000B
		defb	00000100B
		defb	00001110B
		defb	00000100B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00000100B
		defb	00001110B
		defb	00000100B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00001110B
		defb	00000100B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;+48*8
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000010B
		defb	00000111B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000010B
		defb	00000111B
		defb	00000010B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000010B
		defb	00000111B
		defb	00000010B
		defb	00000000B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000010B
		defb	00000111B
		defb	00000010B
		defb	00000000B
		defb	00000000B
;
		defb	00000000B
		defb	00000000B
		defb	00000010B
		defb	00000111B
		defb	00000010B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00000000B
		defb	00000010B
		defb	00000111B
		defb	00000010B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00000010B
		defb	00000111B
		defb	00000010B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00000111B
		defb	00000010B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;+56*8
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000001B
		defb	00000011B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000001B
		defb	00000011B
		defb	00000001B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000001B
		defb	00000011B
		defb	00000001B
		defb	00000000B
;
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000001B
		defb	00000011B
		defb	00000001B
		defb	00000000B
		defb	00000000B
;
		defb	00000000B
		defb	00000000B
		defb	00000001B
		defb	00000011B
		defb	00000001B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00000000B
		defb	00000001B
		defb	00000011B
		defb	00000001B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00000001B
		defb	00000011B
		defb	00000001B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;
		defb	00000011B
		defb	00000001B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
		defb	00000000B
;+64*8

	psect	text
;
;	Save fonts (12 chars)
;
_Save_0_to_11::
	ld	e,12 * 8		;counter
	ld	c,0EH			;character values 0x40 to ...
	ld	b,0			
	ld	hl,Fonts_0_11
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
Load_11:
	ld	e,11 * 8		;counter
Load_12:
	ld	c,0EH			;character values 0x40 to ...
	ld	b,0			
1:
	ld	a,(hl)
	out	(c),a
	inc	hl
	inc	b
	dec	e
	jr	nz,1b
	ret
;
_BLoad_0_to_10::
	ld	hl,BCUSTOM0		;font bitmaps
	jr	Load_11
;
;	Restore fonts 
;
_Restore_0_to_11::
	ld	hl,Fonts_0_11
	ld	e,12 * 8
	jr	Load_12
;
;void Load_CH(int XCHf, int YCHf)
;
;	loads char 0x4B with custom crosshair font
;
_Load_CH::
	ld	hl,2
	add	hl,sp
	ld	c,(hl)
	inc	hl
	ld	b,(hl)			;BC=XCHf
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)			;DE=YCHf
	ld	hl,CH_BASE
	sla	c
	rl	b
	sla	c
	rl	b
	sla	c
	rl	b			
	sla	c
	rl	b			
	sla	c
	rl	b			
	sla	c
	rl	b			;BC=64 * XCHf
	add	hl,bc
	sla	e
	rl	d
	sla	e
	rl	d
	sla	e
	rl	d			;DE=8 * YCHf
	add	hl,de
	ld	e,8
	ld	c,0EH
	ld	b,11*8
1:
	ld	a,(hl)
	out	(c),a
	inc	hl
	inc	b
	dec	e
	jr	nz,1b
	ret

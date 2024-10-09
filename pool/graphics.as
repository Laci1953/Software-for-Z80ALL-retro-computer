;
;	Graphic characters	
;

	psect	bss

Fonts_0_10:	defs	11 * 8

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

	psect	text
;
;	Save fonts (10 chars)
;
_Save_0_to_10::
	ld	e,11 * 8		;counter
	ld	c,0EH			;character values 0x40 to ...
	ld	b,0			
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
	jr	Load_0
;
;	Restore fonts 
;
_Restore_0_to_10::
	ld	hl,Fonts_0_10
	jr	Load_0
;

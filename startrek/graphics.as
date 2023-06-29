;
;	Graphic characters	
;

	global	_Save_1_to_16
	global	_Load_1_to_16
	global	_Restore_1_to_16

	psect	bss

Fonts_1_16:	defs	16 * 8

	psect	data

ENTERPRISE1	equ	1
CUSTOM1:	defb	00000000B
		defb	00000000B
		defb	01111111B
		defb	01111111B
		defb	00000000B
		defb	00000000B
		defb	00000001B
		defb	00000000B
;
ENTERPRISE2	equ	2
CUSTOM2:	defb	00001111B
		defb	00001010B
		defb	11100111B
		defb	11100001B
		defb	01110011B
		defb	11111111B
		defb	01010101B
		defb	11111111B
;
ENTERPRISE3	equ	3
CUSTOM3:	defb	11111110B
		defb	10101010B
		defb	11111100B
		defb	11000000B
		defb	10000000B
		defb	11100000B
		defb	01010000B
		defb	11100000B
;
KLINKON1	equ	4
CUSTOM4:	defb	01111100B
		defb	01100111B
		defb	00001111B
		defb	00111100B
		defb	01111000B
		defb	01001000B
		defb	01111000B
		defb	00110000B
;
KLINKON2	equ	5
CUSTOM5:	defb	01111110B
		defb	11111111B
		defb	00000000B
		defb	00100100B
		defb	00101000B
		defb	00110000B
		defb	00101000B
		defb	00100100B
;
KLINKON3	equ	6
CUSTOM6:	defb	00111110B
		defb	11100110B
		defb	11110000B
		defb	00111100B
		defb	00011110B
		defb	00010010B
		defb	00011110B
		defb	00001100B
;
		defs	8	;7
		defs	8	;8
		defs	8	;9
		defs	8	;10
		defs	8	;11
		defs	8	;12
		defs	8	;13
;
BASE1		equ	14
CUSTOM14:	defb	00011111B
		defb	00111111B
		defb	01100000B
		defb	01101100B
		defb	01101010B
		defb	01101100B
		defb	01101010B
		defb	01101100B
;
BASE2		equ	15
CUSTOM15:	defb	11111111B
		defb	11111111B
		defb	00000000B
		defb	01001110B
		defb	10101000B
		defb	11100100B
		defb	10100010B
		defb	10101110B
;
BASE3		equ	16
CUSTOM16:	defb	11111000B
		defb	11111100B
		defb	00000110B
		defb	11100110B
		defb	10000110B
		defb	11100110B
		defb	10000110B
		defb	11100110B
;

	psect	text
;
;	Save fonts for 1 to 16 (16 chars)
;
_Save_1_to_16:
	ld	e,16 * 8		;counter
	ld	c,0CH			;character values 0x0 to 0x1F
	ld	b,8			;(1)
	ld	hl,Fonts_1_16
1:
	in	a,(c)
	ld	(hl),a
	inc	hl
	inc	b
	dec	e
	jr	nz,1b
	ret
;
;	Load fonts for 1 to 16
;
_Load_1_to_16:
	ld	hl,CUSTOM1		;font bitmaps
Load_1:
	ld	e,16 * 8		;counter
	ld	c,0CH			;character values 0x0 to 0x1F
	ld	b,8			;(1)
1:
	ld	a,(hl)
	out	(c),a
	inc	hl
	inc	b
	dec	e
	jr	nz,1b
	ret
;
;	Restore fonts for 1 to 16
;
_Restore_1_to_16:
	ld	hl,Fonts_1_16
	jr	Load_1
;

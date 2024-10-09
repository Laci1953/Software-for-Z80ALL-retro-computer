
        psect   text

	global	BiosConout
;
;void   Clear(void)
;
_Clear::
        ld      a,' '
        ld      bc,0BH          ;go to last group of 4 lines, first column
clr4lines:
        out     (c),a
        djnz    clr4lines
        dec     c               ;decrement 4 lines group #
        jp      p,clr4lines     ;if C >= 0 , repeat
        ret
;
;void 	ClearTopLine(void)
;
_ClearTopLine::
	ld	bc,0		;first group of 4 lines, first column
	ld	a,' '
	ld	e,40h
1:
	out	(c),a
	inc	b
	dec	e
	jr	nz,1b
	ret

;void	SetCursor
;	sets the cursor at top row, column 53
_SetCursor::
	ld	c,1BH		;ESC
	call	BiosConout
	ld	c,59H		;Y
	call	BiosConout
	ld	c,32		;row 1
	call	BiosConout
	ld	c,91		;col 60
	jp	BiosConout

;void   PrintChar(int Y, int X, char ch)
;       Y=0...47 bottom to top
;       X=0...63 left to right
;
_PrintChar::
        ld      hl,2
        add     hl,sp
				;(HL)=row
	ld	a,47		;transform-it into top to bottom
	sub	(hl)
	ld	c,a		;C=row (top to bottom)
        inc     hl
        inc     hl
        ld      e,(hl)          ;E=col
	inc	hl
	inc	hl
	ld	d,(hl)		;D=ch
        xor     a               ;init A=col index#
        srl     c               ;shift right row#
        jr      nc,1f
        add     a,64            ;if Carry then col index# += 64
1:
        srl     c               ;shift right row#
        jr      nc,2f
        add     a,128           ;if Carry then col index# += 128
2:
        add     a,e             ;add col#
        ld      b,a             ;B=col index#
	ld	a,d		;A=ch
	out	(c),a		;print char
        ret
;
;void   PrintStr(int Y, int X, char* p)
;       Y=0...47 bottom to top
;       X=0...63 left to right
;
_PrintStr::
        ld      hl,2
        add     hl,sp
				;(HL)=row
	ld	a,47		;transform-it into top to bottom
	sub	(hl)
	ld	c,a		;C=row (top to bottom)
        inc     hl
        inc     hl
        ld      e,(hl)          ;E=col
	inc	hl
	inc	hl
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a		;HL=pointer to string
        xor     a               ;init A=col index#
        srl     c               ;shift right row#
        jr      nc,1f
        add     a,64            ;if Carry then col index# += 64
1:
        srl     c               ;shift right row#
        jr      nc,2f
        add     a,128           ;if Carry then col index# += 128
2:
        add     a,e             ;add col#
        ld      b,a             ;B=col index#
3:
	ld	a,(hl)		;A=ch
	or	a
	ret	z
	out	(c),a		;print char
	inc	hl
	inc	b
	jr	3b
;
	
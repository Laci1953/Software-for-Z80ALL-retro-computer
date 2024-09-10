
         psect   text

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
	
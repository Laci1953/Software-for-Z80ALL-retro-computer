
	psect	text

;void CrtSetup(void)
global _CrtSetup
_CrtSetup:
	ld  	hl,(1)
	inc 	hl
	inc 	hl
	inc 	hl
	ld  	de,BiosConst
	ld  	bc,9
	ldir
	ret

BiosConst:  jp 0
BiosConin:  jp 0
BiosConout::jp 0

;void CrtOut(char)
global _CrtOut
_CrtOut:
        ld      hl,2
        add     hl,sp
        ld      c,(hl)  	;ch
        jp   	BiosConout

;char CrtIn(void)
global _CrtIn
_CrtIn:
	call 	BiosConin
	ld 	h,0
	ld 	l,a
	ret

;char CrtSts(void)
global _CrtSts
_CrtSts:
	call	BiosConst
	ld	h,0
	ld	l,a
	ret

;void putstr(char*)
global _putstr
_putstr:
        ld      hl,2
        add     hl,sp
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
1:      ld      a,(hl)
        or      a
        ret     z
        inc     hl
        ld      c,a
        push    hl
        call    BiosConout
        pop     hl
        jr      1b

;void getstr(char*)
global _getstr
_getstr:
	ld	hl,2
	add	hl,sp
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
1:	push	de
	call	BiosConin
	pop	de
	cp	0DH
	jr	nz,2f
	xor	a
	ld	(de),a
	ret
2:	ld	(de),a
	ld	c,a
	push	de
	call	BiosConout
	pop	de
	inc	de
	jr	1b

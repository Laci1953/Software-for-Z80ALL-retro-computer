;
;	Implements two heap mechanism
;
	psect	text

        global  _sbrk, _brk

HEAP	equ	0CA00H	;for file buffers

_brk:
        pop     hl      ;return address
        pop     de      ;argument
        ld      (memtop),de     ;store it
        push    de              ;adjust stack
        jp      (hl)    ;return
_sbrk:
        pop     bc
        pop     de
        push    de
        push    bc
        ld      hl,(memtop)
	ld	a,h
	or	l
	jr	nz,notzero
	ld	hl,HEAP
	ld	(memtop),hl
notzero:
        add     hl,de
        jr      c,2f            ;if overflow, no room
        ld      bc,512          ;allow 512 bytes stack overhead
        add     hl,bc
        jr      c,2f            ;if overflow, no room
        sbc     hl,sp
        jr      c,1f
2:
        ld      hl,-1           ;no room at the inn
        ret

1:      ld      hl,(memtop)
        push    hl
        add     hl,de
        ld      (memtop),hl
        pop     hl
        ret

	psect	bss

memtop:	defs	2


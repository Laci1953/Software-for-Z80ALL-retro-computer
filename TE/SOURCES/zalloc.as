;
;	Dynamic memory allocator
;
;	uses sequential allocation, optimal for capacity
;
;	must be stored above 8000H
;
BUF_START	equ	1
BUF_END		equ	8000H

	psect   bss

_pBigBuf0:
	defs    2
_pBigBuf1:
	defs    2

	psect   top

	global  _InitDynM

_InitDynM:
	ld      hl,BUF_START
	ld      (_pBigBuf0),hl
	ld      (_pBigBuf1),hl
	ret

	global  _Alloc

;void*	Alloc(short size, char* flag);

_Alloc:
	ld	hl,2
	add	hl,sp
	ld	c,(hl)
	ld	b,0		;BC=size
	ld	de,BUF_END+1	;DE=buffer end + 1
				;try first bank
	ld      hl,(_pBigBuf0)
	add	hl,bc		;HL=pointer+size, CARRY=0
	sbc	hl,de		;pointer+size ? buffer end
	jr	nc,try2
				;less or equal
	xor	a		;bank=0
	add	hl,de		;HL=pointer+size
	ld	de,(_pBigBuf0)	;DE=old pointer, to be returned
	ld	(_pBigBuf0),hl	;update pointer
savebank:
	ld	hl,4
	add	hl,sp
	ld	c,(hl)
	inc	hl
	ld	b,(hl)		;BC=bank pointer
	ld	(bc),a		;save bank
	ex	de,hl		;return old pointer
	ret
try2:				;try second bank
	ld      hl,(_pBigBuf1)
	add	hl,bc		;HL=pointer+size, CARRY=0
	sbc	hl,de		;pointer+size ? buffer end
	jr	nc,full
				;less or equal
	ld	a,1		;bank=1
	add	hl,de		;HL=pointer+size
	ld	de,(_pBigBuf1)	;DE=old pointer, to be returned
	ld	(_pBigBuf1),hl	;update pointer
	jr	savebank
full:
	ld	hl,0		;full, return NULL
	ret

	global  _Free
_Free:
	ret

	global  _GetTotalFree

;unsigned int GetTotalFree(void)

_GetTotalFree:
	xor	a		;CARRY=0
	ld	hl,BUF_END
	ld	bc,(_pBigBuf0)
	sbc	hl,bc
	ex	de,hl
	xor	a		;CARRY=0
	ld	hl,BUF_END
	ld	bc,(_pBigBuf1)
	sbc	hl,bc
	add	hl,de
	ret

	global  _GetString

;void	GetString(char* dest, char* source, char source_flag)

_GetString:
	ld	hl,6
	add	hl,sp
	ld      a,(hl)		;bank
	inc	a		;+1
	ld	c,1FH		;port
	out	(c),a		;select bank+1
	dec	hl
	ld	d,(hl)
	dec	hl
	ld	e,(hl)		;DE=source
	dec	hl
	ld	a,(hl)
	dec	hl
	ld	l,(hl)
	ld	h,a		;HL=dest
move:	ld	a,(de)		;move string (DE) -> (HL)
	ld	(hl),a
	inc	de
	inc	hl
	or	a
	jr	nz,move
				;A=0
	out	(c),a		;select 0		
	ret

global  _PutString

;void	PutString(char* source, char* dest, char dest_flag)

_PutString:
	ld	hl,6
	add	hl,sp
	ld      a,(hl)		;bank
	inc	a		;+1
	ld	c,1FH		;port
	out	(c),a		;select bank+1
	dec	hl
	ld	d,(hl)
	dec	hl
	ld	e,(hl)		;DE=dest
	dec	hl
	ld	a,(hl)
	dec	hl
	ld	l,(hl)
	ld	h,a		;HL=source
	ex	de,hl
	jr	move

	global  _StringLen

;short	StringLen(char* s, char s_flag)

_StringLen:
	ld	hl,2
	add	hl,sp
	ld	e,(hl)
	inc	hl
	ld	d,(hl)		;DE=s
	inc	hl
	ld	a,(hl)		;a=bank
	inc	a		;+1
	ld	c,1FH		;port
	out	(c),a		;select bank+1
	ld	hl,0FFH		;prepare HL
count:	ld	a,(de)
	inc	de
	inc	l
	or	a
	jr	nz,count
				;A=0
	out	(c),a		;select 0		
	ret
	
	global  _GetByte

;char	GetByte(char* vector, short index, char flag)

_GetByte:
	ld	hl,2
	add	hl,sp
	ld	e,(hl)
	inc	hl
	ld	d,(hl)		;DE=vector
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)		;BC=index
	ex	de,hl
	add	hl,bc		;HL=vector+index
	ld	l,(hl)
	ret

	global  _PutByte

;void	PutByte(char* vector, short index, char byte, char flag)

_PutByte:
	ld	hl,2
	add	hl,sp
	ld	e,(hl)
	inc	hl
	ld	d,(hl)		;DE=vector
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)		;BC=index
	inc	hl
	ld	a,(hl)		;A=byte
	ex	de,hl
	add	hl,bc		;HL=vector+index
	ld	(hl),a
	ret

	global  _GetWord

;char*	GetWord(char* vector, short index, char flag)

_GetWord:
	ld	hl,2
	add	hl,sp
	ld	e,(hl)
	inc	hl
	ld	d,(hl)		;DE=vector
	inc	hl
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a		;HL=index
	add	hl,hl		;HL=index*2
	add	hl,de		;HL=vector+index*2
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a		;HL=word
	ret

	global  _PutWord

;void	PutWord(char* vector, short index, short word, char flag)

_PutWord:
	ld	hl,2
	add	hl,sp
	ld	e,(hl)
	inc	hl
	ld	d,(hl)		;DE=vector
	inc	hl
	ld	c,(hl)
	inc	hl
	ld	b,(hl)		;BC=index
	inc	hl
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a		;HL=word
	ex	de,hl		;HL=vector,DE=word
	sla	c
	rl	b		;BC=BC*2
	add	hl,bc		;HL=vector+index*2
	ld	(hl),e		;store word
	inc	hl
	ld	(hl),d
	ret
;

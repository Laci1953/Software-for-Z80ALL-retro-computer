;
;	Z80ALL real time clock support library
;
	global	_InitRTC
	global	_GetTime
	global	_GetStartTime
	global	_GetStopTime
	global	_PrintLapseTime
;
;********************************************************************
;	Time lapse computing
;
	psect	bss

StartTime:	defs	3	;H,M,S
StopTime:	defs	3	;H,M,S
DeltaTime:	defs	3	;H,M,S
;
StartSecs:	defs	2
StopSecs:	defs	2
DeltaSecs:	defs	2
;
	psect	data
;
TimeLapse:	defs	8	;00:00:00 using ASCII decimal digits
		defb	'$'

	psect	text

;**************************************************************************
;	16 bit divide and modulus routines

;	called with dividend in hl and divisor in de

;	returns with result in hl.

;	adiv (amod) is signed divide (modulus), ldiv (lmod) is unsigned

amod:
	call	adiv
	ex	de,hl		;put modulus in hl
	ret

lmod:
	call	ldiv
	ex	de,hl
	ret

ldiv:
	xor	a
	ex	af,af'
	ex	de,hl
	jr	dv1

adiv:
	ld	a,h
	xor	d		;set sign flag for quotient
	ld	a,h		;get sign of dividend
	ex	af,af'
	call	negif16
	ex	de,hl
	call	negif16
dv1:	ld	b,1
	ld	a,h
	or	l
	ret	z
dv8:	push	hl
	add	hl,hl
	jr	c,dv2
	ld	a,d
	cp	h
	jr	c,dv2
	jp	nz,dv6
	ld	a,e
	cp	l
	jr	c,dv2
dv6:	pop	af
	inc	b
	jp	dv8

dv2:	pop	hl
	ex	de,hl
	push	hl
	ld	hl,0
	ex	(sp),hl

dv4:	ld	a,h
	cp	d
	jr	c,dv3
	jp	nz,dv5
	ld	a,l
	cp	e
	jr	c,dv3

dv5:	sbc	hl,de
dv3:	ex	(sp),hl
	ccf
	adc	hl,hl
	srl	d
	rr	e
	ex	(sp),hl
	djnz	dv4
	pop	de
	ex	de,hl
	ex	af,af'
	call	m,negat16
	ex	de,hl
	or	a			;test remainder sign bit
	call	m,negat16
	ex	de,hl
	ret

negif16:bit	7,h
	ret	z
negat16:ld	b,h
	ld	c,l
	ld	hl,0
	or	a
	sbc	hl,bc
	ret

;	16 bit integer multiply

;	on entry, left operand is in hl, right operand in de

amul:
lmul:
	ld	a,e
	ld	c,d
	ex	de,hl
	ld	hl,0
	ld	b,8
	call	mult8b
	ex	de,hl
	jr	3f
2:	add	hl,hl
3:
	djnz	2b
	ex	de,hl
1:
	ld	a,c
mult8b:
	srl	a
	jp	nc,1f
	add	hl,de
1:	ex	de,hl
	add	hl,hl
	ex	de,hl
	ret	z
	djnz	mult8b
	ret
;
;***********************************************************
; POSITIVE INTEGER DIVISION
;   inputs hi=A lo=D, divide by E
;   output D, remainder in A
;***********************************************************
DIVIDE: PUSH    bc
        LD      b,8
DD04:   SLA     d
        RLA
        SUB     e
        JP      M,rel027
        INC     d
        JR      rel024
rel027: ADD     a,e
rel024: DJNZ    DD04
        POP     bc
        RET
;
;********************************************************************
;
;	Computes DeltaTime = StopTime - StartTime
;	convert-it to ASCII 
;	and store-it to TimeLapse
;
ComputeLapse:
				;compute StartSecs

	ld	a,(StartTime)	;Start Hour
	ld	e,a
	ld	d,0		;DE=Start Hour
	ld	hl,3600
	call	lmul		;HL=Start Hour x 3600
	push	hl

	ld	a,(StartTime+1)	;Start Minutes
	ld	e,a
	ld	d,0
	ld	hl,60
	call	lmul		;HL=Start Minutes x 60

	ld	a,(StartTime+2)	;Start Seconds
	ld	e,a
	ld	d,0		;DE=Start Seconds

	add	hl,de
	pop	de
	add	hl,de		;HL = StartSecs
	ld	(StartSecs),hl
	
				;compute StopSecs

	ld	a,(StopTime)	;Stop Hour
	ld	e,a
	ld	d,0		;DE=Stop Hour
	ld	hl,3600
	call	lmul		;HL=Stop Hour x 3600
	push	hl

	ld	a,(StopTime+1)	;Stop Minutes
	ld	e,a
	ld	d,0
	ld	hl,60
	call	lmul		;HL=Stop Minutes x 60

	ld	a,(StopTime+2)	;Stop Seconds
	ld	e,a
	ld	d,0		;DE=Stop Seconds

	add	hl,de
	pop	de
	add	hl,de		;HL = StopSecs
	ld	(StopSecs),hl

				;compute DeltaSecs
	xor	a		;CARRY=0
	ld	de,(StartSecs)
	sbc	hl,de
	ld	(DeltaSecs),hl
				;compute DeltaTime
	ld	de,3600
	call	ldiv		;HL=DeltaSecs/3600
	ld	a,l
	ld	(DeltaTime),a	;H

	ld	hl,(DeltaSecs)
	ld	de,3600
	call	lmod		;HL=DeltaSecs modulo 3600
	push	hl
	ld	de,60
	call	ldiv		;HL=(DeltaSecs modulo 3600)/60
	ld	a,l
	ld	(DeltaTime+1),a	;M

	pop	hl
	ld	de,60
	call	lmod		;HL = (DeltaSecs modulo 3600) modulo 60
	ld	a,l
	ld	(DeltaTime+2),a	;S
				;convert DeltaTime to ASCII
				;and store-it to TimeLapse
	ld	hl,DeltaTime
	ld	bc,TimeLapse
				;HH:
	ld	a,(hl)
	inc	hl
	ld	d,a
	xor	a
	ld	e,10
	call	DIVIDE		;inputs hi=A lo=D, divide by E
				;   output D, remainder in A
	ld	e,a
	ld	a,30H
	add	a,d
	ld	(bc),a
	inc	bc
	ld	a,30H
	add	a,e
	ld	(bc),a
	inc	bc
	ld	a,':'
	ld	(bc),a
	inc	bc
				;MM:
	ld	a,(hl)
	inc	hl
	ld	d,a
	xor	a
	ld	e,10
	call	DIVIDE		;inputs hi=A lo=D, divide by E
				;   output D, remainder in A
	ld	e,a
	ld	a,30H
	add	a,d
	ld	(bc),a
	inc	bc
	ld	a,30H
	add	a,e
	ld	(bc),a
	inc	bc
	ld	a,':'
	ld	(bc),a
	inc	bc
				;SS
	ld	a,(hl)
	ld	d,a
	xor	a
	ld	e,10
	call	DIVIDE		;inputs hi=A lo=D, divide by E
				;   output D, remainder in A
	ld	e,a
	ld	a,30H
	add	a,d
	ld	(bc),a
	inc	bc
	ld	a,30H
	add	a,e
	ld	(bc),a

	ret
;
;	Get current time, store-it in StartTime
;
_GetStartTime:
	call	_GetTime		;E = seconds
				;D = minutes
				;L = hours
				;H = 0
	ld	a,l
	ld	hl,StartTime
	ld	(hl),a		;H
	inc	hl
	ld	(hl),d		;M
	inc	hl
	ld	(hl),e		;S
	ret
;
;	Get current time, store-it in StopTime
;
_GetStopTime:
	call	_GetTime		;E = seconds
				;D = minutes
				;L = hours
				;H = 0
	ld	a,l
	ld	hl,StopTime
	ld	(hl),a		;H
	inc	hl
	ld	(hl),d		;M
	inc	hl
	ld	(hl),e		;S
	ret
;
;	Print (StopTime - StartTime)
;
_PrintLapseTime:
	call	ComputeLapse
	ld	de,TimeLapse
        ld 	c,9
        jp 	5
;
;********************************************************************
;	DS1302 real time clock routines
;
mask_data	EQU	10000000B	; RTC data line
mask_clk	EQU	01000000B	; RTC Serial Clock line
mask_rd		EQU	00100000B	; Enable data read from RTC
mask_rst	EQU	00010000B	; De-activate RTC reset line
;
RTC		EQU	0C0H		; RTC port for Z80ALL
;
;void	InitRTC(void)
;
;	Resets time to 01-01-01 00:00:00
;	Writes 00:00:00 to the top-right corner of the screen
;
_InitRTC:
	CALL	ResetON

	CALL	Delay
	CALL	Delay
	CALL	Delay

	CALL RTC_WR_UNPROTECT
; seconds
	LD	D,00H
	LD	A,0
	LD	E,A
	CALL RTC_WRITE
; minutes
	LD	D,01H
	LD	A,0
	LD	E,A
	CALL RTC_WRITE
; hours
	LD	D,02H
	LD	A,0
	LD	E,A
	CALL RTC_WRITE
; date
	LD	D,03H
	LD	A,1
	LD	E,A
	CALL RTC_WRITE
; month
	LD	D,04H
	LD	A,1
	LD	E,A
	CALL RTC_WRITE
; day
	LD	D,05H
	LD	A,1
	LD	E,A
	CALL RTC_WRITE
; year
	LD	D,06H
	LD	A,1
	LD	E,A
	CALL RTC_WRITE
	CALL RTC_WR_PROTECT
;restart
	CALL RTC_WR_UNPROTECT
	LD	D,00H
	LD	E,00H
	CALL RTC_WRITE
	CALL RTC_WR_PROTECT
					;write 00:00:00
	LD	BC,3800H		;LINE 0, COL 56
	LD	A,'0'
	OUT	(C),A
	INC	B
	OUT	(C),A
	INC	B
	LD	A,':'
	OUT	(C),A
	INC	B
	LD	A,'0'
	OUT	(C),A
	INC	B
	OUT	(C),A
	INC	B
	LD	A,':'
	OUT	(C),A
	INC	B
	LD	A,'0'
	OUT	(C),A
	INC	B
	OUT	(C),A

	RET
;
;long	GetTime(void)
;
;	returns E = seconds
;		D = minutes
;		L = hours
;		H = 0
;	writes HH:MM:SS to LINE 0, COL 56
;
_GetTime:
					;PRINT :   :
	LD	BC,3A00H
	LD	A,':'
	OUT	(C),A
	INC	B
	INC	B
	INC	B
	OUT	(C),A

	CALL	ResetOFF		; turn of RTC reset
					;    { Write command, burst read }
	LD	C,10111111B		; (255 - 64)
	CALL	RTC_WR			; send COMMAND BYTE (BURST READ) to DS1302

;    { Read seconds }

	CALL	RTC_RD			; read value from DS1302, value is in Reg C
					; C = ?SSSssss (seconds = (10 x SSS) + ssss)
	LD	E,C
	LD	A,C
	RLC	A
	RLC	A
	RLC	A
	RLC	A
	AND	07H			; A = SSS
	ADD	A,30H
	LD	BC,3E00H
	OUT	(C),a			; seconds first decimal digit
	SUB	30H
	ADD	A,A
	LD	D,A			; D = SSS x 2
	ADD	A,A
	ADD	A,A			; A = SSS x 8
	ADD	A,D			; A = 10 x SSS
	LD	D,A			; D = 10 x SSS
	LD	A,E
	AND	0FH			; A = ssss
	ADD	A,30H
	INC	B
	OUT	(C),A			; seconds second decimal digit
	SUB	30H
	ADD	A,D			; A = 10 x SSS + ssss	
	LD	L,A			; L = seconds

;    { Read minutes }

	CALL	RTC_RD			; read value from DS1302, value is in Reg C
					; C = ?MMMmmmm (minutes = (10 x MMM) + mmmm)
	LD	A,C
	LD	E,C
	RLC	A
	RLC	A
	RLC	A
	RLC	A
	AND	07H			; A = MMM
	ADD	A,30H
	LD	BC,3B00H
	OUT	(C),A			; minutes first decimal digit
	SUB	30H
	ADD	A,A
	LD	D,A			; D = MMM x 2
	ADD	A,A
	ADD	A,A			; A = MMM x 8
	ADD	A,D			; A = 10 x MMM
	LD	D,A			; D = 10 x MMM
	LD	A,E
	AND	0FH			; A = mmmm
	ADD	A,30H
	INC	B
	OUT	(C),A			; minutes second decimal digit
	SUB	30H
	ADD	A,D			; A = 10 x MMM + mmmm	
	LD	H,A			; H = minutes
	PUSH	HL			;save minutes & seconds

;    { Read hours }

	CALL	RTC_RD			; read value from DS1302, value is in Reg C
					; C = ??HHhhhh (hours = (10 x HH) + hhhh)
	LD	A,C
	LD	E,C
	RLC	A
	RLC	A
	RLC	A
	RLC	A
	AND	03H			; A = HH
	ADD	A,30H
	LD	BC,3800H
	OUT	(C),A			; hours first decimal digit
	SUB	30H
	ADD	A,A
	LD	D,A			; D = HH x 2
	ADD	A,A
	ADD	A,A			; A = HH x 8
	ADD	A,D			; A = 10 x HH
	LD	D,A			; D = 10 x HH
	LD	A,E
	AND	0FH			; A = hhhh
	ADD	A,30H
	INC	B
	OUT	(C),A			; hours second decimal digit
	SUB	30H
	ADD	A,D			; A = 10 x HH + hhhh	
	LD	L,A			; L = hours
	LD	H,0

;    { Read date }

	CALL	RTC_RD			; read value from DS1302, value is in Reg C

;    { Read month }

	CALL	RTC_RD			; read value from DS1302, value is in Reg C

;    { Read day }

	CALL	RTC_RD			; read value from DS1302, value is in Reg C

;    { Read year }

	CALL	RTC_RD			; read value from DS1302, value is in Reg C

	POP	DE
			;E = seconds
			;D = minutes
			;L = hours
			;H = 0
	CALL	ResetON		; turn RTC reset back on 
	RET				; Yes, end function and return
;
Delay:
	PUSH	AF			; 11 t-states
	LD	A,7			; 7 t-states ADJUST THE TIME 13h IS FOR 4 MHZ
RTC_BIT_DELAY1:
	DEC	A			; 4 t-states DEC COUNTER. 4 T-states = 1 uS.
	JP	NZ,RTC_BIT_DELAY1	; 10 t-states JUMP TO PAUSELOOP2 IF A <> 0.

	NOP				; 4 t-states
	NOP				; 4 t-states
	POP	AF			; 10 t-states
	RET				; 10 t-states (144 t-states total)
;
ResetON:
	LD	A,mask_data + mask_rd
OutDelay:
	OUT	(RTC),A
	CALL	Delay
	JR	Delay
;
ResetOFF:
	LD	A,mask_data + mask_rd + mask_rst
	JR	OutDelay
;
; function RTC_WR
; input value in C
; uses A
;
;  PROCEDURE rtc_wr(n : int);
;   var
;    i : int;
;  BEGIN
;    for i := 0 while i < 8 do inc(i) loop
;       if (n and 1) <> 0 then
;          out(rtc_base,mask_rst + mask_data);
;          rtc_bit_delay();
;          out(rtc_base,mask_rst + mask_clk + mask_data);
;       else
;          out(rtc_base,mask_rst);
;          rtc_bit_delay();
;          out(rtc_base,mask_rst + mask_clk);
;       end;
;       rtc_bit_delay();
;       n := shr(n,1);
;    end loop;
;  END;

RTC_WR:
	XOR	A			; set A=0 index counter of FOR loop

RTC_WR1:
	PUSH	AF			; save accumulator as it is the index counter in FOR loop
	LD	A,C			; get the value to be written in A from C (passed value to write in C)
	BIT	0,A			; is LSB a 0 or 1?
	JP	Z,RTC_WR2		; if it's a 0, handle it at RTC_WR2.
					; LSB is a 1, handle it below
					; setup RTC latch with RST and DATA high, SCLK low
	LD	A,mask_rst + mask_data
	OUT	(RTC),A		; output to RTC latch
	CALL	Delay	; let it settle a while
					; setup RTC with RST, DATA, and SCLK high
	LD	A,mask_rst + mask_clk + mask_data
	OUT	(RTC),A		; output to RTC latch
	JP	RTC_WR3		; exit FOR loop 

RTC_WR2:
					; LSB is a 0, handle it below
	LD	A,mask_rst		; setup RTC latch with RST high, SCLK and DATA low
	OUT	(RTC),A		; output to RTC latch
	CALL	Delay	; let it settle a while
					; setup RTC with RST and SCLK high, DATA low
	LD	A,mask_rst + mask_clk
	OUT	(RTC),A		; output to RTC latch

RTC_WR3:
	CALL	Delay	; let it settle a while
	RRC	C			; move next bit into LSB position for processing to RTC
	POP	AF			; recover accumulator as it is the index counter in FOR loop
	INC	A			; increment A in FOR loop (A=A+1)
	CP	08H			; is A < $08 ?
	JP	NZ,RTC_WR1		; No, do FOR loop again
	RET				; Yes, end function and return


; function RTC_RD
; output value in C
; uses A
;
; function RTC_RD
;
;  PROCEDURE rtc_rd(): int ;
;   var
;     i,n,mask : int;
;  BEGIN
;    n := 0;
;    mask := 1;
;    for i := 0 while i < 8 do inc(i) loop
;       out(rtc_base,mask_rst + mask_rd);
;       rtc_bit_delay();
;       if (in(rtc_base) and #1) <> #0 then
;          { Data = 1 }
;          n := n + mask;
;       else
;          { Data = 0 }
;       end;
;       mask := shl(mask,1);
;       out(rtc_base,mask_rst + mask_clk + mask_rd);
;       rtc_bit_delay();
;    end loop;
;    return n;
;  END;

RTC_RD:
	XOR	A			; set A=0 index counter of FOR loop
	LD	C,00H			; set C=0 output of RTC_RD is passed in C
	LD	B,01H			; B is mask value

RTC_RD1:
	PUSH	AF			; save accumulator as it is the index counter in FOR loop
					; setup RTC with RST and RD high, SCLK low
	LD	A,mask_rst + mask_rd
	OUT	(RTC),A		; output to RTC latch
	CALL	Delay	; let it settle a while
	IN	A,(RTC)		; input from RTC latch
	BIT	0,A			; is LSB a 0 or 1?
	JP	Z,RTC_RD2		; if LSB is a 1, handle it below
	LD	A,C
	ADD	A,B
	LD	C,A
;	INC	C
					; if LSB is a 0, skip it (C=C+0)
RTC_RD2:
	RLC	B			; move input bit out of LSB position to save it in C
					; setup RTC with RST, SCLK high, and RD high
	LD	A,mask_rst + mask_clk + mask_rd
	OUT	(RTC),A		; output to RTC latch
	CALL	Delay	; let it settle
	POP	AF			; recover accumulator as it is the index counter in FOR loop
	INC	A			; increment A in FOR loop (A=A+1)
	CP	08H			; is A < $08 ?
	JP	NZ,RTC_RD1		; No, do FOR loop again
	RET				; Yes, end function and return.  Read RTC value is in C

; function RTC_WRITE
; input address in D
; input value in E
; uses A
;
; based on following algorithm:		
;
;  PROCEDURE rtc_write(address, value: int);
;  BEGIN
;    lock();
;    rtc_reset_off();
;    { Write command }
;    rtc_wr(128 + shl(address and $3f,1));
;    { Write data }
;    rtc_wr(value and $ff);
;    rtc_reset_on();
;    unlock();
;  END;

RTC_WRITE:
	CALL	ResetOFF	; turn off RTC reset
	LD	A,D			; bring into A the address from D
	AND	00111111B		; keep only bits 6 LSBs, discard 2 MSBs
	RLC	A			; rotate address bits to the left
	ADD	A,10000000B		; set MSB to one for DS1302 COMMAND BYTE (WRITE)
	LD	C,A			; RTC_WR expects write data (address) in reg C
	CALL	RTC_WR		; write address to DS1302
	LD	A,E			; start processing value
	LD	C,A			; RTC_WR expects write data (value) in reg C
	CALL	RTC_WR		; write address to DS1302
	CALL	ResetON	; turn on RTC reset
	RET
;
; function RTC_READ
; input address in D
; output value in C
; uses A
;
; based on following algorithm
;
;  PROCEDURE rtc_read(address: int): int;
;   var
;     n : int;
;  BEGIN
;    lock();
;    rtc_reset_off();
;    { Write command }
;    rtc_wr(128 + shl(address and $3f,1) + 1);
;    { Read data }
;    n := rtc_rd();
;    rtc_reset_on();
;    unlock();
;    return n;
;  END;
;
RTC_READ:
	CALL	ResetOFF	; turn off RTC reset
	LD	A,D			; bring into A the address from D
	AND	3FH			; keep only bits 6 LSBs, discard 2 MSBs
	RLC	A			; rotate address bits to the left
	ADD	A,81H			; set MSB to one for DS1302 COMMAND BYTE (READ)
	LD	C,A			; RTC_WR expects write data (address) in reg C
	CALL	RTC_WR		; write address to DS1302
	CALL	RTC_RD		; read value from DS1302 (value is in reg C)
	CALL	ResetON	; turn on RTC reset
	RET
;
; function RTC_WR_UNPROTECT
; input D (address) $07
; input E (value) 00H
; uses A
;
; based on following algorithm
;
;  PROCEDURE rtc_wr_unprotect;
;  BEGIN
;    rtc_write(7,0);
;  END;

RTC_WR_UNPROTECT:
	LD	D,00000111B
	LD	E,00000000B
	CALL	RTC_WRITE
	RET
;
; function RTC_WR_PROTECT
; input D (address) $07
; input E (value) $80
; uses A
;
; based on following algorithm
;
;  PROCEDURE rtc_wr_protect;
;  BEGIN
;    rtc_write(7,128);
;  END;

RTC_WR_PROTECT:
	LD	D,00000111B
	LD	E,10000000B
	CALL	RTC_WRITE
	RET
;
;********************************************************************

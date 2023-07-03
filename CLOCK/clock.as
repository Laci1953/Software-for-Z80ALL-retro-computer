;	CLOCK
;
;	Real time clock support routines
;
;	for Z80ALL
;
;	Szilagyi Ladislau, July 2023
;
;	Run options
;
;	>clock reset	: start clock
;	>clock		; display time lapse since the last clock run
;
;--------------------------------------------------------------
;
	psect	text
;
BDOS	equ	5
;
start:	ld	sp,(6)
	ld	a,(80H)		;command line length
	or	a		;empty?
	jr	z,display	;if yes, display time lapse
	call	InitRTC		;reset DS1302
	jp	0		;quit
display:
	call	GetTime

	ld	a,l		;hours
	ld	hl,time
	ld	(hl),e		;seconds
	inc	hl
	ld	(hl),d		;minutes
	inc	hl
	ld	(hl),a		;hours

	call	TimeToASCII

	ld	de,TimeASCII
	call	PrintLine
				;initialize again
	call	InitRTC		;reset DS1302

	jp	0		;quit
;
time:	defs	3		;S,M,H
;
TimeASCII:
	defs	8
	defm	' since the last clock call...$'
;
;	print (DE)=line
;
PrintLine:
	ld	c,9
	jp	BDOS
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
;	(time) ---> (TimeASCII)
;
TimeToASCII:
	ld	hl,TimeASCII

	ld	a,(time+2)		;H
	ld	d,a
	xor	a
	ld	e,10
	call	DIVIDE			;inputs hi=A lo=D, divide by E
					;   output D, remainder in A
	ld	e,a
	ld	a,30H
	add	a,d
	ld	(hl),a
	inc	hl
	ld	a,30H
	add	a,e
	ld	(hl),a
	inc	hl
	ld	a,':'
	ld	(hl),a
	inc	hl

	ld	a,(time+1)		;M
	ld	d,a
	xor	a
	ld	e,10
	call	DIVIDE			;inputs hi=A lo=D, divide by E
					;   output D, remainder in A
	ld	e,a
	ld	a,30H
	add	a,d
	ld	(hl),a
	inc	hl
	ld	a,30H
	add	a,e
	ld	(hl),a
	inc	hl
	ld	a,':'
	ld	(hl),a
	inc	hl

	ld	a,(time)		;S
	ld	d,a
	xor	a
	ld	e,10
	call	DIVIDE			;inputs hi=A lo=D, divide by E
					;   output D, remainder in A
	ld	e,a
	ld	a,30H
	add	a,d
	ld	(hl),a
	inc	hl
	ld	a,30H
	add	a,e
	ld	(hl),a

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
;void	InitRTC(void)
;
;	Resets time to 01-01-01 00:00:00
;
InitRTC:
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

	RET
;
;long	GetTime(void)
;
;	returns E = seconds
;		D = minutes
;		L = hours
;		H = 0
;
GetTime:

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
	ADD	A,A
	LD	D,A			; D = SSS x 2
	ADD	A,A
	ADD	A,A			; A = SSS x 8
	ADD	A,D			; A = 10 x SSS
	LD	D,A			; D = 10 x SSS
	LD	A,E
	AND	0FH			; A = ssss
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
	ADD	A,A
	LD	D,A			; D = MMM x 2
	ADD	A,A
	ADD	A,A			; A = MMM x 8
	ADD	A,D			; A = 10 x MMM
	LD	D,A			; D = 10 x MMM
	LD	A,E
	AND	0FH			; A = mmmm
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
	ADD	A,A
	LD	D,A			; D = HH x 2
	ADD	A,A
	ADD	A,A			; A = HH x 8
	ADD	A,D			; A = 10 x HH
	LD	D,A			; D = 10 x HH
	LD	A,E
	AND	0FH			; A = hhhh
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
1:
	DEC	A			; 4 t-states DEC COUNTER. 4 T-states = 1 uS.
	JP	NZ,1b			; 10 t-states JUMP TO PAUSELOOP2 IF A <> 0.

	NOP				; 4 t-states
	NOP				; 4 t-states
	POP	AF			; 10 t-states
	RET				; 10 t-states (144 t-states total)
;
ResetON:
	LD	A,mask_data + mask_rd
	OUT	(RTC),A
	CALL	Delay
	JR	Delay
;
ResetOFF:
	LD	A,mask_data + mask_rd + mask_rst
	OUT	(RTC),A
	CALL	Delay
	JR	Delay
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
1:
	PUSH	AF			; save accumulator as it is the index counter in FOR loop
	LD	A,C			; get the value to be written in A from C (passed value to write in C)
	BIT	0,A			; is LSB a 0 or 1?
	JP	Z,2f			; if it's a 0, handle it at RTC_WR2.
					; LSB is a 1, handle it below
					; setup RTC latch with RST and DATA high, SCLK low
	LD	A,mask_rst + mask_data
	OUT	(RTC),A		; output to RTC latch
	CALL	Delay	; let it settle a while
					; setup RTC with RST, DATA, and SCLK high
	LD	A,mask_rst + mask_clk + mask_data
	OUT	(RTC),A		; output to RTC latch
	JP	3f		; exit FOR loop 
2:
					; LSB is a 0, handle it below
	LD	A,mask_rst		; setup RTC latch with RST high, SCLK and DATA low
	OUT	(RTC),A		; output to RTC latch
	CALL	Delay	; let it settle a while
					; setup RTC with RST and SCLK high, DATA low
	LD	A,mask_rst + mask_clk
	OUT	(RTC),A		; output to RTC latch
3:
	CALL	Delay	; let it settle a while
	RRC	C			; move next bit into LSB position for processing to RTC
	POP	AF			; recover accumulator as it is the index counter in FOR loop
	INC	A			; increment A in FOR loop (A=A+1)
	CP	08H			; is A < $08 ?
	JP	NZ,1b			; No, do FOR loop again
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
1:
	PUSH	AF			; save accumulator as it is the index counter in FOR loop
					; setup RTC with RST and RD high, SCLK low
	LD	A,mask_rst + mask_rd
	OUT	(RTC),A		; output to RTC latch
	CALL	Delay	; let it settle a while
	IN	A,(RTC)		; input from RTC latch
	BIT	0,A			; is LSB a 0 or 1?
	JP	Z,2f		; if LSB is a 1, handle it below
	LD	A,C
	ADD	A,B
	LD	C,A
;	INC	C
					; if LSB is a 0, skip it (C=C+0)
2:
	RLC	B			; move input bit out of LSB position to save it in C
					; setup RTC with RST, SCLK high, and RD high
	LD	A,mask_rst + mask_clk + mask_rd
	OUT	(RTC),A		; output to RTC latch
	CALL	Delay	; let it settle
	POP	AF			; recover accumulator as it is the index counter in FOR loop
	INC	A			; increment A in FOR loop (A=A+1)
	CP	08H			; is A < $08 ?
	JP	NZ,1b		; No, do FOR loop again
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
	end	start
;

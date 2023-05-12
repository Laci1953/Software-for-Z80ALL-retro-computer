;
;       VGA support routines
;
        global  _CrtClear
        global  _CrtLocate
        global  _CrtClearEol
        global  _CrtClearLine
        global  _CrtReverse
        global  _CrtNormal
        global  _CharOut
        global  _StringOut
        global  _CharIn

CR      equ     0DH
LF      equ     0AH
BS      equ     8

BDOS    equ     5

        psect   data

Cursor: defw    0               ;cursor registers
RevMode:defb    0               ;00=video normal, 80H=video reverse

        psect   text
;
;void   CrtClear(void)
;
_CrtClear:
        ld      a,' '
        ld      bc,0BH          ;go to last group of 4 lines, first column
clr4lines:
        out     (c),a
        djnz    clr4lines
        dec     c               ;decrement 4 lines group #
        jp      p,clr4lines     ;if C >= 0 , repeat
        inc     c               ;(BC=0)
        ld      (Cursor),bc     ;...and set cursor to (0,0)
        ret
;
;void   CrtLocate(int row, int col)
;       row=0...47
;       col=0...63
;
_CrtLocate:
        ld      bc,(Cursor)     ;first erase current cursor
        in      a,(c)
        and     7FH
        out     (c),a
        ld      hl,2
        add     hl,sp
        ld      c,(hl)          ;C=row
        inc     hl
        inc     hl
        ld      e,(hl)          ;E=col
setcursor:
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
        ld      (Cursor),bc     ;save cursor
        ret
;
;void   CrtClearEol(void)
;
_CrtClearEol:
        ld      bc,(Cursor)
delchar:ld      a,' '           ;Clear crt char
        out     (c),a
        inc     b               ;increment col index#
        ld      a,b
        and     3FH
        jr      nz,delchar      ;until end of line is reached
        ret
;
;void   CrtClearLine(int row)
;       row=0...47
;
_CrtClearLine:
        ld      hl,2
        add     hl,sp
        ld      c,(hl)          ;C=row
        ld      e,0             ;E=col=0
        call    setcursor       ;goto (row,0)
        jr      _CrtClearEol    ;and clear line
;
;void   CrtReverse(void)
;
_CrtReverse:
        ld      a,80H
setmode:
        ld      (RevMode),a
        ret
;
;void   CrtNormal(void)
;
_CrtNormal:
        xor     a
        jr      setmode
;
;void   CharOut(char c)
;
_CharOut:
        ld      hl,2
        add     hl,sp
        ld      a,(hl)          ;A=char
chout:
        ld      bc,(Cursor)
        cp      BS              ;backspace?
        jr      nz,1f
        ld      a,b             ;yes...
        and     3FH             ;are we at the beginning of a line?
        ret     z               ;if yes, do nothing, just return
        dec     b               ;go back one column
        ld      a,' '
        out     (c),a           ;erase char
        jr      99f             ;save cursor position
1:      cp      LF              ;line feed?
        jr      nz,2f
        ld      a,b             ;...then expand-it to LF+CR
        and     0C0H
        add     a,64
        ld      b,a
        jr      nz,99f          ;if column index# reached 0
        inc     c               ;then increment line group counter (ignore overflow!)
        jr      99f             ;save cursor position
2:      cp      CR              ;carriage return?
        jr      nz,3f
        ld      a,b
        and     0C0H
        ld      b,a             ;then, back to column 0
        jr      99f             ;save cursor position
3:                              ;else output char
        ld      e,a
        ld      a,(RevMode)
        or      e
        out     (c),a
        inc     b
99:                             ;save cursor position
        ld      (Cursor),bc
        ret
;
;void   StringOut(char* p)
;
_StringOut:
        ld      hl,2
        add     hl,sp
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
loopo:  ld      a,(hl)
        or      a
        ret     z
        inc     hl
        call    chout
        jr      loopo
;
;int    CharIn(void)
; returns -1 if no char was available
;
_CharIn:
        ld      c,6
        ld      e,0FFH
        call    BDOS
        or      a               ;zero if no char available
        jr      nz,1f
        ld      hl,0FFFFH
        ret
1:
        ld      h,0
        ld      l,a
        ret
;


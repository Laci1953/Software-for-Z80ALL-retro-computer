;
;	Ladislau Szilagyi, sept 2024
;
;	Fixed point math
;
        psect text
;
;       Fixed point 8.8 format: 16 bits
;       HIGH=int part
;       LOW=fract part
;
;       int fpmul = mul(int pf1, int fp2)
;
_mul::
        ld      hl,2
        add     hl,sp
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        ld      a,(hl)
        inc     hl
        ld      h,(hl)
        ld      l,a
                ;HL=DE*HL fixed point 8_8
fpmul::
        ld      a,h
        xor     d
        push    af
        xor     d
        jp      p,1f
        xor     a
        sub     l
        ld      l,a
        sbc     a,a
        sub     h
        ld      h,a
1:
        bit     7,d
        jr      z,2f
        xor     a
        sub     e
        ld      e,a
        sbc     a,a
        sub     d
        ld      d,a
2:
        ld      bc,0
        push    bc
        push    hl
        ld      hl,0
        call    mul16
        ld      b,h
        ld      h,l
        ld      l,d
        ld      a,b
        or      a
        jr      z,3f
        ld      hl,7FFFH
3:
        pop     af
        ret     p
        xor     a
        sub     l
        ld      l,a
        sbc     a,a
        sub     h
        ld      h,a
        ret

mul16:
        ex      de,hl
        ex      (sp),hl
        exx
        pop     de
        pop     bc
        exx
        pop     bc
        push    hl
        ld      hl,0
        exx
        ld      hl,0
        ld      a,c
        ld      c,b
        call    lmult8b
        ld      a,c
        call    lmult8b
        exx
        ld      a,c
        exx
        call    lmult8b
        exx
        ld      a,b
        exx
        call    lmult8b
        push    hl
        exx
        pop     de
        ret

lmult8b:ld      b,8
4:      srl     a
        jp      nc,5f
        add     hl,de
        exx
        adc     hl,de
        exx
5:      ex      de,hl
        add     hl,hl
        ex      de,hl
        exx
        ex      de,hl
        adc     hl,hl
        ex      de,hl
        exx
        djnz    4b
        ret
;
;       fpdiv = div(int pf1, int fp2)
;
_div::
        ld      hl,2
        add     hl,sp
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
                ;HL=BC/DE fixed point 8_8
fpdiv::
        ld      a,b
        xor     d
        push    af
        xor     b
        jp      p,1f
        xor     a
        sub     c
        ld      c,a
        sbc     a,a
        sub     b
        ld      b,a
1:
        ld      a,d
        or      d
        jp      m,2f
        xor     a
        sub     e
        ld      e,a
        sbc     a,a
        sub     d
        ld      d,a
2:
        or      e
        jr      z,div_overflow
        ld      h,0
        ld      a,b
        add     a,e
        ld      a,d
        adc     a,h
        jr      c,div_overflow
        ld      l,b
        ld      a,c
        call    div_sub
        ld      c,a
        ld      a,b
        call    div_sub
        ld      d,c
        ld      e,a
        pop     af
        jp      p,retdiv
        xor     a
        sub     e
        ld      e,a
        sbc     a,a
        sub     d
        ld      d,a
retdiv:
        ex      de,hl
        ret

div_overflow:
        ld      de,7FFFH
        pop     af
        jp      p,retdiv
        inc     de
        inc     e
        jp      retdiv

div_sub:
        ld      b,8
3:
        rla
        adc     hl,hl
        add     hl,de
        jr      c,4f
        sbc     hl,de
4:
        djnz    3b
        adc     a,a
        ret

BC_Times_DE:            ; unsigned BC*DE->BHLA
        ld a,b
        ld hl,0
        ld b,h
        add a,a
        jr nc,$+5
        ld h,d
        ld l,e

        REPT 7
        add hl,hl
        rla
        jr nc,$+4
        add hl,de
        adc a,b
        ENDM

        push hl
        ld h,b
        ld l,b
        ld b,a
        ld a,c
        ld c,h
        add a,a
        jr nc,$+5
        ld h,d
        ld l,e

        REPT 7
        add hl,hl
        rla
        jr nc,$+4
        add hl,de
        adc a,c
        ENDM

        pop de
        ld c,a
        ld a,l
        ld l,h
        ld h,c
        add hl,de
        ret nc
        inc b
        ret

halfPI          equ     192H
PI              equ     324H
PIplus_halfPI   equ     4B6H
twoPI           equ     648H

;
;       int = sin(int fp)
;
_sin::
        ld      hl,2
        add     hl,sp
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
                        ;CARRY=0
        ld      hl,halfPI-1     ;if angle < PI/2
        sbc     hl,de
        jr      nc,fpsin1       ;...compute sin(angle)

        xor     a       ;CARRY=0
        ld      hl,PI-1         ;if angle < PI
        sbc     hl,de
        inc     hl
        jr      nc,fpsin2       ;...compute sin(PI-angle)

        xor     a       ;CARRY=0
        ld      hl,PIplus_halfPI-1;if angle < PI+PI/2
        sbc     hl,de
        jr      nc,fpsin3       ;...compute -sin(angle-PI)

        xor     a       ;CARRY=0
        ld      hl,twoPI        ;...else compute -sin(2PI-angle)
        sbc     hl,de
        call    fpsin2
        jr      negate

fpsin3:                 ;CARRY=0
        ex      de,hl
        ld      de,PI
        sbc     hl,de
        call    fpsin2
negate:
        ex      de,hl
        xor     a
        ld      hl,0
        sbc     hl,de
        ret

fpsin2: ex      de,hl
                        ;       x < PI/2
                        ;       sin(x) : x-85x^3/512+x^5/128
fpsin1:
                        ;Inputs: DE , output: HL
        push    de
        sra     d
        rr      e       ;DE=x/2
        ld      b,d
        ld      c,e
        call    BC_Times_DE
                        ;HL=x^2/4
        push    hl
        sra     h
        rr      l       ;HL=x^2/8
        ex      de,hl
        ld      b,d
        ld      c,e
        call    BC_Times_DE
                        ;HL=x^4/64
        sra h
        rr l
        inc h
        ex (sp),hl      ;x^4/128+1 is on stack, HL=x^2/4
        xor a
        ld d,a
        ld b,h
        ld c,l
        add hl,hl
        rla
        add hl,hl
        rla
        add hl,bc
        adc a,d
        ld b,h
        ld c,l
        add hl,hl
        rla
        add hl,hl
        rla
        add hl,hl
        rla
        add hl,hl
        rla
        add hl,bc
        adc a,d
        ld e,l
        ld l,h
        ld h,a
        rl e
        adc hl,hl
        rl e
        jr nc,$+3
        inc hl
        pop de
        ex de,hl
        or a
        sbc hl,de
        ex de,hl
        pop bc
        jp BC_Times_DE

;
;       int = cos(int fp)
;
_cos::
        ld      hl,2
        add     hl,sp
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
                        ;CARRY=0
        ld      hl,halfPI-1     ;if angle < PI/2
        sbc     hl,de
        jr      nc,fpcos1       ;...compute cos(angle)

        xor     a       ;CARRY=0
        ld      hl,PI-1         ;if angle < PI
        sbc     hl,de
        inc     hl
        jr      nc,fpcos2       ;...compute -cos(PI-angle)

        xor     a       ;CARRY=0
        ld      hl,PIplus_halfPI-1;if angle < PI+PI/2
        sbc     hl,de
        jr      nc,fpcos3       ;...compute -cos(angle-PI)

        xor     a       ;CARRY=0
        ld      hl,twoPI        ;...else compute cos(2PI-angle)
        sbc     hl,de
        ex      de,hl
        jr      fpcos1

fpcos3:                 ;CARRY=0
        ex      de,hl
        ld      de,PI
        sbc     hl,de

fpcos2: ex      de,hl
        call    fpcos1
        ex      de,hl
        xor     a
        ld      hl,0
        sbc     hl,de
        ret
                        ;       x < PI/2
                        ;       cos(x) : 1-x^2/2+5x^4/128
fpcos1:
                        ;Inputs: DE , output: HL
        ld      b,d
        ld      c,e
        call    BC_Times_DE
                        ;HL=x^2
        sra     h
        rr      l       ;HL=x^2/2
        push    hl      ; x^2/2 on stack

        ex      de,hl
        ld      b,d
        ld      c,e
        call    BC_Times_DE
                        ;HL=x^^4/4

        sra     h
        rr      l       ;HL=x^^4/8
        sra     h
        rr      l       ;HL=x^^4/16
        sra     h
        rr      l       ;HL=x^^4/32
        push    hl      ; x^^4/32 on stack

        sra     h
        rr      l       ;HL=x^^4/64
        sra     h
        rr      l       ;HL=x^^4/128

        pop     de
        add     hl,de   ;HL=x^4/32 + x^4/128 = 5x^^4/128

        pop     de
        sbc     hl,de   ;HL=5x^^4/128 - x^2/2

        ld      bc,100h
        add     hl,bc   ;HL=1 - x^2/2 + 5x^^4/128
        ret


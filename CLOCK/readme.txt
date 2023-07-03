Real time clock utility
-----------------------

Measures time in HH:MM:SS

Use:

>clock reset
>clock
00:00:06 since the last clock call...
>clock
00:00:03 since the last clock call...
>

Very useful to measure the execution speed of CP/M programs

Example:

c>type stmake.sub
clock reset
c -c -o st1.c
clock
c -c -o st2.c
clock
z80as -j rand
clock
z80as -j graphics
clock
z80as -j file
clock

c>
c>submit stmake

c>clock reset

c>c -c -o st1.c
HI-TECH C COMPILER (CP/M-80) V3.09
Copyright (C) 1984-87 HI-TECH SOFTWARE
ST1.C:406:      constant relational expression
Z80AS Macro-Assembler V4.8

Errors: 0

Jump optimizations done: 76
Finished.

c>clock
00:01:13 since the last clock call...
c>c -c -o st2.c
HI-TECH C COMPILER (CP/M-80) V3.09
Copyright (C) 1984-87 HI-TECH SOFTWARE
Z80AS Macro-Assembler V4.8

Errors: 0

Jump optimizations done: 68
Finished.

c>clock
00:01:24 since the last clock call...
c>z80as -j rand
Z80AS Macro-Assembler V4.8

Errors: 0
Finished.

c>clock
00:00:01 since the last clock call...
c>z80as -j graphics
Z80AS Macro-Assembler V4.8

Errors: 0
Finished.

c>clock
00:00:01 since the last clock call...
c>z80as -j file
Z80AS Macro-Assembler V4.8

Errors: 0
Finished.

c>clock
00:00:02 since the last clock call...
c>

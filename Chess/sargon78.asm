;***********************************************************
;
;               SARGON
;
; Sargon is a computer chess playing program designed
; and coded by Dan and Kathe Spracklen.  Copyright 1978. 
; All rights reserved.  No part of this publication may be
; reproduced without the prior written permission.
; This version was ported to CP/M by John Squires in May 2021 specifically
; for the Z80 Playground. It is based on the assembler listing found at
; github.com/billforsternz/retro-sargon. See 8bitStack.co.uk for details.
; Adapted to Z80ALL by Ladislau Szilagyi in June 2023
;
;***********************************************************

    ORG 0100H               ; The standard location to start a CP/M program.
    
    jp DRIVER               ; Jump over all the tables to the start of the program.

;***********************************************************
; EQUATES
;***********************************************************
;
PAWN    EQU     1
KNIGHT  EQU     2
BISHOP  EQU     3
ROOK    EQU     4
QUEEN   EQU     5
KING    EQU     6
WHITE   EQU     0
BLACK   EQU     80H
BPAWN   EQU     BLACK+PAWN

;***********************************************************
; TABLES SECTION
;***********************************************************
START equ 0200H

        ORG     START+80H
TBASE   EQU     START+100H

;There are multiple tables used for fast table look ups
;that are declared relative to TBASE. In each case there
;is a table (say DIRECT) and one or more variables that
;index into the table (say INDX2). The table is declared
;as a relative offset from the TBASE like this;
;
;DIRECT = .-TBASE  ;In this . is the current location
;                  ;($ rather than . is used in most assemblers)
;
;The index variable is declared as;
;INDX2    .WORD TBASE
;
;TBASE itself is page aligned, for example TBASE = 100h
;Although 2 bytes are allocated for INDX2 the most significant
;never changes (so in our example it's 01h). If we want
;to index 5 bytes into DIRECT we set the low byte of INDX2
;to 5 (now INDX2 = 105h) and load IDX2 into an index
;register. The following sequence loads register C with
;the 5th byte of the DIRECT table (Z80 mnemonics)
;        LD      A,5
;        LD      [INDX2],A
;        LD      IY,INDX2
;        LD      C,[IY+DIRECT]
;
;It's a bit like the little known C trick where array[5]
;can also be written as 5[array].
;
;The Z80 indexed addressing mode uses a signed 8 bit
;displacement offset (here DIRECT) in the range -128
;to 127. Sargon needs most of this range, which explains
;why DIRECT is allocated 80h bytes after start and 80h
;bytes *before* TBASE, this arrangement sets the DIRECT
;displacement to be -80h bytes (-128 bytes). After the 24
;byte DIRECT table comes the DPOINT table. So the DPOINT
;displacement is -128 + 24 = -104. The final tables have
;positive displacements.
;
;The negative displacements are not necessary in X86 where
;the equivalent mov reg,[di+offset] indexed addressing
;is not limited to 8 bit offsets, so in the X86 port we
;put the first table DIRECT at the same address as TBASE,
;a more natural arrangement I am sure you'll agree.
;
;In general it seems Sargon doesn't want memory allocated
;in the first page of memory, so we start TBASE at 100h not
;at 0h. One reason is that Sargon extensively uses a trick
;to test for a NULL pointer; it tests whether the hi byte of
;a pointer == 0 considers this as a equivalent to testing
;whether the whole pointer == 0 (works as long as pointers
;never point to page 0).
;
;Also there is an apparent bug in Sargon, such that MLPTRJ
;is left at 0 for the root node and the MLVAL for that root
;node is therefore written to memory at offset 5 from 0 (so
;in page 0). It's a bit wasteful to waste a whole 256 byte
;page for this, but it is compatible with the goal of making
;as few changes as possible to the inner heart of Sargon.
;In the X86 port we lock the uninitialised MLPTRJ bug down
;so MLPTRJ is always set to zero and rendering the bug
;harmless (search for MLPTRJ to find the relevant code).

;**********************************************************
; DIRECT  --  Direction Table.  Used to determine the dir-
;             ection of movement of each piece.
;***********************************************************
DIRECT  EQU     080H ; -128 ; $-TBASE             ;  -128
        DB      +09,+11,-11,-09
        DB      +10,-10,+01,-01
        DB      -21,-12,+08,+19
        DB      +21,+12,-08,-19
        DB      +10,+10,+11,+09
        DB      -10,-10,-11,-09
;***********************************************************
; DPOINT  --  Direction Table Pointer. Used to determine
;             where to begin in the direction table for any
;             given piece.
;***********************************************************
DPOINT  EQU     098H ; -104 ; $-TBASE             ; -104
        DB      20,16,8,0,4,0,0

;***********************************************************
; DCOUNT  --  Direction Table Counter. Used to determine
;             the number of directions of movement for any
;             given piece.
;***********************************************************
DCOUNT  EQU     09FH ; -97 ; $-TBASE             ; -97
        DB      4,4,8,4,4,8,8

;***********************************************************
; PVALUE  --  Point Value. Gives the point value of each
;             piece, or the worth of each piece.
;***********************************************************
PVALUE  EQU     0A5H ; -91 ; $-TBASE-1           ; -91
        DB      1,3,3,5,9,10

;***********************************************************
; PIECES  --  The initial arrangement of the first rank of
;             pieces on the board. Use to set up the board
;             for the start of the game.
;***********************************************************
PIECES  EQU    0ACH ;  -84 ; $-TBASE             ; -84
        DB      4,2,3,5,6,3,2,4

;***********************************************************
; BOARD   --  Board Array.  Used to hold the current position
;             of the board during play. The board itself
;             looks like:
;             FFFFFFFFFFFFFFFFFFFF
;             FFFFFFFFFFFFFFFFFFFF
;             FF0402030506030204FF
;             FF0101010101010101FF
;             FF0000000000000000FF
;             FF0000000000000000FF
;             FF0000000000000060FF
;             FF0000000000000000FF
;             FF8181818181818181FF
;             FF8482838586838284FF
;             FFFFFFFFFFFFFFFFFFFF
;             FFFFFFFFFFFFFFFFFFFF
;             The values of FF form the border of the
;             board, and are used to indicate when a piece
;             moves off the board. The individual bits of
;             the other bytes in the board array are as
;             follows:
;             Bit 7 -- Color of the piece
;                     1 -- Black
;                     0 -- White
;             Bit 6 -- Not used
;             Bit 5 -- Not used
;             Bit 4 --Castle flag for Kings only
;             Bit 3 -- Piece has moved flag
;             Bits 2-0 Piece type
;                     1 -- Pawn
;                     2 -- Knight
;                     3 -- Bishop
;                     4 -- Rook
;                     5 -- Queen
;                     6 -- King
;                     7 -- Not used     (actually this is "mated-king")
;                     0 -- Empty Square
;***********************************************************
BOARD   EQU     0B4H ; -76 ; $-TBASE             ; -76
BOARDA:  DS      120

;***********************************************************
; ATKLIST -- Attack List. A two part array, the first
;            half for white and the second half for black.
;            It is used to hold the attackers of any given
;            square in the order of their value.
;
; WACT   --  White Attack Count. This is the first
;            byte of the array and tells how many pieces are
;            in the white portion of the attack list.
;
; BACT   --  Black Attack Count. This is the eighth byte of
;            the array and does the same for black.
;***********************************************************
ATKLST:  DW      0,0,0,0,0,0,0
WACT    EQU     ATKLST
BACT    EQU     ATKLST+7

;***********************************************************
; PLIST   --  Pinned Piece Array. This is a two part array.
;             PLISTA contains the pinned piece position.
;             PLISTD contains the direction from the pinned
;             piece to the attacker.
;***********************************************************
PLIST   EQU     $-TBASE-1
PLISTD  EQU     PLIST+10
PLISTA:  DW      0,0,0,0,0,0,0,0,0,0

;***********************************************************
; POSK    --  Position of Kings. A two byte area, the first
;             byte of which hold the position of the white
;             king and the second holding the position of
;             the black king.
;
; POSQ    --  Position of Queens. Like POSK,but for queens.
;***********************************************************
POSK:    DB      24,95
POSQ:    DB      14,94
        DB      -1

;***********************************************************
; SCORE   --  Score Array. Used during Alpha-Beta pruning to
;             hold the scores at each ply. It includes two
;             "dummy" entries for ply -1 and ply 0.
;***********************************************************
SCORE:   DW      0,0,0,0,0,0     ;Z80 max 6 ply

;***********************************************************
; STACK   --  Contains the stack for the program.
;***********************************************************
        ORG     START+2FFH
STACK:

;***********************************************************
; TABLE INDICES SECTION
;
; M1-M4   --  Working indices used to index into
;             the board array.
;
; T1-T3   --  Working indices used to index into Direction
;             Count, Direction Value, and Piece Value tables.
;
; INDX1   --  General working indices. Used for various
; INDX2       purposes.
;
; NPINS   --  Number of Pins. Count and pointer into the
;             pinned piece list.
;
; MLPTRI  --  Pointer into the ply table which tells
;             which pair of pointers are in current use.
;
; MLPTRJ  --  Pointer into the move list to the move that is
;             currently being processed.
;
; SCRIX   --  Score Index. Pointer to the score table for
;             the ply being examined.
;
; BESTM   --  Pointer into the move list for the move that
;             is currently considered the best by the
;             Alpha-Beta pruning process.
;
; MLLST   --  Pointer to the previous move placed in the move
;             list. Used during generation of the move list.
;
; MLNXT   --  Pointer to the next available space in the move
;             list.
;
;***********************************************************
        ORG     START+0
M1:      DW      TBASE
M2:      DW      TBASE
M3:      DW      TBASE
M4:      DW      TBASE
T1:      DW      TBASE
T2:      DW      TBASE
T3:      DW      TBASE
INDX1:   DW      TBASE
INDX2:   DW      TBASE
NPINS:   DW      TBASE
MLPTRI:  DW      PLYIX
MLPTRJ:  DW      0
SCRIX:   DW      0
BESTM:   DW      0
MLLST:   DW      0
MLNXT:   DW      MLIST

;***********************************************************
; VARIABLES SECTION
;
; KOLOR   --  Indicates computer's color. White is 0, and
;             Black is 80H.
;
; COLOR   --  Indicates color of the side with the move.
;
; P1-P3   --  Working area to hold the contents of the board
;             array for a given square.
;
; PMATE   --  The move number at which a checkmate is
;             discovered during look ahead.
;
; MOVENO  --  Current move number.
;
; PLYMAX  --  Maximum depth of search using Alpha-Beta
;             pruning.
;
; NPLY    --  Current ply number during Alpha-Beta
;             pruning.
;
; CKFLG   --  A non-zero value indicates the king is in check.
;
; MATEF   --  A zero value indicates no legal moves.
;
; VALM    --  The score of the current move being examined.
;
; BRDC    --  A measure of mobility equal to the total number
;             of squares white can move to minus the number
;             black can move to.
;
; PTSL    --  The maximum number of points which could be lost
;             through an exchange by the player not on the
;             move.
;
; PTSW1   --  The maximum number of points which could be won
;             through an exchange by the player not on the
;             move.
;
; PTSW2   --  The second highest number of points which could
;             be won through a different exchange by the player
;             not on the move.
;
; MTRL    --  A measure of the difference in material
;             currently on the board. It is the total value of
;             the white pieces minus the total value of the
;             black pieces.
;
; BC0     --  The value of board control(BRDC) at ply 0.
;
; MV0     --  The value of material(MTRL) at ply 0.
;
; PTSCK   --  A non-zero value indicates that the piece has
;             just moved itself into a losing exchange of
;             material.
;
; BMOVES  --  Our very tiny book of openings. Determines
;             the first move for the computer.
;
;***********************************************************
KOLOR:   DB      0
COLOR:   DB      0
P1:      DB      0
P2:      DB      0
P3:      DB      0
PMATE:   DB      0
MOVENO:  DB      0
PLYMAX:  DB      2
NPLY:    DB      0
CKFLG:   DB      0
MATEF:   DB      0
VALM:    DB      0
BRDC:    DB      0
PTSL:    DB      0
PTSW1:   DB      0
PTSW2:   DB      0
MTRL:    DB      0
BC0:     DB      0
MV0:     DB      0
PTSCK:   DB      0
BMOVES:  DB      35,55,10H
        DB      34,54,10H
        DB      85,65,10H
        DB      84,64,10H

;***********************************************************
; MOVE LIST SECTION
;
; MLIST   --  A 2048 byte storage area for generated moves.
;             This area must be large enough to hold all
;             the moves for a single leg of the move tree.
;
; MLEND   --  The address of the last available location
;             in the move list.
;
; MLPTR   --  The Move List is a linked list of individual
;             moves each of which is 6 bytes in length. The
;             move list pointer(MLPTR) is the link field
;             within a move.
;
; MLFRP   --  The field in the move entry which gives the
;             board position from which the piece is moving.
;
; MLTOP   --  The field in the move entry which gives the
;             board position to which the piece is moving.
;
; MLFLG   --  A field in the move entry which contains flag
;             information. The meaning of each bit is as
;             follows:
;             Bit 7  --  The color of any captured piece
;                        0 -- White
;                        1 -- Black
;             Bit 6  --  Double move flag (set for castling and
;                        en passant pawn captures)
;             Bit 5  --  Pawn Promotion flag; set when pawn
;                        promotes.
;             Bit 4  --  When set, this flag indicates that
;                        this is the first move for the
;                        piece on the move.
;             Bit 3  --  This flag is set is there is a piece
;                        captured, and that piece has moved at
;                        least once.
;             Bits 2-0   Describe the captured piece.  A
;                        zero value indicates no capture.
;
; MLVAL   --  The field in the move entry which contains the
;             score assigned to the move.
;
;***********************************************************
        ORG     START+300H
MLIST:   DS      2048
MLEND   EQU     MLIST+2040
MLPTR   EQU     0
MLFRP   EQU     2
MLTOP   EQU     3
MLFLG   EQU     4
MLVAL   EQU     5

;***********************************************************

;***********************************************************
; PLYIX   --  Ply Table. Contains pairs of pointers, a pair
;             for each ply. The first pointer points to the
;             top of the list of possible moves at that ply.
;             The second pointer points to which move in the
;             list is the one currently being considered.
;***********************************************************
PLYIX:   DW      0,0,0,0,0,0,0,0,0,0
        DW      0,0,0,0,0,0,0,0,0,0

;**********************************************************
; PROGRAM CODE SECTION
;**********************************************************

;**********************************************************
; BOARD SETUP ROUTINE
;***********************************************************
; FUNCTION:   To initialize the board array, setting the
;             pieces in their initial positions for the
;             start of the game.
;
; CALLED BY:  DRIVER
;
; CALLS:      None
;
; ARGUMENTS:  None
;***********************************************************
INITBD: LD      b,120           ; Pre-fill board with -1's
        LD      hl,BOARDA
back01: LD      (hl),-1
        INC     hl
        DJNZ    back01
        LD      b,8
        LD      ix,BOARDA
IB2:    LD      a,(ix-8)        ; Fill non-border squares
        LD      (ix+21),a       ; White pieces
        SET     7,a             ; Change to black
        LD      (ix+91),a       ; Black pieces
        LD      (ix+31),PAWN    ; White Pawns
        LD      (ix+81),BPAWN   ; Black Pawns
        LD      (ix+41),0       ; Empty squares
        LD      (ix+51),0
        LD      (ix+61),0
        LD      (ix+71),0
        INC     ix
        DJNZ    IB2
        LD      ix,POSK         ; Init King/Queen position list
        LD      (ix+0),25
        LD      (ix+1),95
        LD      (ix+2),24
        LD      (ix+3),94
        RET

;***********************************************************
; PATH ROUTINE
;***********************************************************
; FUNCTION:   To generate a single possible move for a given
;             piece along its current path of motion including:

;                Fetching the contents of the board at the new
;                position, and setting a flag describing the
;                contents:
;                          0  --  New position is empty
;                          1  --  Encountered a piece of the
;                                 opposite color
;                          2  --  Encountered a piece of the
;                                 same color
;                          3  --  New position is off the
;                                 board
;
; CALLED BY:  MPIECE
;             ATTACK
;             PINFND
;
; CALLS:      None
;
; ARGUMENTS:  Direction from the direction array giving the
;             constant to be added for the new position.
;***********************************************************

PATH:   LD      hl,M2           ; Get previous position
        LD      a,(hl)
        ADD     a,c             ; Add direction constant
        LD      (hl),a          ; Save new position
        LD      ix,(M2)         ; Load board index
        LD      a,(ix+BOARD)    ; Get contents of board
        CP      -1              ; In border area ?
        JR      Z,PA2           ; Yes - jump
        LD      (P2),a          ; Save piece
        AND     7               ; Clear flags
        LD      (T2),a          ; Save piece type
        RET     Z               ; Return if empty
        LD      a,(P2)          ; Get piece encountered
        LD      hl,P1           ; Get moving piece address
        XOR     (hl)            ; Compare
        BIT     7,a             ; Do colors match ?
        JR      Z,PA1           ; Yes - jump
        LD      a,1             ; Set different color flag
        RET                     ; Return
PA1:    LD      a,2             ; Set same color flag
        RET                     ; Return
PA2:    LD      a,3             ; Set off board flag
        RET                     ; Return

;***********************************************************
; PIECE MOVER ROUTINE
;***********************************************************
; FUNCTION:   To generate all the possible legal moves for a
;             given piece.
;
; CALLED BY:  GENMOV
;
; CALLS:      PATH
;             ADMOVE
;             CASTLE
;             ENPSNT
;
; ARGUMENTS:  The piece to be moved.
;***********************************************************
MPIECE: XOR     (hl)            ; Piece to move
        AND     87H             ; Clear flag bit
        CP      BPAWN           ; Is it a black Pawn ?
        JR      NZ,rel001       ; No-Skip
        DEC     a               ; Decrement for black Pawns
rel001: AND     7               ; Get piece type
        LD      (T1),a          ; Save piece type
        LD      iy,(T1)         ; Load index to DCOUNT/DPOINT
        LD      b,(iy+DCOUNT)   ; Get direction count
        LD      a,(iy+DPOINT)   ; Get direction pointer
        LD      (INDX2),a       ; Save as index to direct
        LD      iy,(INDX2)      ; Load index
MP5:    LD      c,(iy+DIRECT)   ; Get move direction
        LD      a,(M1)          ; From position
        LD      (M2),a          ; Initialize to position
MP10:   CALL    PATH            ; Calculate next position
        CP      2               ; Ready for new direction ?
        JR      NC,MP15         ; Yes - Jump
        AND     a               ; Test for empty square
        EX      af,af'          ; Save result
        LD      a,(T1)          ; Get piece moved
        CP      PAWN+1          ; Is it a Pawn ?
        JR      C,MP20          ; Yes - Jump
        CALL    ADMOVE          ; Add move to list
        EX      af,af'          ; Empty square ?
        JR      NZ,MP15         ; No - Jump
        LD      a,(T1)          ; Piece type
        CP      KING            ; King ?
        JR      Z,MP15          ; Yes - Jump
        CP      BISHOP          ; Bishop, Rook, or Queen ?
        JR      NC,MP10         ; Yes - Jump
MP15:   INC     iy              ; Increment direction index
        DJNZ    MP5             ; Decr. count-jump if non-zerc
        LD      a,(T1)          ; Piece type
        CP      KING            ; King ?
        CALL    Z,CASTLE        ; Yes - Try Castling
        RET                     ; Return
; ***** PAWN LOGIC *****
MP20:   LD      a,b             ; Counter for direction
        CP      3             ; On diagonal moves ?
        JR      C,MP35          ; Yes - Jump
        JR      Z,MP30          ; -or-jump if on 2 square move
        EX      af,af'          ; Is forward square empty?
        JR      NZ,MP15         ; No - jump
        LD      a,(M2)          ; Get "to" position
        CP      91            ; Promote white Pawn ?
        JR      NC,MP25         ; Yes - Jump
        CP      29            ; Promote black Pawn ?
        JR      NC,MP26         ; No - Jump
MP25:   LD      hl,P2           ; Flag address
        SET     5,(hl)          ; Set promote flag
MP26:   CALL    ADMOVE          ; Add to move list
        INC     iy              ; Adjust to two square move
        DEC     b
        LD      hl,P1           ; Check Pawn moved flag
        BIT     3,(hl)          ; Has it moved before ?
        JR      Z,MP10          ; No - Jump
        JP      MP15            ; Jump
MP30:   EX      af,af'          ; Is forward square empty ?
        JR      NZ,MP15         ; No - Jump
MP31:   CALL    ADMOVE          ; Add to move list
        JP      MP15            ; Jump
MP35:   EX      af,af'          ; Is diagonal square empty ?
        JR      Z,MP36          ; Yes - Jump
        LD      a,(M2)          ; Get "to" position
        CP      91            ; Promote white Pawn ?
        JR      NC,MP37         ; Yes - Jump
        CP      29            ; Black Pawn promotion ?
        JR      NC,MP31         ; No- Jump
MP37:   LD      hl,P2           ; Get flag address
        SET     5,(hl)          ; Set promote flag
        JR      MP31            ; Jump
MP36:   CALL    ENPSNT          ; Try en passant capture
        JP      MP15            ; Jump

;***********************************************************
; EN PASSANT ROUTINE
;***********************************************************
; FUNCTION:   --  To test for en passant Pawn capture and
;                 to add it to the move list if it is
;                 legal.
;
; CALLED BY:  --  MPIECE
;
; CALLS:      --  ADMOVE
;                 ADJPTR
;
; ARGUMENTS:  --  None
;***********************************************************
ENPSNT: LD      a,(M1)          ; Set position of Pawn
        LD      hl,P1           ; Check color
        BIT     7,(hl)          ; Is it white ?
        JR      Z,rel002        ; Yes - skip
        ADD     a,10            ; Add 10 for black
rel002: CP      61            ; On en passant capture rank ?
        RET     C               ; No - return
        CP      69            ; On en passant capture rank ?
        RET     NC              ; No - return
        LD      ix,(MLPTRJ)     ; Get pointer to previous move
        BIT     4,(ix+MLFLG)    ; First move for that piece ?
        RET     Z               ; No - return
        LD      a,(ix+MLTOP)    ; Get "to" position
        LD      (M4),a          ; Store as index to board
        LD      ix,(M4)         ; Load board index
        LD      a,(ix+BOARD)    ; Get piece moved
        LD      (P3),a          ; Save it
        AND     7             ; Get piece type
        CP      PAWN          ; Is it a Pawn ?
        RET     NZ              ; No - return
        LD      a,(M4)          ; Get "to" position
        LD      hl,M2           ; Get present "to" position
        SUB     (hl)          ; Find difference
        JP      P,rel003        ; Positive ? Yes - Jump
        NEG                     ; Else take absolute value
rel003: CP      10            ; Is difference 10 ?
        RET     NZ              ; No - return
        LD      hl,P2           ; Address of flags
        SET     6,(hl)          ; Set double move flag
        CALL    ADMOVE          ; Add Pawn move to move list
        LD      a,(M1)          ; Save initial Pawn position
        LD      (M3),a
        LD      a,(M4)          ; Set "from" and "to" positions
                                ; for dummy move
        LD      (M1),a
        LD      (M2),a
        LD      a,(P3)          ; Save captured Pawn
        LD      (P2),a
        CALL    ADMOVE          ; Add Pawn capture to move list
        LD      a,(M3)          ; Restore "from" position
        LD      (M1),a

;***********************************************************
; ADJUST MOVE LIST POINTER FOR DOUBLE MOVE
;***********************************************************
; FUNCTION:   --  To adjust move list pointer to link around
;                 second move in double move.
;
; CALLED BY:  --  ENPSNT
;                 CASTLE
;                 (This mini-routine is not really called,
;                 but is jumped to to save time.)
;
; CALLS:      --  None
;
; ARGUMENTS:  --  None
;***********************************************************
ADJPTR: LD      hl,(MLLST)      ; Get list pointer
        LD      de,-6           ; Size of a move entry
        ADD     hl,de           ; Back up list pointer
        LD      (MLLST),hl      ; Save list pointer
        LD      (hl),0          ; Zero out link, first byte
        INC     hl              ; Next byte
        LD      (hl),0          ; Zero out link, second byte
        RET                     ; Return

;***********************************************************
; CASTLE ROUTINE
;***********************************************************
; FUNCTION:   --  To determine whether castling is legal
;                 (Queen side, King side, or both) and add it
;                 to the move list if it is.
;
; CALLED BY:  --  MPIECE
;
; CALLS:      --  ATTACK
;                 ADMOVE
;                 ADJPTR
;
; ARGUMENTS:  --  None
;***********************************************************
CASTLE: LD      a,(P1)          ; Get King
        BIT     3,a             ; Has it moved ?
        RET     NZ              ; Yes - return
        LD      a,(CKFLG)       ; Fetch Check Flag
        AND     a             ; Is the King in check ?
        RET     NZ              ; Yes - Return
        LD      bc,0FF03H       ; Initialize King-side values
CA5:    LD      a,(M1)          ; King position
        ADD     a,c             ; Rook position
        LD      c,a             ; Save
        LD      (M3),a          ; Store as board index
        LD      ix,(M3)         ; Load board index
        LD      a,(ix+BOARD)    ; Get contents of board
        AND     7FH           ; Clear color bit
        CP      ROOK          ; Has Rook ever moved ?
        JR      NZ,CA20         ; Yes - Jump
        LD      a,c             ; Restore Rook position
        JR      CA15            ; Jump
CA10:   LD      ix,(M3)         ; Load board index
        LD      a,(ix+BOARD)    ; Get contents of board
        AND     a             ; Empty ?
        JR      NZ,CA20         ; No - Jump
        LD      a,(M3)          ; Current position
        CP      22            ; White Queen Knight square ?
        JR      Z,CA15          ; Yes - Jump
        CP      92            ; Black Queen Knight square ?
        JR      Z,CA15          ; Yes - Jump
        CALL    ATTACK          ; Look for attack on square
        AND     a             ; Any attackers ?
        JR      NZ,CA20         ; Yes - Jump
        LD      a,(M3)          ; Current position
CA15:   ADD     a,b             ; Next position
        LD      (M3),a          ; Save as board index
        LD      hl,M1           ; King position
        CP      (hl)          ; Reached King ?
        JR      NZ,CA10         ; No - jump
        SUB     b             ; Determine King's position
        SUB     b
        LD      (M2),a          ; Save it
        LD      hl,P2           ; Address of flags
        LD      (hl),40H        ; Set double move flag
        CALL    ADMOVE          ; Put king move in list
        LD      hl,M1           ; Addr of King "from" position
        LD      a,(hl)          ; Get King's "from" position
        LD      (hl),c          ; Store Rook "from" position
        SUB     b             ; Get Rook "to" position
        LD      (M2),a          ; Store Rook "to" position
        XOR     a             ; Zero
        LD      (P2),a          ; Zero move flags
        CALL    ADMOVE          ; Put Rook move in list
        CALL    ADJPTR          ; Re-adjust move list pointer
        LD      a,(M3)          ; Restore King position
        LD      (M1),a          ; Store
CA20:   LD      a,b             ; Scan Index
        CP      1             ; Done ?
        RET     Z               ; Yes - return
        LD      bc,01FCH        ; Set Queen-side initial values
        JP      CA5             ; Jump

;***********************************************************
; ADMOVE ROUTINE
;***********************************************************
; FUNCTION:   --  To add a move to the move list
;
; CALLED BY:  --  MPIECE
;                 ENPSNT
;                 CASTLE
;
; CALLS:      --  None
;
; ARGUMENT:  --  None
;***********************************************************
ADMOVE: LD      de,(MLNXT)      ; Addr of next loc in move list
        LD      hl,MLEND        ; Address of list end
        AND     a             ; Clear carry flag
        SBC     hl,de           ; Calculate difference
        JR      C,AM10          ; Jump if out of space
        LD      hl,(MLLST)      ; Addr of prev. list area
        LD      (MLLST),de      ; Save next as previous
        LD      (hl),e          ; Store link address
        INC     hl
        LD      (hl),d
        LD      hl,P1           ; Address of moved piece
        BIT     3,(hl)          ; Has it moved before ?
        JR      NZ,rel004       ; Yes - jump
        LD      hl,P2           ; Address of move flags
        SET     4,(hl)          ; Set first move flag
rel004: EX      de,hl           ; Address of move area
        LD      (hl),0          ; Store zero in link address
        INC     hl
        LD      (hl),0
        INC     hl
        LD      a,(M1)          ; Store "from" move position
        LD      (hl),a
        INC     hl
        LD      a,(M2)          ; Store "to" move position
        LD      (hl),a
        INC     hl
        LD      a,(P2)          ; Store move flags/capt. piece
        LD      (hl),a
        INC     hl
        LD      (hl),0          ; Store initial move value
        INC     hl
        LD      (MLNXT),hl      ; Save address for next move
        RET                     ; Return
AM10:   LD      (hl),0          ; Abort entry on table ovflow
        INC     hl
        LD      (hl),0          ; TODO does this out of memory
        DEC     hl              ;      check actually work?
        RET

;***********************************************************
; GENERATE MOVE ROUTINE
;***********************************************************
; FUNCTION:  --  To generate the move set for all of the
;                pieces of a given color.
;
; CALLED BY: --  FNDMOV
;
; CALLS:     --  MPIECE
;                INCHK
;
; ARGUMENTS: --  None
;***********************************************************
GENMOV: CALL    INCHK           ; Test for King in check
        LD      (CKFLG),a       ; Save attack count as flag
        LD      de,(MLNXT)      ; Addr of next avail list space
        LD      hl,(MLPTRI)     ; Ply list pointer index
        INC     hl              ; Increment to next ply
        INC     hl
        LD      (hl),e          ; Save move list pointer
        INC     hl
        LD      (hl),d
        INC     hl
        LD      (MLPTRI),hl     ; Save new index
        LD      (MLLST),hl      ; Last pointer for chain init.
        LD      a,21            ; First position on board
GM5:    LD      (M1),a          ; Save as index
        LD      ix,(M1)         ; Load board index
        LD      a,(ix+BOARD)    ; Fetch board contents
        AND     a             ; Is it empty ?
        JR      Z,GM10          ; Yes - Jump
        CP      -1            ; Is it a border square ?
        JR      Z,GM10          ; Yes - Jump
        LD      (P1),a          ; Save piece
        LD      hl,COLOR        ; Address of color of piece
        XOR     (hl)          ; Test color of piece
        BIT     7,a             ; Match ?
        CALL    Z,MPIECE        ; Yes - call Move Piece
GM10:   LD      a,(M1)          ; Fetch current board position
        INC     a               ; Incr to next board position
        CP      99            ; End of board array ?
        JP      NZ,GM5          ; No - Jump
        RET                     ; Return

;***********************************************************
; CHECK ROUTINE
;***********************************************************
; FUNCTION:   --  To determine whether or not the
;                 King is in check.
;
; CALLED BY:  --  GENMOV
;                 FNDMOV
;                 EVAL
;
; CALLS:      --  ATTACK
;
; ARGUMENTS:  --  Color of King
;***********************************************************
INCHK:  LD      a,(COLOR)       ; Get color
INCHK1: LD      hl,POSK         ; Addr of white King position
        AND     a             ; White ?
        JR      Z,rel005        ; Yes - Skip
        INC     hl              ; Addr of black King position
rel005: LD      a,(hl)          ; Fetch King position
        LD      (M3),a          ; Save
        LD      ix,(M3)         ; Load board index
        LD      a,(ix+BOARD)    ; Fetch board contents
        LD      (P1),a          ; Save
        AND     7             ; Get piece type
        LD      (T1),a          ; Save
        CALL    ATTACK          ; Look for attackers on King
        RET                     ; Return

;***********************************************************
; ATTACK ROUTINE
;***********************************************************
; FUNCTION:   --  To find all attackers on a given square
;                 by scanning outward from the square
;                 until a piece is found that attacks
;                 that square, or a piece is found that
;                 doesn't attack that square, or the edge
;                 of the board is reached.
;
;                 In determining which pieces attack
;                 a square, this routine also takes into
;                 account the ability of certain pieces to
;                 attack through another attacking piece. (For
;                 example a queen lined up behind a bishop
;                 of her same color along a diagonal.) The
;                 bishop is then said to be transparent to the
;                 queen, since both participate in the
;                 attack.
;
;                 In the case where this routine is called
;                 by CASTLE or INCHK, the routine is
;                 terminated as soon as an attacker of the
;                 opposite color is encountered.
;
; CALLED BY:  --  POINTS
;                 PINFND
;                 CASTLE
;                 INCHK
;
; CALLS:      --  PATH
;                 ATKSAV
;
; ARGUMENTS:  --  None
;***********************************************************
ATTACK: PUSH    bc              ; Save Register B
        XOR     a             ; Clear
        LD      b,16            ; Initial direction count
        LD      (INDX2),a       ; Initial direction index
        LD      iy,(INDX2)      ; Load index
AT5:    LD      c,(iy+DIRECT)   ; Get direction
        LD      d,0             ; Init. scan count/flags
        LD      a,(M3)          ; Init. board start position
        LD      (M2),a          ; Save
AT10:   INC     d               ; Increment scan count
        CALL    PATH            ; Next position
        CP      1             ; Piece of a opposite color ?
        JR      Z,AT14A         ; Yes - jump
        CP      2             ; Piece of same color ?
        JR      Z,AT14B         ; Yes - jump
        AND     a             ; Empty position ?
        JR      NZ,AT12         ; No - jump
        LD      a,b             ; Fetch direction count
        CP      9             ; On knight scan ?
        JR      NC,AT10         ; No - jump
AT12:   INC     iy              ; Increment direction index
        DJNZ    AT5             ; Done ? No - jump
        XOR     a             ; No attackers
AT13:   POP     bc              ; Restore register B
        RET                     ; Return
AT14A:  BIT     6,d             ; Same color found already ?
        JR      NZ,AT12         ; Yes - jump
        SET     5,d             ; Set opposite color found flag
        JP      AT14            ; Jump
AT14B:  BIT     5,d             ; Opposite color found already?
        JR      NZ,AT12         ; Yes - jump
        SET     6,d             ; Set same color found flag
;
; ***** DETERMINE IF PIECE ENCOUNTERED ATTACKS SQUARE *****
;
AT14:   LD      a,(T2)          ; Fetch piece type encountered
        LD      e,a             ; Save
        LD      a,b             ; Get direction-counter
        CP      9             ; Look for Knights ?
        JR      C,AT25          ; Yes - jump
        LD      a,e             ; Get piece type
        CP      QUEEN         ; Is is a Queen ?
        JR      NZ,AT15         ; No - Jump
        SET     7,d             ; Set Queen found flag
        JR      AT30            ; Jump
AT15:   LD      a,d             ; Get flag/scan count
        AND     0FH           ; Isolate count
        CP      1             ; On first position ?
        JR      NZ,AT16         ; No - jump
        LD      a,e             ; Get encountered piece type
        CP      KING          ; Is it a King ?
        JR      Z,AT30          ; Yes - jump
AT16:   LD      a,b             ; Get direction counter
        CP      13            ; Scanning files or ranks ?
        JR      C,AT21          ; Yes - jump
        LD      a,e             ; Get piece type
        CP      BISHOP        ; Is it a Bishop ?
        JR      Z,AT30          ; Yes - jump
        LD      a,d             ; Get flags/scan count
        AND     0FH           ; Isolate count
        CP      1             ; On first position ?
        JR      NZ,AT12         ; No - jump
        CP      e             ; Is it a Pawn ?
        JR      NZ,AT12         ; No - jump
        LD      a,(P2)          ; Fetch piece including color
        BIT     7,a             ; Is it white ?
        JR      Z,AT20          ; Yes - jump
        LD      a,b             ; Get direction counter
        CP      15            ; On a non-attacking diagonal ?
        JR      C,AT12          ; Yes - jump
        JR      AT30            ; Jump
AT20:   LD      a,b             ; Get direction counter
        CP      15            ; On a non-attacking diagonal ?
        JR      NC,AT12         ; Yes - jump
        JR      AT30            ; Jump
AT21:   LD      a,e             ; Get piece type
        CP      ROOK          ; Is is a Rook ?
        JR      NZ,AT12         ; No - jump
        JR      AT30            ; Jump
AT25:   LD      a,e             ; Get piece type
        CP      KNIGHT        ; Is it a Knight ?
        JR      NZ,AT12         ; No - jump
AT30:   LD      a,(T1)          ; Attacked piece type/flag
        CP      7             ; Call from POINTS ?
        JR      Z,AT31          ; Yes - jump
        BIT     5,d             ; Is attacker opposite color ?
        JR      Z,AT32          ; No - jump
        LD      a,1             ; Set attacker found flag
        JP      AT13            ; Jump
AT31:   CALL    ATKSAV          ; Save attacker in attack list
AT32:   LD      a,(T2)          ; Attacking piece type
        CP      KING          ; Is it a King,?
        JP      Z,AT12          ; Yes - jump
        CP      KNIGHT        ; Is it a Knight ?
        JP      Z,AT12          ; Yes - jump
        JP      AT10            ; Jump

;***********************************************************
; ATTACK SAVE ROUTINE
;***********************************************************
; FUNCTION:   --  To save an attacking piece value in the
;                 attack list, and to increment the attack
;                 count for that color piece.
;
;                 The pin piece list is checked for the
;                 attacking piece, and if found there, the
;                 piece is not included in the attack list.
;
; CALLED BY:  --  ATTACK
;
; CALLS:      --  PNCK
;
; ARGUMENTS:  --  None
;***********************************************************
ATKSAV: PUSH    bc              ; Save Regs BC
        PUSH    de              ; Save Regs DE
        LD      a,(NPINS)       ; Number of pinned pieces
        AND     a             ; Any ?
        CALL    NZ,PNCK         ; yes - check pin list
        LD      ix,(T2)         ; Init index to value table
        LD      hl,ATKLST       ; Init address of attack list
        LD      bc,0            ; Init increment for white
        LD      a,(P2)          ; Attacking piece
        BIT     7,a             ; Is it white ?
        JR      Z,rel006        ; Yes - jump
        LD      c,7             ; Init increment for black
rel006: AND     7             ; Attacking piece type
        LD      e,a             ; Init increment for type
        BIT     7,d             ; Queen found this scan ?
        JR      Z,rel007        ; No - jump
        LD      e,QUEEN         ; Use Queen slot in attack list
rel007: ADD     hl,bc           ; Attack list address
        INC     (hl)            ; Increment list count
        LD      d,0
        ADD     hl,de           ; Attack list slot address
        LD      a,(hl)          ; Get data already there
        AND     0FH           ; Is first slot empty ?
        JR      Z,AS20          ; Yes - jump
        LD      a,(hl)          ; Get data again
        AND     0F0H          ; Is second slot empty ?
        JR      Z,AS19          ; Yes - jump
        INC     hl              ; Increment to King slot
        JR      AS20            ; Jump
AS19:   RLD                     ; Temp save lower in upper
        LD      a,(ix+PVALUE)   ; Get new value for attack list
        RRD                     ; Put in 2nd attack list slot
        JR      AS25            ; Jump
AS20:   LD      a,(ix+PVALUE)   ; Get new value for attack list
        RLD                     ; Put in 1st attack list slot
AS25:   POP     de              ; Restore DE regs
        POP     bc              ; Restore BC regs
        RET                     ; Return

;***********************************************************
; PIN CHECK ROUTINE
;***********************************************************
; FUNCTION:   --  Checks to see if the attacker is in the
;                 pinned piece list. If so he is not a valid
;                 attacker unless the direction in which he
;                 attacks is the same as the direction along
;                 which he is pinned. If the piece is
;                 found to be invalid as an attacker, the
;                 return to the calling routine is aborted
;                 and this routine returns directly to ATTACK.
;
; CALLED BY:  --  ATKSAV
;
; CALLS:      --  None
;
; ARGUMENTS:  --  The direction of the attack. The
;                 pinned piece counnt.
;***********************************************************
PNCK:   LD      d,c             ; Save attack direction
        LD      e,0             ; Clear flag
        LD      c,a             ; Load pin count for search
        LD      b,0
        LD      a,(M2)          ; Position of piece
        LD      hl,PLISTA       ; Pin list address
PC1:    CPIR                    ; Search list for position
        RET     NZ              ; Return if not found
        EX      af,af'          ; Save search parameters
        BIT     0,e             ; Is this the first find ?
        JR      NZ,PC5          ; No - jump
        SET     0,e             ; Set first find flag
        PUSH    hl              ; Get corresp index to dir list
        POP     ix
        LD      a,(ix+9)        ; Get direction
        CP      d             ; Same as attacking direction ?
        JR      Z,PC3           ; Yes - jump
        NEG                     ; Opposite direction ?
        CP      d             ; Same as attacking direction ?
        JR      NZ,PC5          ; No - jump
PC3:    EX      af,af'          ; Restore search parameters
        JP      PE,PC1          ; Jump if search not complete
        RET                     ; Return
PC5:    POP     af              ; Abnormal exit
        POP     de              ; Restore regs.
        POP     bc
        RET                     ; Return to ATTACK

;***********************************************************
; PIN FIND ROUTINE
;***********************************************************
; FUNCTION:   --  To produce a list of all pieces pinned
;                 against the King or Queen, for both white
;                 and black.
;
; CALLED BY:  --  FNDMOV
;                 EVAL
;
; CALLS:      --  PATH
;                 ATTACK
;
; ARGUMENTS:  --  None
;***********************************************************
PINFND: XOR     a             ; Zero pin count
        LD      (NPINS),a
        LD      de,POSK         ; Addr of King/Queen pos list
PF1:    LD      a,(de)          ; Get position of royal piece
        AND     a             ; Is it on board ?
        JP      Z,PF26          ; No- jump
        CP      -1            ; At end of list ?
        RET     Z               ; Yes return
        LD      (M3),a          ; Save position as board index
        LD      ix,(M3)         ; Load index to board
        LD      a,(ix+BOARD)    ; Get contents of board
        LD      (P1),a          ; Save
        LD      b,8             ; Init scan direction count
        XOR     a
        LD      (INDX2),a       ; Init direction index
        LD      iy,(INDX2)
PF2:    LD      a,(M3)          ; Get King/Queen position
        LD      (M2),a          ; Save
        XOR     a
        LD      (M4),a          ; Clear pinned piece saved pos
        LD      c,(iy+DIRECT)   ; Get direction of scan
PF5:    CALL    PATH            ; Compute next position
        AND     a             ; Is it empty ?
        JR      Z,PF5           ; Yes - jump
        CP      3             ; Off board ?
        JP      Z,PF25          ; Yes - jump
        CP      2             ; Piece of same color
        LD      a,(M4)          ; Load pinned piece position
        JR      Z,PF15          ; Yes - jump
        AND     a             ; Possible pin ?
        JP      Z,PF25          ; No - jump
        LD      a,(T2)          ; Piece type encountered
        CP      QUEEN         ; Queen ?
        JP      Z,PF19          ; Yes - jump
        LD      l,a             ; Save piece type
        LD      a,b             ; Direction counter
        CP      5             ; Non-diagonal direction ?
        JR      C,PF10          ; Yes - jump
        LD      a,l             ; Piece type
        CP      BISHOP        ; Bishop ?
        JP      NZ,PF25         ; No - jump
        JP      PF20            ; Jump
PF10:   LD      a,l             ; Piece type
        CP      ROOK          ; Rook ?
        JP      NZ,PF25         ; No - jump
        JP      PF20            ; Jump
PF15:   AND     a             ; Possible pin ?
        JP      NZ,PF25         ; No - jump
        LD      a,(M2)          ; Save possible pin position
        LD      (M4),a
        JP      PF5             ; Jump
PF19:   LD      a,(P1)          ; Load King or Queen
        AND     7             ; Clear flags
        CP      QUEEN         ; Queen ?
        JR      NZ,PF20         ; No - jump
        PUSH    bc              ; Save regs.
        PUSH    de
        PUSH    iy
        XOR     a             ; Zero out attack list
        LD      b,14
        LD      hl,ATKLST
back02: LD      (hl),a
        INC     hl
        DJNZ    back02
        LD      a,7             ; Set attack flag
        LD      (T1),a
        CALL    ATTACK          ; Find attackers/defenders
        LD      hl,WACT         ; White queen attackers
        LD      de,BACT         ; Black queen attackers
        LD      a,(P1)          ; Get queen
        BIT     7,a             ; Is she white ?
        JR      Z,rel008        ; Yes - skip
        EX      de,hl           ; Reverse for black
rel008: LD      a,(hl)          ; Number of defenders
        EX      de,hl           ; Reverse for attackers
        SUB     (hl)          ; Defenders minus attackers
        DEC     a               ; Less 1
        POP     iy              ; Restore regs.
        POP     de
        POP     bc
        JP      P,PF25          ; Jump if pin not valid
PF20:   LD      hl,NPINS        ; Address of pinned piece count
        INC     (hl)            ; Increment
        LD      ix,(NPINS)      ; Load pin list index
        LD      (ix+PLISTD),c   ; Save direction of pin
        LD      a,(M4)          ; Position of pinned piece
        LD      (ix+PLIST),a    ; Save in list
PF25:   INC     iy              ; Increment direction index
        DJNZ    PF27            ; Done ? No - Jump
PF26:   INC     de              ; Incr King/Queen pos index
        JP      PF1             ; Jump
PF27:   JP      PF2             ; Jump

;***********************************************************
; EXCHANGE ROUTINE
;***********************************************************
; FUNCTION:   --  To determine the exchange value of a
;                 piece on a given square by examining all
;                 attackers and defenders of that piece.
;
; CALLED BY:  --  POINTS
;
; CALLS:      --  NEXTAD
;
; ARGUMENTS:  --  None.
;***********************************************************
XCHNG:  EXX                     ; Swap regs.
        LD      a,(P1)          ; Piece attacked
        LD      hl,WACT         ; Addr of white attkrs/dfndrs
        LD      de,BACT         ; Addr of black attkrs/dfndrs
        BIT     7,a             ; Is piece white ?
        JR      Z,rel009        ; Yes - jump
        EX      de,hl           ; Swap list pointers
rel009: LD      b,(hl)          ; Init list counts
        EX      de,hl
        LD      c,(hl)
        EX      de,hl
        EXX                     ; Restore regs.
        LD      c,0             ; Init attacker/defender flag
        LD      e,0             ; Init points lost count
        LD      ix,(T3)         ; Load piece value index
        LD      d,(ix+PVALUE)   ; Get attacked piece value
        SLA     d               ; Double it
        LD      b,d             ; Save
        CALL    NEXTAD          ; Retrieve first attacker
        RET     Z               ; Return if none
XC10:   LD      l,a             ; Save attacker value
        CALL    NEXTAD          ; Get next defender
        JR      Z,XC18          ; Jump if none
        EX      af,af'          ; Save defender value
        LD      a,b             ; Get attacked value
        CP      l             ; Attacked less than attacker ?
        JR      NC,XC19         ; No - jump
        EX      af,af'          ; -Restore defender
XC15:   CP      l             ; Defender less than attacker ?
        RET     C               ; Yes - return
        CALL    NEXTAD          ; Retrieve next attacker value
        RET     Z               ; Return if none
        LD      l,a             ; Save attacker value
        CALL    NEXTAD          ; Retrieve next defender value
        JR      NZ,XC15         ; Jump if none
XC18:   EX      af,af'          ; Save Defender
        LD      a,b             ; Get value of attacked piece
XC19:   BIT     0,c             ; Attacker or defender ?
        JR      Z,rel010        ; Jump if defender
        NEG                     ; Negate value for attacker
rel010: ADD     a,e             ; Total points lost
        LD      e,a             ; Save total
        EX      af,af'          ; Restore previous defender
        RET     Z               ; Return if none
        LD      b,l             ; Prev attckr becomes defender
        JP      XC10            ; Jump

;***********************************************************
; NEXT ATTACKER/DEFENDER ROUTINE
;***********************************************************
; FUNCTION:   --  To retrieve the next attacker or defender
;                 piece value from the attack list, and delete
;                 that piece from the list.
;
; CALLED BY:  --  XCHNG
;
; CALLS:      --  None
;
; ARGUMENTS:  --  Attack list addresses.
;                 Side flag
;                 Attack list counts
;***********************************************************
NEXTAD: INC     c               ; Increment side flag
        EXX                     ; Swap registers
        LD      a,b             ; Swap list counts
        LD      b,c
        LD      c,a
        EX      de,hl           ; Swap list pointers
        XOR     a
        CP      b             ; At end of list ?
        JR      Z,NX6           ; Yes - jump
        DEC     b               ; Decrement list count
back03: INC     hl              ; Increment list pointer
        CP      (hl)          ; Check next item in list
        JR      Z,back03        ; Jump if empty
        RRD                     ; Get value from list
        ADD     a,a             ; Double it
        DEC     hl              ; Decrement list pointer
NX6:    EXX                     ; Restore regs.
        RET                     ; Return

;***********************************************************
; POINT EVALUATION ROUTINE
;***********************************************************
;FUNCTION:   --  To perform a static board evaluation and
;                derive a score for a given board position
;
; CALLED BY:  --  FNDMOV
;                 EVAL
;
; CALLS:      --  ATTACK
;                 XCHNG
;                 LIMIT
;
; ARGUMENTS:  --  None
;***********************************************************
POINTS: XOR     a             ; Zero out variables
        LD      (MTRL),a
        LD      (BRDC),a
        LD      (PTSL),a
        LD      (PTSW1),a
        LD      (PTSW2),a
        LD      (PTSCK),a
        LD      hl,T1           ; Set attacker flag
        LD      (hl),7
        LD      a,21            ; Init to first square on board
PT5:    LD      (M3),a          ; Save as board index
        LD      ix,(M3)         ; Load board index
        LD      a,(ix+BOARD)    ; Get piece from board
        CP      -1            ; Off board edge ?
        JP      Z,PT25          ; Yes - jump
        LD      hl,P1           ; Save piece, if any
        LD      (hl),a
        AND     7             ; Save piece type, if any
        LD      (T3),a
        CP      KNIGHT        ; Less than a Knight (Pawn) ?
        JR      C,PT6X          ; Yes - Jump
        CP      ROOK          ; Rook, Queen or King ?
        JR      C,PT6B          ; No - jump
        CP      KING          ; Is it a King ?
        JR      Z,PT6AA         ; Yes - jump
        LD      a,(MOVENO)      ; Get move number
        CP      7             ; Less than 7 ?
        JR      C,PT6A          ; Yes - Jump
        JP      PT6X            ; Jump
PT6AA:  BIT     4,(hl)          ; Castled yet ?
        JR      Z,PT6A          ; No - jump
        LD      a,+6            ; Bonus for castling
        BIT     7,(hl)          ; Check piece color
        JR      Z,PT6D          ; Jump if white
        LD      a,-6            ; Bonus for black castling
        JP      PT6D            ; Jump
PT6A:   BIT     3,(hl)          ; Has piece moved yet ?
        JR      Z,PT6X          ; No - jump
        JP      PT6C            ; Jump
PT6B:   BIT     3,(hl)          ; Has piece moved yet ?
        JR      NZ,PT6X         ; Yes - jump
PT6C:   LD      a,-2            ; Two point penalty for white
        BIT     7,(hl)          ; Check piece color
        JR      Z,PT6D          ; Jump if white
        LD      a,+2            ; Two point penalty for black
PT6D:   LD      hl,BRDC         ; Get address of board control
        ADD     a,(hl)          ; Add on penalty/bonus points
        LD      (hl),a          ; Save
PT6X:   XOR     a             ; Zero out attack list
        LD      b,14
        LD      hl,ATKLST
back04: LD      (hl),a
        INC     hl
        DJNZ    back04
        CALL    ATTACK          ; Build attack list for square
        LD      hl,BACT         ; Get black attacker count addr
        LD      a,(WACT)        ; Get white attacker count
        SUB     (hl)          ; Compute count difference
        LD      hl,BRDC         ; Address of board control
        ADD     a,(hl)          ; Accum board control score
        LD      (hl),a          ; Save
        LD      a,(P1)          ; Get piece on current square
        AND     a             ; Is it empty ?
        JP      Z,PT25          ; Yes - jump
        CALL    XCHNG           ; Evaluate exchange, if any
        XOR     a             ; Check for a loss
        CP      e             ; Points lost ?
        JR      Z,PT23          ; No - Jump
        DEC     d               ; Deduct half a Pawn value
        LD      a,(P1)          ; Get piece under attack
        LD      hl,COLOR        ; Color of side just moved
        XOR     (hl)          ; Compare with piece
        BIT     7,a             ; Do colors match ?
        LD      a,e             ; Points lost
        JR      NZ,PT20         ; Jump if no match
        LD      hl,PTSL         ; Previous max points lost
        CP      (hl)          ; Compare to current value
        JR      C,PT23          ; Jump if greater than
        LD      (hl),e          ; Store new value as max lost
        LD      ix,(MLPTRJ)     ; Load pointer to this move
        LD      a,(M3)          ; Get position of lost piece
        CP      (ix+MLTOP)    ; Is it the one moving ?
        JR      NZ,PT23         ; No - jump
        LD      (PTSCK),a       ; Save position as a flag
        JP      PT23            ; Jump
PT20:   LD      hl,PTSW1        ; Previous maximum points won
        CP      (hl)          ; Compare to current value
        JR      C,rel011        ; Jump if greater than
        LD      a,(hl)          ; Load previous max value
        LD      (hl),e          ; Store new value as max won
rel011: LD      hl,PTSW2        ; Previous 2nd max points won
        CP      (hl)          ; Compare to current value
        JR      C,PT23          ; Jump if greater than
        LD      (hl),a          ; Store as new 2nd max lost
PT23:   LD      hl,P1           ; Get piece
        BIT     7,(hl)          ; Test color
        LD      a,d             ; Value of piece
        JR      Z,rel012        ; Jump if white
        NEG                     ; Negate for black
rel012: LD      hl,MTRL         ; Get addrs of material total
        ADD     a,(hl)          ; Add new value
        LD      (hl),a          ; Store
PT25:   LD      a,(M3)          ; Get current board position
        INC     a               ; Increment
        CP      99            ; At end of board ?
        JP      NZ,PT5          ; No - jump
        LD      a,(PTSCK)       ; Moving piece lost flag
        AND     a             ; Was it lost ?
        JR      Z,PT25A         ; No - jump
        LD      a,(PTSW2)       ; 2nd max points won
        LD      (PTSW1),a       ; Store as max points won
        XOR     a             ; Zero out 2nd max points won
        LD      (PTSW2),a
PT25A:  LD      a,(PTSL)        ; Get max points lost
        AND     a             ; Is it zero ?
        JR      Z,rel013        ; Yes - jump
        DEC     a               ; Decrement it
rel013: LD      b,a             ; Save it
        LD      a,(PTSW1)       ; Max,points won
        AND     a             ; Is it zero ?
        JR      Z,rel014        ; Yes - jump
        LD      a,(PTSW2)       ; 2nd max points won
        AND     a             ; Is it zero ?
        JR      Z,rel014        ; Yes - jump
        DEC     a               ; Decrement it
        SRL     a               ; Divide it by 2
rel014: SUB     b             ; Subtract points lost
        LD      hl,COLOR        ; Color of side just moved ???
        BIT     7,(hl)          ; Is it white ?
        JR      Z,rel015        ; Yes - jump
        NEG                     ; Negate for black
rel015: LD      hl,MTRL         ; Net material on board
        ADD     a,(hl)          ; Add exchange adjustments
        LD      hl,MV0          ; Material at ply 0
        SUB     (hl)          ; Subtract from current
        LD      b,a             ; Save
        LD      a,30            ; Load material limit
        CALL    LIMIT           ; Limit to plus or minus value
        LD      e,a             ; Save limited value
        LD      a,(BRDC)        ; Get board control points
        LD      hl,BC0          ; Board control at ply zero
        SUB     (hl)          ; Get difference
        LD      b,a             ; Save
        LD      a,(PTSCK)       ; Moving piece lost flag
        AND     a             ; Is it zero ?
        JR      Z,rel026        ; Yes - jump
        LD      b,0             ; Zero board control points
rel026: LD      a,6             ; Load board control limit
        CALL    LIMIT           ; Limit to plus or minus value
        LD      d,a             ; Save limited value
        LD      a,e             ; Get material points
        ADD     a,a             ; Multiply by 4
        ADD     a,a
        ADD     a,d             ; Add board control
        LD      hl,COLOR        ; Color of side just moved
        BIT     7,(hl)          ; Is it white ?
        JR      NZ,rel016       ; No - jump
        NEG                     ; Negate for white
rel016: ADD     a,80H           ; Rescale score (neutral = 80H)
        LD      (VALM),a        ; Save score
        LD      ix,(MLPTRJ)     ; Load move list pointer
        LD      (ix+MLVAL),a    ; Save score in move list
        RET                     ; Return

;***********************************************************
; LIMIT ROUTINE
;***********************************************************
; FUNCTION:   --  To limit the magnitude of a given value
;                 to another given value.
;
; CALLED BY:  --  POINTS
;
; CALLS:      --  None
;
; ARGUMENTS:  --  Input  - Value, to be limited in the B
;                          register.
;                        - Value to limit to in the A register
;                 Output - Limited value in the A register.
;***********************************************************
LIMIT:  BIT     7,b             ; Is value negative ?
        JP      Z,LIM10         ; No - jump
        NEG                     ; Make positive
        CP      b             ; Compare to limit
        RET     NC              ; Return if outside limit
        LD      a,b             ; Output value as is
        RET                     ; Return
LIM10:  CP      b             ; Compare to limit
        RET     C               ; Return if outside limit
        LD      a,b             ; Output value as is
        RET                     ; Return

;***********************************************************
; MOVE ROUTINE
;***********************************************************
; FUNCTION:   --  To execute a move from the move list on the
;                 board array.
;
; CALLED BY:  --  CPTRMV
;                 PLYRMV
;                 EVAL
;                 FNDMOV
;                 VALMOV
;
; CALLS:      --  None
;
; ARGUMENTS:  --  None
;***********************************************************
MOVE:   LD      hl,(MLPTRJ)     ; Load move list pointer
        INC     hl              ; Increment past link bytes
        INC     hl
MV1:    LD      a,(hl)          ; "From" position
        LD      (M1),a          ; Save
        INC     hl              ; Increment pointer
        LD      a,(hl)          ; "To" position
        LD      (M2),a          ; Save
        INC     hl              ; Increment pointer
        LD      d,(hl)          ; Get captured piece/flags
        LD      ix,(M1)         ; Load "from" pos board index
        LD      e,(ix+BOARD)    ; Get piece moved
        BIT     5,d             ; Test Pawn promotion flag
        JR      NZ,MV15         ; Jump if set
        LD      a,e             ; Piece moved
        AND     7             ; Clear flag bits
        CP      QUEEN         ; Is it a queen ?
        JR      Z,MV20          ; Yes - jump
        CP      KING          ; Is it a king ?
        JR      Z,MV30          ; Yes - jump
MV5:    LD      iy,(M2)         ; Load "to" pos board index
        SET     3,e             ; Set piece moved flag
        LD      (iy+BOARD),e    ; Insert piece at new position
        LD      (ix+BOARD),0    ; Empty previous position
        BIT     6,d             ; Double move ?
        JR      NZ,MV40         ; Yes - jump
        LD      a,d             ; Get captured piece, if any
        AND     7
        CP      QUEEN         ; Was it a queen ?
        RET     NZ              ; No - return
        LD      hl,POSQ         ; Addr of saved Queen position
        BIT     7,d             ; Is Queen white ?
        JR      Z,MV10          ; Yes - jump
        INC     hl              ; Increment to black Queen pos
MV10:   XOR     a             ; Set saved position to zero
        LD      (hl),a
        RET                     ; Return
MV15:   SET     2,e             ; Change Pawn to a Queen
        JP      MV5             ; Jump
MV20:   LD      hl,POSQ         ; Addr of saved Queen position
MV21:   BIT     7,e             ; Is Queen white ?
        JR      Z,MV22          ; Yes - jump
        INC     hl              ; Increment to black Queen pos
MV22:   LD      a,(M2)          ; Get new Queen position
        LD      (hl),a          ; Save
        JP      MV5             ; Jump
MV30:   LD      hl,POSK         ; Get saved King position
        BIT     6,d             ; Castling ?
        JR      Z,MV21          ; No - jump
        SET     4,e             ; Set King castled flag
        JP      MV21            ; Jump
MV40:   LD      hl,(MLPTRJ)     ; Get move list pointer
        LD      de,8            ; Increment to next move
        ADD     hl,de
        JP      MV1             ; Jump (2nd part of dbl move)

;***********************************************************
; UN-MOVE ROUTINE
;***********************************************************
; FUNCTION:   --  To reverse the process of the move routine,
;                 thereby restoring the board array to its
;                 previous position.
;
; CALLED BY:  --  VALMOV
;                 EVAL
;                 FNDMOV
;                 ASCEND
;
; CALLS:      --  None
;
; ARGUMENTS:  --  None
;***********************************************************
UNMOVE: LD      hl,(MLPTRJ)     ; Load move list pointer
        INC     hl              ; Increment past link bytes
        INC     hl
UM1:    LD      a,(hl)          ; Get "from" position
        LD      (M1),a          ; Save
        INC     hl              ; Increment pointer
        LD      a,(hl)          ; Get "to" position
        LD      (M2),a          ; Save
        INC     hl              ; Increment pointer
        LD      d,(hl)          ; Get captured piece/flags
        LD      ix,(M2)         ; Load "to" pos board index
        LD      e,(ix+BOARD)    ; Get piece moved
        BIT     5,d             ; Was it a Pawn promotion ?
        JR      NZ,UM15         ; Yes - jump
        LD      a,e             ; Get piece moved
        AND     7             ; Clear flag bits
        CP      QUEEN         ; Was it a Queen ?
        JR      Z,UM20          ; Yes - jump
        CP      KING          ; Was it a King ?
        JR      Z,UM30          ; Yes - jump
UM5:    BIT     4,d             ; Is this 1st move for piece ?
        JR      NZ,UM16         ; Yes - jump
UM6:    LD      iy,(M1)         ; Load "from" pos board index
        LD      (iy+BOARD),e    ; Return to previous board pos
        LD      a,d             ; Get captured piece, if any
        AND     8FH           ; Clear flags
        LD      (ix+BOARD),a    ; Return to board
        BIT     6,d             ; Was it a double move ?
        JR      NZ,UM40         ; Yes - jump
        LD      a,d             ; Get captured piece, if any
        AND     7             ; Clear flag bits
        CP      QUEEN         ; Was it a Queen ?
        RET     NZ              ; No - return
        LD      hl,POSQ         ; Address of saved Queen pos
        BIT     7,d             ; Is Queen white ?
        JR      Z,UM10          ; Yes - jump
        INC     hl              ; Increment to black Queen pos
UM10:   LD      a,(M2)          ; Queen's previous position
        LD      (hl),a          ; Save
        RET                     ; Return
UM15:   RES     2,e             ; Restore Queen to Pawn
        JP      UM5             ; Jump
UM16:   RES     3,e             ; Clear piece moved flag
        JP      UM6             ; Jump
UM20:   LD      hl,POSQ         ; Addr of saved Queen position
UM21:   BIT     7,e             ; Is Queen white ?
        JR      Z,UM22          ; Yes - jump
        INC     hl              ; Increment to black Queen pos
UM22:   LD      a,(M1)          ; Get previous position
        LD      (hl),a          ; Save
        JP      UM5             ; Jump
UM30:   LD      hl,POSK         ; Address of saved King pos
        BIT     6,d             ; Was it a castle ?
        JR      Z,UM21          ; No - jump
        RES     4,e             ; Clear castled flag
        JP      UM21            ; Jump
UM40:   LD      hl,(MLPTRJ)     ; Load move list pointer
        LD      de,8            ; Increment to next move
        ADD     hl,de
        JP      UM1             ; Jump (2nd part of dbl move)

;***********************************************************
; SORT ROUTINE
;***********************************************************
; FUNCTION:   --  To sort the move list in order of
;                 increasing move value scores.
;
; CALLED BY:  --  FNDMOV
;
; CALLS:      --  EVAL
;
; ARGUMENTS:  --  None
;***********************************************************
SORTM:  LD      bc,(MLPTRI)     ; Move list begin pointer
        LD      de,0            ; Initialize working pointers
SR5:    LD      h,b
        LD      l,c
        LD      c,(hl)          ; Link to next move
        INC     hl
        LD      b,(hl)
        LD      (hl),d          ; Store to link in list
        DEC     hl
        LD      (hl),e
        XOR     a             ; End of list ?
        CP      b
        RET     Z               ; Yes - return
SR10:   LD      (MLPTRJ),bc     ; Save list pointer
        CALL    EVAL            ; Evaluate move
        LD      hl,(MLPTRI)     ; Begining of move list
        LD      bc,(MLPTRJ)     ; Restore list pointer
SR15:   LD      e,(hl)          ; Next move for compare
        INC     hl
        LD      d,(hl)
        XOR     a             ; At end of list ?
        CP      d
        JR      Z,SR25          ; Yes - jump
        PUSH    de              ; Transfer move pointer
        POP     ix
        LD      a,(VALM)        ; Get new move value
        CP      (ix+MLVAL)    ; Less than list value ?
        JR      NC,SR30         ; No - jump
SR25:   LD      (hl),b          ; Link new move into list
        DEC     hl
        LD      (hl),c
        JP      SR5             ; Jump
SR30:   EX      de,hl           ; Swap pointers
        JP      SR15            ; Jump

;***********************************************************
; EVALUATION ROUTINE
;***********************************************************
; FUNCTION:   --  To evaluate a given move in the move list.
;                 It first makes the move on the board, then if
;                 the move is legal, it evaluates it, and then
;                 restores the board position.
;
; CALLED BY:  --  SORT
;
; CALLS:      --  MOVE
;                 INCHK
;                 PINFND
;                 POINTS
;                 UNMOVE
;
; ARGUMENTS:  --  None
;***********************************************************
EVAL:   CALL    MOVE            ; Make move on the board array
        CALL    INCHK           ; Determine if move is legal
        AND     a             ; Legal move ?
        JR      Z,EV5           ; Yes - jump
        XOR     a             ; Score of zero
        LD      (VALM),a        ; For illegal move
        JP      EV10            ; Jump
EV5:    CALL    PINFND          ; Compile pinned list
        CALL    POINTS          ; Assign points to move
EV10:   CALL    UNMOVE          ; Restore board array
        RET                     ; Return

;***********************************************************
; FIND MOVE ROUTINE
;***********************************************************
; FUNCTION:   --  To determine the computer's best move by
;                 performing a depth first tree search using
;                 the techniques of alpha-beta pruning.
;
; CALLED BY:  --  CPTRMV
;
; CALLS:      --  PINFND
;                 POINTS
;                 GENMOV
;                 SORTM
;                 ASCEND
;                 UNMOVE
;
; ARGUMENTS:  --  None
;***********************************************************
FNDMOV: LD      a,(MOVENO)      ; Current move number
        CP      1             ; First move ?
        CALL    Z,BOOK          ; Yes - execute book opening
        XOR     a             ; Initialize ply number to zero
        LD      (NPLY),a
        LD      hl,0            ; Initialize best move to zero
        LD      (BESTM),hl
        LD      hl,MLIST        ; Initialize ply list pointers
        LD      (MLNXT),hl
        LD      hl,PLYIX-2
        LD      (MLPTRI),hl
        LD      a,(KOLOR)       ; Initialize color
        LD      (COLOR),a
        LD      hl,SCORE        ; Initialize score index
        LD      (SCRIX),hl
        LD      a,(PLYMAX)      ; Get max ply number
        ADD     a,2             ; Add 2
        LD      b,a             ; Save as counter
        XOR     a             ; Zero out score table
back05: LD      (hl),a
        INC     hl
        DJNZ    back05
        LD      (BC0),a         ; Zero ply 0 board control
        LD      (MV0),a         ; Zero ply 0 material
        CALL    PINFND          ; Compile pin list
        CALL    POINTS          ; Evaluate board at ply 0
        LD      a,(BRDC)        ; Get board control points
        LD      (BC0),a         ; Save
        LD      a,(MTRL)        ; Get material count
        LD      (MV0),a         ; Save
FM5:    LD      hl,NPLY         ; Address of ply counter
        INC     (hl)            ; Increment ply count
        XOR     a             ; Initialize mate flag
        LD      (MATEF),a
        CALL    GENMOV          ; Generate list of moves
        LD      a,(NPLY)        ; Current ply counter
        LD      hl,PLYMAX       ; Address of maximum ply number
        CP      (hl)          ; At max ply ?
        CALL    C,SORTM         ; No - call sort
        LD      hl,(MLPTRI)     ; Load ply index pointer
        LD      (MLPTRJ),hl     ; Save as last move pointer
FM15:   LD      hl,(MLPTRJ)     ; Load last move pointer
        LD      e,(hl)          ; Get next move pointer
        INC     hl
        LD      d,(hl)
        LD      a,d
        AND     a             ; End of move list ?
        JR      Z,FM25          ; Yes - jump
        LD      (MLPTRJ),de     ; Save current move pointer
        LD      hl,(MLPTRI)     ; Save in ply pointer list
        LD      (hl),e
        INC     hl
        LD      (hl),d
        LD      a,(NPLY)        ; Current ply counter
        LD      hl,PLYMAX       ; Maximum ply number ?
        CP      (hl)          ; Compare
        JR      C,FM18          ; Jump if not max
        CALL    MOVE            ; Execute move on board array
        CALL    INCHK           ; Check for legal move
        AND     a             ; Is move legal
        JR      Z,rel017        ; Yes - jump
        CALL    UNMOVE          ; Restore board position
        JP      FM15            ; Jump
rel017: LD      a,(NPLY)        ; Get ply counter
        LD      hl,PLYMAX       ; Max ply number
        CP      (hl)          ; Beyond max ply ?
        JR      NZ,FM35         ; Yes - jump
        LD      a,(COLOR)       ; Get current color
        XOR     80H           ; Get opposite color
        CALL    INCHK1          ; Determine if King is in check
        AND     a             ; In check ?
        JR      Z,FM35          ; No - jump
        JP      FM19            ; Jump (One more ply for check)
FM18:   LD      ix,(MLPTRJ)     ; Load move pointer
        LD      a,(ix+MLVAL)    ; Get move score
        AND     a             ; Is it zero (illegal move) ?
        JR      Z,FM15          ; Yes - jump
        CALL    MOVE            ; Execute move on board array
FM19:   LD      hl,COLOR        ; Toggle color
        LD      a,80H
        XOR     (hl)
        LD      (hl),a          ; Save new color
        BIT     7,a             ; Is it white ?
        JR      NZ,rel018       ; No - jump
        LD      hl,MOVENO       ; Increment move number
        INC     (hl)
rel018: LD      hl,(SCRIX)      ; Load score table pointer
        LD      a,(hl)          ; Get score two plys above
        INC     hl              ; Increment to current ply
        INC     hl
        LD      (hl),a          ; Save score as initial value
        DEC     hl              ; Decrement pointer
        LD      (SCRIX),hl      ; Save it
        JP      FM5             ; Jump
FM25:   LD      a,(MATEF)       ; Get mate flag
        AND     a             ; Checkmate or stalemate ?
        JR      NZ,FM30         ; No - jump
        LD      a,(CKFLG)       ; Get check flag
        AND     a             ; Was King in check ?
        LD      a,80H           ; Pre-set stalemate score
        JR      Z,FM36          ; No - jump (stalemate)
        LD      a,(MOVENO)      ; Get move number
        LD      (PMATE),a       ; Save
        LD      a,0FFH          ; Pre-set checkmate score
        JP      FM36            ; Jump
FM30:   LD      a,(NPLY)        ; Get ply counter
        CP      1             ; At top of tree ?
        RET     Z               ; Yes - return
        CALL    ASCEND          ; Ascend one ply in tree
        LD      hl,(SCRIX)      ; Load score table pointer
        INC     hl              ; Increment to current ply
        INC     hl
        LD      a,(hl)          ; Get score
        DEC     hl              ; Restore pointer
        DEC     hl
        JP      FM37            ; Jump
FM35:   CALL    PINFND          ; Compile pin list
        CALL    POINTS          ; Evaluate move
        CALL    UNMOVE          ; Restore board position
        LD      a,(VALM)        ; Get value of move
FM36:   LD      hl,MATEF        ; Set mate flag
        SET     0,(hl)
        LD      hl,(SCRIX)      ; Load score table pointer
FM37:
        CP      (hl)          ; Compare to score 2 ply above
        JR      C,FM40          ; Jump if less
        JR      Z,FM40          ; Jump if equal
        NEG                     ; Negate score
        INC     hl              ; Incr score table pointer
        CP      (hl)          ; Compare to score 1 ply above
        JP      C,FM15          ; Jump if less than
        JP      Z,FM15          ; Jump if equal
        LD      (hl),a          ; Save as new score 1 ply above
        LD      a,(NPLY)        ; Get current ply counter
        CP      1             ; At top of tree ?
        JP      NZ,FM15         ; No - jump
        LD      hl,(MLPTRJ)     ; Load current move pointer
        LD      (BESTM),hl      ; Save as best move pointer
        LD      a,(SCORE+1)     ; Get best move score
        CP      0FFH          ; Was it a checkmate ?
        JP      NZ,FM15         ; No - jump
        LD      hl,PLYMAX       ; Get maximum ply number
        DEC     (hl)            ; Subtract 2
        DEC     (hl)
        LD      a,(KOLOR)       ; Get computer's color
        BIT     7,a             ; Is it white ?
        RET     Z               ; Yes - return
        LD      hl,PMATE        ; Checkmate move number
        DEC     (hl)            ; Decrement
        RET                     ; Return
FM40:   CALL    ASCEND          ; Ascend one ply in tree
        JP      FM15            ; Jump

;***********************************************************
; ASCEND TREE ROUTINE
;***********************************************************
; FUNCTION:  --  To adjust all necessary parameters to
;                ascend one ply in the tree.
;
; CALLED BY: --  FNDMOV
;
; CALLS:     --  UNMOVE
;
; ARGUMENTS: --  None
;***********************************************************
ASCEND: LD      hl,COLOR        ; Toggle color
        LD      a,80H
        XOR     (hl)
        LD      (hl),a          ; Save new color
        BIT     7,a             ; Is it white ?
        JR      Z,rel019        ; Yes - jump
        LD      hl,MOVENO       ; Decrement move number
        DEC     (hl)
rel019: LD      hl,(SCRIX)      ; Load score table index
        DEC     hl              ; Decrement
        LD      (SCRIX),hl      ; Save
        LD      hl,NPLY         ; Decrement ply counter
        DEC     (hl)
        LD      hl,(MLPTRI)     ; Load ply list pointer
        DEC     hl              ; Load pointer to move list top
        LD      d,(hl)
        DEC     hl
        LD      e,(hl)
        LD      (MLNXT),de      ; Update move list avail ptr
        DEC     hl              ; Get ptr to next move to undo
        LD      d,(hl)
        DEC     hl
        LD      e,(hl)
        LD      (MLPTRI),hl     ; Save new ply list pointer
        LD      (MLPTRJ),de     ; Save next move pointer
        CALL    UNMOVE          ; Restore board to previous ply
        RET                     ; Return

;***********************************************************
; ONE MOVE BOOK OPENING
; **********************************************************
; FUNCTION:   --  To provide an opening book of a single
;                 move.
;
; CALLED BY:  --  FNDMOV
;
; CALLS:      --  None
;
; ARGUMENTS:  --  None
;***********************************************************
BOOK:   POP     af              ; Abort return to FNDMOV
        LD      hl,SCORE+1      ; Zero out score
        LD      (hl),0          ; Zero out score table
        LD      hl,BMOVES-2     ; Init best move ptr to book
        LD      (BESTM),hl
        LD      hl,BESTM        ; Initialize address of pointer
        LD      a,(KOLOR)       ; Get computer's color
        AND     a             ; Is it white ?
        JR      NZ,BM5          ; No - jump
        LD      a,r             ; Load refresh reg (random no)
        BIT     0,a             ; Test random bit
        RET     Z               ; Return if zero (P-K4)
        INC     (hl)            ; P-Q4
        INC     (hl)
        INC     (hl)
        RET                     ; Return
BM5:    INC     (hl)            ; Increment to black moves
        INC     (hl)
        INC     (hl)
        INC     (hl)
        INC     (hl)
        INC     (hl)
        LD      ix,(MLPTRJ)     ; Pointer to opponents 1st move
        LD      a,(ix+MLFRP)    ; Get "from" position
        CP      22            ; Is it a Queen Knight move ?
        JR      Z,BM9           ; Yes - Jump
        CP      27            ; Is it a King Knight move ?
        JR      Z,BM9           ; Yes - jump
        CP      34            ; Is it a Queen Pawn ?
        JR      Z,BM9           ; Yes - jump
        RET     C               ; If Queen side Pawn opening -
                                ; return (P-K4)
        CP      35            ; Is it a King Pawn ?
        RET     Z               ; Yes - return (P-K4)
BM9:    INC     (hl)            ; (P-Q4)
        INC     (hl)
        INC     (hl)
        RET                     ; Return to CPTRMV

;*******************************************************
; GRAPHICS DATA BASE
;*******************************************************
; DESCRIPTION:  The Graphics Data Base contains the
;               necessary stored data to produce the piece
;               on the board. Only the center 4 x 4 blocks are
;               stored and only for a Black Piece on a White
;               square. A White piece on a black square is
;               produced by complementing each block, and a
;               piece on its own color square is produced
;               by moving in a kernel of 6 blocks.
;*******************************************************
        ORG     START+384
BLBASE  EQU     START+512
BLOCK   EQU     080H ; $-BLBASE     -128
        DB      80H,80H,80H,80H ; Black Pawn on White square
        DB      80H,0A0H,90H,80H
        DB      80H,0AFH,9FH,80H
        DB      80H,83H,83H,80H
        DB      80H,0B0H,0B0H,80H ; Black Knight on White square
        DB      0BEH,0BFH,0BFH,95H
        DB      0A0H,0BEH,0BFH,85H
        DB      83H,83H,83H,81H
        DB      80H,0A0H,00H,80H ; Black Bishop on White square
        DB      0A8H,0BFH,0BDH,80H
        DB      82H,0AFH,87H,80H
        DB      82H,83H,83H,80H
        DB      80H,80H,80H,80H ; Black Rook on White square
        DB      8AH,0BEH,0BDH,85H
        DB      80H,0BFH,0BFH,80H
        DB      82H,83H,83H,81H
        DB      90H,80H,80H,90H ; Black Queen on White square
        DB      0BFH,0B4H,0BEH,95H
        DB      8BH,0BFH,9FH,81H
        DB      83H,83H,83H,81H
        DB      80H,0B8H,90H,80H ; Black King on White square
        DB      0BCH,0BAH,0B8H,94H
        DB      0AFH,0BFH,0BFH,85H
        DB      83H,83H,83H,81H
        DB      90H,0B0H,0B0H,80H ; Toppled Black King
        DB      0BFH,0BFH,0B7H,80H
        DB      9FH,0BFH,0BDH,80H
        DB      80H,80H,88H,9DH
KERNEL  EQU     0F0H ; $-BLBASE
        DB      0BFH,9FH,0AFH,0BFH,9AH,0A5H ; Pawn Kernel
        DB      89H,0AFH,0BFH,9FH,0B9H,9FH ; Knight Kernel
        DB      97H,0BEH,96H,0BDH,9BH,0B9H ; Bishop Kernel
        DB      0B5H,0A1H,92H,0BFH,0AAH,95H ; Rook Kernel
        DB      0A8H,9BH,0B9H,0B6H,0AFH,0A7H ; Queen Kernel
        DB      0A3H,85H,0A7H,9AH,0BFH,9FH ; King Kernel
        DB      0A8H,0BFH,89H,0A2H,8FH,86H ; Toppled King Kernel

;*******************************************************
; STANDARD MESSAGES
;*******************************************************
        ORG     START+1800H
HELP:	 DB	13,10,13,10
	 DB	 "when moving a piece (e.g. e2-e4) hit ctrl^r to quit the game"
	 DB	 0dh,0ah,'$'
GRTTNG:  DB      "Welcome to sargon chess! Care for a game (n to quit) ?$"
ANAMSG:  DB      "WOULD YOU LIKE TO ANALYZE A POSITION?"
CLRMSG:  DB      "do you want to play white(w) or black(b)?"
TITLE1:  DB      "sargon"
TITLE2:  DB      "player"
SPACE:   DB      "                   "    ; For output of blank area
MVENUM:  DB      "01 "
TITLE3:  DB      "  ====== ======"
MVEMSG:  DB      "a1-a1"
O_O:     DB      "0-0  "
O_O_O:   DB      "0-0-0"
CKMSG:   DB      "check"
MTMSG:   DB      "mate in "
MTPL:    DB      "2"
PCS:     DB      "KQRBNP"        ; Valid piece characters
UWIN:    DB      "you win"
IWIN:    DB      "i win"
AGAIN:   DB      "care for another game (n to quit) ?$"
CRTNES:  DB      "IS THIS RIGHT?"
PLYDEP:  DB      "select look ahead (1-6)"
TITLE4:  DB      "                "
WSMOVE:  DB      "WHOSE MOVE IS IT?"
BLANKR:  DB      '[',1CH,']'     ; Control-\
P_PEP:   DB      "pxpep"
INVAL1:  DB      "invalid move"
INVAL2:  DB      "try again"


;*******************************************************
; VARIABLES
;*******************************************************
BRDPOS:  DS      1               ; Index into the board array
ANBDPS:  DS      1               ; Additional index required for ANALYS
INDXER:  DW      BLBASE          ; Index into graphics data base
NORMAD:  DS      2               ; The address of the upper left hand
                                ; corner of the square on the board
LINECT:  DB      0               ; Current line number

;*******************************************************
; MACRO DEFINITIONS
;*******************************************************
; All input/output to SARGON is handled in the form of
; macro calls to simplify conversion to alternate systems.
; All of the input/output macros conform to the Jove monitor
; of the Jupiter III computer.
;*******************************************************
;*** OUTPUT <CR><LF> ***
	MACRO	CARRET
        exx
        ex af, af'
        ld  c, BDOS_Console_Output
        ld  e, 13
        call BDOS
        ld  c, BDOS_Console_Output
        ld  e, 10
        call BDOS
        ex af, af'
        exx
        ENDM

;*** PRINT ANY LINE (NAME, LENGTH) ***
	MACRO	PRTLIN  NAME,LNGTH
        exx
        ex af, af'
        ld b, LNGTH
        ld hl, NAME
1:
        ld e, (hl)
        inc hl
        ld c, BDOS_Console_Output
        push hl
        push bc
        call BDOS
        pop bc
        pop hl
        djnz 1b
        ld a, 13
        call print_a
        ld a, 10
        call print_a
        ex af, af'
        exx
        ENDM

;*** PRINT ANY BLOCK (NAME, LENGTH) ***
	MACRO	PRTBLK  NAME,LNGTH
        exx
        ex af, af'
        ld b, LNGTH
        ld hl, NAME
2:
        ld e, (hl)
        inc hl
        ld c, BDOS_Console_Output
        push hl
        push bc
        call BDOS
        pop bc
        pop hl
        djnz 2b
        ex af, af'
        exx
        ENDM

;*** EXIT TO MONITOR ***
	MACRO	EXIT
	call	Restore_1_to_26
	call	Restore_64_to_89
        jp      0
        ENDM

;***********************************************************
; MAIN PROGRAM DRIVER
;***********************************************************
; FUNCTION:   --  To coordinate the game moves.
;
; CALLED BY:  --  None
;
; CALLS:      --  INTERR
;                 INITBD
;                 DSPBRD
;                 CPTRMV
;                 PLYRMV
;                 TBCPCL
;                 PGIFND
;
; MACRO CALLS:    CrtClear
;                 CARRET
;                 PRTLIN
;                 PRTBLK
;
; ARGUMENTS:      None
;***********************************************************
        ORG     START+1A00H     ; Above the move logic

DRIVER: LD      sp,STACK        ; Set stack pointer

        call    CrtClear        ; Blank out screen

	ld	de,copyright_message
	call	show_string_de

	ld	de,GRTTNG	; Output greeting
	call	show_string_de

	ld	c,BDOS_Console_Input
	call	BDOS
	and	5FH
        CP      'N'             ; Is it a 'N' ?
	jp	z,0		; If yes, quit

	call    CrtClear

	call	Save_1_to_26	; Save old fonts			
	call	Save_64_to_89
	
	call	Load_1_to_26	; Load new fonts
	call	Load_64_to_89

	jp	GO

DRIV01: 
	CALL    CHARTR          ; Accept answer
        CARRET                  ; New line
        CP      'N'             ; Is it a 'N' ?
	jp	nz,GO
	EXIT
;       JP      Z,ANALYS        ; If so then jump to ANALYSing a position
GO:
        SUB     a               ; Code of White is zero
        LD      (COLOR),a       ; White always moves first

	ld	de,HELP		; Output help
	call	show_string_de

        CALL    INTERR          ; Players color/search depth

        call    CrtClear	; Clear screen
	call	InitRTC		; Initialize real time clock

        CALL    INITBD          ; Initialize board array
        LD      a,1             ; Move number is 1 at at start
        LD      (MOVENO),a      ; Save
        LD      (LINECT),a      ; Line number is one at start
        LD      hl,MVENUM       ; Address of ascii move number
        LD      (hl),30H        ; Init to '01 '
        INC     hl
        LD      (hl),31H
        INC     hl
        LD      (hl),20H
        CALL    DSPBRD          ; Set up graphics board
        PRTLIN  TITLE4,15       ; Put up player headings
        PRTLIN  TITLE3,15
DRIV04: 
	PRTBLK  MVENUM,3        ; Display move number
        LD      a,(KOLOR)       ; Bring in computer's color
        AND     a               ; Is it white ?
        JR      NZ,DR08         ; No - jump

        CALL    PGIFND          ; New page if needed
        CP      1               ; Was page turned ?
        CALL    Z,TBCPCL        ; Yes - Tab to computers column

	call	GetStartTime
        CALL    CPTRMV          ; Make and write computers move
	call	GetStopTime
        PRTBLK  SPACE,1         ; Output a space
	call	PrintLapseTime
        PRTBLK  SPACE,1         ; Output a space

	call	GetStartTime
        CALL    PLYRMV          ; Accept and make players move
	call	GetStopTime
        PRTBLK  SPACE,1         ; Output a space
	call	PrintLapseTime
        CARRET                  ; New line

        JR      DR0C            ; Jump
DR08:   
	call	GetStartTime
	CALL    PLYRMV          ; Accept and make players move
	call	GetStopTime
        PRTBLK  SPACE,1         ; Output a space
	call	PrintLapseTime
        PRTBLK  SPACE,1         ; Output a space

        CALL    PGIFND          ; New page if needed
        CP      1               ; Was page turned ?
        CALL    Z,TBCPCL        ; Yes - Tab to computers column

	call	GetStartTime
        CALL    CPTRMV          ; Make and write computers move
	call	GetStopTime
        PRTBLK  SPACE,1         ; Output a space
	call	PrintLapseTime
        CARRET                  ; New line

DR0C:   LD      hl,MVENUM+2     ; Addr of 3rd char of move
        LD      a,20H           ; Ascii space
        CP      (hl)          ; Is char a space ?
        LD      a,3AH           ; Set up test value
        JR      Z,DR10          ; Yes - jump
        INC     (hl)            ; Increment value
        CP      (hl)          ; Over Ascii 9 ?
        JR      NZ,DR14         ; No - jump
        LD      (hl),30H        ; Set char to zero
DR10:   DEC     hl              ; 2nd char of Ascii move no.
        INC     (hl)            ; Increment value
        CP      (hl)          ; Over Ascii 9 ?
        JR      NZ,DR14         ; No - jump
        LD      (hl),30H        ; Set char to zero
        DEC     hl              ; 1st char of Ascii move no.
        INC     (hl)            ; Increment value
        CP      (hl)          ; Over Ascii 9 ?
        JR      NZ,DR14         ; No - jump
        LD      (hl),31H        ; Make 1st char a one
        LD      a,30H           ; Make 3rd char a zero
        LD      (MVENUM+2),a
DR14:   LD      hl,MOVENO       ; Hexadecimal move number
        INC     (hl)            ; Increment
        JP      DRIV04          ; Jump

;***********************************************************
; INTERROGATION FOR PLY & COLOR
;***********************************************************
; FUNCTION:   --  To query the player for his choice of ply
;                 depth and color.
;
; CALLED BY:  --  DRIVER
;
; CALLS:      --  CHARTR
;
; MACRO CALLS:    PRTLIN
;                 CARRET
;
; ARGUMENTS:  --  None
;***********************************************************
INTERR: PRTLIN  CLRMSG,41       ; Request color choice
        CALL    CHARTR          ; Accept response
        CARRET                  ; New line
        CP      'B'             ; Did player request black ?
        JR      NZ,IN04          ; Yes - branch
        SUB     a               ; Set computers color to white
        LD      (KOLOR),a
        LD      hl,TITLE1       ; Prepare move list titles
        LD      de,TITLE4+2
        LD      bc,6
        LDIR
        LD      hl,TITLE2
        LD      de,TITLE4+9
        LD      bc,6
        LDIR
        JR      IN08            ; Jump
IN04:   LD      a,80H           ; Set computers color to black
        LD      (KOLOR),a
        LD      hl,TITLE2       ; Prepare move list titles
        LD      de,TITLE4+2
        LD      bc,6
        LDIR
        LD      hl,TITLE1
        LD      de,TITLE4+9
        LD      bc,6
        LDIR
IN08:   PRTLIN  PLYDEP,23       ; Request depth of search
        CALL    CHARTR          ; Accept response
        CARRET                  ; New line
        LD      hl,PLYMAX       ; Address of ply depth variabl
        LD      (hl),2          ; Default depth of search
        CP      31H           ; Under minimum of 1 ?
        RET     M               ; Yes - return
        CP      37H           ; Over maximum of 6 ?
        RET     P               ; Yes - return
        SUB     30H           ; Subtract Ascii constant
        LD      (hl),a          ; Set desired depth
        RET                     ; Return

;***********************************************************
; COMPUTER MOVE ROUTINE
;***********************************************************
; FUNCTION:   --  To control the search for the computers move
;                 and the display of that move on the board
;                 and in the move list.
;
; CALLED BY:  --  DRIVER
;
; CALLS:      --  FNDMOV
;                 FCDMAT
;                 MOVE
;                 EXECMV
;                 BITASN
;                 INCHK
;
; MACRO CALLS:    PRTBLK
;                 CARRET
;
; ARGUMENTS:  --  None
;***********************************************************
CPTRMV: CALL    FNDMOV          ; Select best move
        LD      hl,(BESTM)      ; Move list pointer variable
        LD      (MLPTRJ),hl     ; Pointer to move data
        LD      a,(SCORE+1)     ; To check for mates
        CP      1               ; Mate against computer ?
        JR      NZ, CP0C        ; No
        LD      c,1             ; Computer mate flag
        CALL    FCDMAT          ; Full checkmate ?
CP0C:   CALL    MOVE            ; Produce move on board array
        CALL    EXECMV          ; Make move on graphics board
                                ; and return info about it
        LD      a,b             ; Special move flags
        AND     a               ; Special ?
        JR      NZ,CP10         ; Yes - jump
        LD      d,e             ; "To" position of the move
        CALL    BITASN          ; Convert to Ascii
        LD      (MVEMSG+3),hl   ; Put in move message
        LD      d,c             ; "From" position of the move
        CALL    BITASN          ; Convert to Ascii
        LD      (MVEMSG),hl     ; Put in move message
        PRTBLK  MVEMSG,5        ; Output text of move
        JR      CP1C            ; Jump
CP10:   BIT     1,b             ; King side castle ?
        JR      Z,rel020        ; No - jump
        PRTBLK  O_O,5           ; Output "O-O"
        JR      CP1C            ; Jump
rel020: BIT     2,b             ; Queen side castle ?
        JR      Z,rel021        ; No - jump
        PRTBLK  O_O_O,5         ; Output "O-O-O"
        JR      CP1C            ; Jump
rel021: PRTBLK  P_PEP,5         ; Output "PxPep" - En passant
CP1C:   LD      a,(COLOR)       ; Should computer call check ?
        LD      b,a
        XOR     80H           ; Toggle color
        LD      (COLOR),a
        CALL    INCHK           ; Check for check
        AND     a             ; Is enemy in check ?
        LD      a,b             ; Restore color
        LD      (COLOR),a
        JR      Z,CP24          ; No - return
        CARRET                  ; New line
        LD      a,(SCORE+1)     ; Check for player mated
        CP      0FFH          ; Forced mate ?
        CALL    NZ,TBCPMV       ; No - Tab to computer column
        PRTBLK  CKMSG,5         ; Output "check"
        LD      hl,LINECT       ; Address of screen line count
        INC     (hl)            ; Increment for message
CP24:   LD      a,(SCORE+1)     ; Check again for mates
        CP      0FFH            ; Player mated ?
        RET     NZ              ; No - return
        LD      c,0             ; Set player mate flag
        CALL    FCDMAT          ; Full checkmate ?
        RET                     ; Return

;***********************************************************
; FORCED MATE HANDLING
;***********************************************************
; FUNCTION:   --  To examine situations where there exits
;                 a forced mate and determine whether or
;                 not the current move is checkmate. If it is,
;                 a losing player is offered another game,
;                 while a loss for the computer signals the
;                 King to tip over in resignation.
;
; CALLED BY:  --  CPTRMV
;
; CALLS:      --  MATED
;                 CHARTR
;                 TBPLMV
;
; ARGUMENTS:  --  The only value passed in a register is the
;                 flag which tells FCDMAT whether the computer
;                 or the player is mated.
;***********************************************************
FCDMAT: LD      a,(MOVENO)      ; Current move number
        LD      b,a             ; Save
        LD      a,(PMATE)       ; Move number where mate occurs
        SUB     b               ; Number of moves till mate
        AND     a               ; Checkmate ?
        JP      NZ,FM0C         ; No - jump
        BIT     0,c             ; Check flag for who is mated
        JP      Z,FM04          ; Jump if player
        CARRET                  ; New line
        PRTLIN  CKMSG,9         ; Print "CHECKMATE"
        CALL    MATED           ; Tip over King
        PRTLIN  UWIN,7          ; Output "YOU WIN"
        JR      FM08            ; Jump
FM04:   PRTLIN  MTMSG,4         ; Output "MATE"
        PRTLIN  IWIN,5          ; Output "I WIN"
FM08:   POP     hl              ; Remove return addresses
        POP     hl
        CALL    CHARTR          ; Input any char to play again
FM09:   call CrtClear                  ; Blank screen
	ld	de,AGAIN
	call	show_string_de	; "CARE FOR ANOTHER GAME?"
        JP      DRIV01          ; Jump (Rest of game init)
FM0C:   BIT     0,c             ; Who has forced mate ?
        RET     NZ              ; Return if player
        CARRET                  ; New line
        ADD     a,30H           ; Number of moves to Ascii
        LD      (MTPL),a        ; Place value in message
        PRTLIN  MTMSG,9         ; Output "MATE IN x MOVES"
        CALL    TBPLMV          ; Tab to players column
        RET                     ; Return

;***********************************************************
; TAB TO PLAYERS COLUMN
;***********************************************************
; FUNCTION:   --  To space over in the move listing to the
;                 column in which the players moves are being
;                 recorded. This routine also reprints the
;                 move number.
;
; CALLED BY:  --  PLYRMV
;
; CALLS:      --  None
;
; MACRO CALLS:    PRTBLK
;
; ARGUMENTS:  --  None
;***********************************************************
TBPLCL: PRTBLK  MVENUM,3        ; Reproduce move number
        LD      a,(KOLOR)       ; Computers color
        AND     a             ; Is computer white ?
        RET     NZ              ; No - return
        PRTBLK  SPACE,15         ; Tab to next column
        RET                     ; Return

;***********************************************************
; TAB TO COMPUTERS COLUMN
;***********************************************************
; FUNCTION:   --  To space over in the move listing to the
;                 column in which the computers moves are
;                 being recorded. This routine also reprints
;                 the move number.
;
; CALLED BY:  --  DRIVER
;                 CPTRMV
;
; CALLS:      --  None
;
; MACRO CALLS:    PRTBLK
;
; ARGUMENTS:  --  None
;***********************************************************
TBCPCL: PRTBLK  MVENUM,3        ; Reproduce move number
        LD      a,(KOLOR)       ; Computer's color
        AND     a             ; Is computer white ?
        RET     Z               ; Yes - return
        PRTBLK  SPACE,15        ; Tab to next column
        RET                     ; Return

;***********************************************************
; TAB TO PLAYERS COLUMN W/0 MOVE NO.
;***********************************************************
; FUNCTION:   --  Like TBPLCL, except that the move number
;                 is not reprinted.
;
; CALLED BY:  --  FCDMAT
;***********************************************************
TBPLMV: PRTBLK  SPACE,3
        LD      a,(KOLOR)
        AND     a
        RET     NZ
        PRTBLK  SPACE,6
        RET

;***********************************************************
; TAB TO COMPUTERS COLUMN W/O MOVE NO.
;***********************************************************
; FUNCTION:   --  Like TBCPCL, except that the move number
;                 is not reprinted.
;
; CALLED BY:  --  CPTRMV
;***********************************************************
TBCPMV: PRTBLK  SPACE,3
        LD      a,(KOLOR)
        AND     a
        RET     Z
        PRTBLK  SPACE,6
        RET

;***********************************************************
; BOARD INDEX TO ASCII SQUARE NAME
;***********************************************************
; FUNCTION:   --  To translate a hexadecimal index in the
;                 board array into an ascii description
;                 of the square in algebraic chess notation.
;
; CALLED BY:  --  CPTRMV
;
; CALLS:      --  DIVIDE
;
; ARGUMENTS:  --  Board index input in register D and the
;                 Ascii square name is output in register
;                 pair HL.
;***********************************************************
BITASN: SUB     a             ; Get ready for division
        LD      e,10
        CALL    DIVIDE          ; Divide
        DEC     d               ; Get rank on 1-8 basis
        ADD     a,60H           ; Convert file to Ascii (a-h)
        LD      l,a             ; Save
        LD      a,d             ; Rank
        ADD     a,30H           ; Convert rank to Ascii (1-8)
        LD      h,a             ; Save
        RET                     ; Return

;***********************************************************
; PLAYERS MOVE ANALYSIS
;***********************************************************
; FUNCTION:   --  To accept and validate the players move
;                 and produce it on the graphics board. Also
;                 allows player to resign the game by
;                 entering a control-R.
;
; CALLED BY:  --  DRIVER
;
; CALLS:      --  CHARTR
;                 ASNTBI
;                 VALMOV
;                 EXECMV
;                 PGIFND
;                 TBPLCL
;
; ARGUMENTS:  --  None
;***********************************************************
PLYRMV: CALL    CHARTR          ; Accept "from" file letter
        CP      12H             ; Is it instead a Control-R ?
        JP      Z,FM09          ; Yes - jump
        LD      h,a             ; Save
        CALL    CHARTR          ; Accept "from" rank number
        LD      l,a             ; Save
        CALL    ASNTBI          ; Convert to a board index
        SUB     b               ; Gives board index, if valid
        JR      Z,PL08          ; Jump if invalid
        LD      (MVEMSG),a      ; Move list "from" position
        CALL    CHARTR          ; Accept separator & ignore it (TODO: Let's not do this, they can type E2E4 surely???)
        CALL    CHARTR          ; Repeat for "to" position
        LD      h,a
        CALL    CHARTR
        LD      l,a
        CALL    ASNTBI
        SUB     b
        JR      Z,PL08
        LD      (MVEMSG+1),a    ; Move list "to" position
        CALL    VALMOV          ; Determines if a legal move
        AND     a               ; Legal ?
        JP      NZ,PL08         ; No - jump
        CALL    EXECMV          ; Make move on graphics board
        RET                     ; Return
PL08:   LD      hl,LINECT       ; Address of screen line count
        INC     (hl)            ; Increase by 2 for message
        INC     (hl)
        CARRET                  ; New line
        CALL    PGIFND          ; New page if needed
        PRTLIN  INVAL1,12       ; Output "INVALID MOVE"
        PRTLIN  INVAL2,9        ; Output "TRY AGAIN"
        CALL    TBPLCL          ; Tab to players column
        JP      PLYRMV          ; Jump

;***********************************************************
; ASCII SQUARE NAME TO BOARD INDEX
;***********************************************************
; FUNCTION:   --  To convert an algebraic square name in
;                 Ascii to a hexadecimal board index.
;                 This routine also checks the input for
;                 validity.
;
; CALLED BY:  --  PLYRMV
;
; CALLS:      --  MLTPLY
;
; ARGUMENTS:  --  Accepts the square name in register pair HL
;                 and outputs the board index in register A.
;                 Register B = 0 if ok. Register B = Register
;                 A if invalid.
;***********************************************************
ASNTBI: 
        LD      a,l             ; Ascii rank (1 - 8)
        SUB     30H           ; Rank 1 - 8
        CP      1             ; Check lower bound
        JP      M,AT04          ; Jump if invalid
        CP      9             ; Check upper bound
        JR      NC,AT04         ; Jump if invalid
        INC     a               ; Rank 2 - 9
        LD      d,a             ; Ready for multiplication
        LD      e,10
        CALL    MLTPLY          ; Multiply
        LD      a,h             ; Ascii file letter (a - h)
        SUB     40H           ; File 1 - 8
        CP      1             ; Check lower bound
        JP      M,AT04          ; Jump if invalid
        CP      9             ; Check upper bound
        JR      NC,AT04         ; Jump if invalid
        ADD     a,d             ; File+Rank(20-90)=Board index
        LD      b,0             ; Ok flag
        RET                     ; Return
AT04:   LD      b,a             ; Invalid flag
        RET                     ; Return

;***********************************************************
; VALIDATE MOVE SUBROUTINE
;***********************************************************
; FUNCTION:   --  To check a players move for validity.
;
; CALLED BY:  --  PLYRMV
;
; CALLS:      --  GENMOV
;                 MOVE
;                 INCHK
;                 UNMOVE
;
; ARGUMENTS:  --  Returns flag in register A, 0 for valid
;                 and 1 for invalid move.
;***********************************************************
VALMOV: LD      hl,(MLPTRJ)     ; Save last move pointer
        PUSH    hl              ; Save register
        LD      a,(KOLOR)       ; Computers color
        XOR     80H           ; Toggle color
        LD      (COLOR),a       ; Store
        LD      hl,PLYIX-2      ; Load move list index
        LD      (MLPTRI),hl
        LD      hl,MLIST+1024   ; Next available list pointer
        LD      (MLNXT),hl
        CALL    GENMOV          ; Generate opponents moves
        LD      ix,MLIST+1024   ; Index to start of moves
VA5:    LD      a,(MVEMSG)      ; "From" position
        CP      (ix+MLFRP)    ; Is it in list ?
        JR      NZ,VA6          ; No - jump
        LD      a,(MVEMSG+1)    ; "To" position
        CP      (ix+MLTOP)    ; Is it in list ?
        JR      Z,VA7           ; Yes - jump
VA6:    LD      e,(ix+MLPTR)    ; Pointer to next list move
        LD      d,(ix+MLPTR+1)
        XOR     a             ; At end of list ?
        CP      d
        JR      Z,VA10          ; Yes - jump
        PUSH    de              ; Move to X register
        POP     ix
        JR      VA5             ; Jump
VA7:    LD      (MLPTRJ),ix     ; Save opponents move pointer
        CALL    MOVE            ; Make move on board array
        CALL    INCHK           ; Was it a legal move ?
        AND     a
        JR      NZ,VA9          ; No - jump
VA8:    POP     hl              ; Restore saved register
        RET                     ; Return
VA9:    CALL    UNMOVE          ; Un-do move on board array
VA10:   LD      a,1             ; Set flag for invalid move
        POP     hl              ; Restore saved register
        LD      (MLPTRJ),hl     ; Save move pointer
        RET                     ; Return

;***********************************************************
; ACCEPT INPUT CHARACTER
;***********************************************************
; FUNCTION:   --  Accepts a single character input from the
;                 console keyboard and places it in the A
;                 register. The character is also echoed on
;                 the video screen, unless it is a carriage
;                 return, line feed, or backspace.
;                 Lower case alphabetic characters are folded
;                 to upper case.
;
; CALLED BY:  --  DRIVER
;                 INTERR
;                 PLYRMV
;                 ANALYS
;
; CALLS:      --  None
;
; ARGUMENTS:  --  Character input is output in register A.
;
; NOTES:      --  This routine contains a reference to a
;                 monitor function of the Jove monitor, there-
;                 for the first few lines of this routine are
;                 system dependent.
;***********************************************************
CHARTR: 
        push    hl
CHARTR1: 
	call	GetTime
        ld      c, BDOS_Console_Direct
        ld      e, 0FFH         ; Use non-echo key read
        call    BDOS            ; Read key from keyboard (if none we will get 0)
        cp      0
        jr      z, CHARTR1 
        CP      0DH             ; Carriage return ?
        jr      Z, CHARTR2      ; Yes - return
        CP      0AH             ; Line feed ?
        jr      Z, CHARTR2      ; Yes - return
        CP      08H             ; Backspace ?
        jr      Z, CHARTR2      ; Yes - return
        push af
        ld      c, BDOS_Console_Output
        ld      e, a
        call    BDOS            ; Print the characer to screen
        pop af
        AND     7FH           ; Mask off parity bit
        CP      7BH           ; Upper range check (z+l)
        jp      P, CHARTR2               ; No need to fold - return
        CP      61H           ; Lower-range check (a)
        jp     M, CHARTR2               ; No need to fold - return
        SUB     20H           ; Change to one of A-Z
CHARTR2:
        pop     hl
        RET                     ; Return

;***********************************************************
; NEW PAGE IF NEEDED
;***********************************************************
; FUNCTION:   --  To clear move list output when the column
;                 has been filled.
;
; CALLED BY:  --  DRIVER
;                 PLYRMV
;                 CPTRMV
;
; CALLS:     --   DSPBRD
;
; ARGUMENTS: --   Returns a 1 in the A register if a new
;                 page was turned.
;***********************************************************
PGIFND: LD      hl,LINECT       ; Addr of page position counter
        INC     (hl)            ; Increment
        LD      a,40            ; Page bottom ?
        CP      (hl)
        RET     NC              ; No - return
        call    CrtClear
        CALL    DSPBRD          ; Put up new page
        PRTLIN  TITLE4,15       ; Re-print titles
        PRTLIN  TITLE3,15
        LD      a,1             ; Set line count back to 1
        LD      (LINECT),a
        RET                     ; Return

;***********************************************************
; DISPLAY MATED KING
;***********************************************************
; FUNCTION:   --  To tip over the computers King when
;                 mated.
;
; CALLED BY:  --  FCDMAT
;
; CALLS:      --  CONVRT
;                 BLNKER
;                 INSPCE  (Abnormal Call to IP04)
;
; ARGUMENTS:  --  None
;***********************************************************
MATED:  
        LD      a,(KOLOR)       ; Computers color
        AND     a               ; Is computer white ?
        JR      Z,rel23         ; Yes - skip
        LD      c,2             ; Set black piece flag
        LD      a,(POSK+1)      ; Position of black King
        JR      MA08            ; Jump
rel23:  LD      c,a             ; Clear black piece flag
        LD      a,(POSK)        ; Position of white King
MA08:   LD      (BRDPOS),a      ; Store King position
        LD      (ANBDPS),a      ; Again

        LD      (M1),a          ; Set up board index
        LD      ix,(M1)
        ld      a,7+128
        LD      (ix+BOARD), a   ; Set mated king

        CALL    CONVRT          ; Getting norm address in HL
        call    blink_square

        RET                     ; Return

;***********************************************************
; SET UP POSITION FOR ANALYSIS
;***********************************************************
; FUNCTION:   --  To enable user to set up any position
;                 for analysis, or to continue to play
;                 the game. The routine blinks the board
;                 squares in turn and the user has the option
;                 of leaving the contents unchanged by a
;                 carriage return, emptying the square by a 0,
;                 or inputting a piece of his chosing. To
;                 enter a piece, type in piece-code,color-code,
;                 moved-code.
;
;                 Piece-code is a letter indicating the
;                 desired piece:
;                       K  -  King
;                       Q  -  Queen
;                       R  -  Rook
;                       B  -  Bishop
;                       N  -  Knight
;                       P  -  Pawn
;
;                 Color code is a letter, W for white, or B for
;                 black.
;
;                 Moved-code is a number. 0 indicates the piece has never
;                 moved. 1 indicates the piece has moved.
;
;                 A backspace will back up in the sequence of blinked
;                 squares. An Escape will terminate the blink cycle and
;                 verify that the position is correct, then procede
;                 with game initialization.
;
; CALLED BY:  --  DRIVER
;
; CALLS:      --  CHARTR
;                 DPSBRD
;                 BLNKER
;                 ROYALT
;                 PLYRMV
;                 CPTRMV
;
; MACRO CALLS:    PRTLIN
;                 EXIT
;                 CrtClear
;                 PRTBLK
;                 CARRET
;
; ARGUMENTS:  --  None
;***********************************************************
ANALYS: PRTLIN  ANAMSG,37       ; "CARE TO ANALYSE A POSITION?"
        CALL    CHARTR          ; Accept answer
        CARRET                  ; New line
        CP      4EH           ; Is answer a "N" ?
        JR      NZ,AN04         ; No - jump
        EXIT                    ; Return to monitor
AN04:   CALL    DSPBRD          ; Current board position
        LD      a,21            ; First board index
AN08:   LD      (ANBDPS),a      ; Save
        LD      (BRDPOS),a
        CALL    CONVRT          ; Norm address into HL register
        LD      (M1),a          ; Set up board index
        LD      ix,(M1)
        LD      a,(ix+BOARD)    ; Get board contents
        CP      0FFH            ; Border square ?
        JR      Z,AN19          ; Yes - jump

        call    blink_square

        CALL    CHARTR          ; Accept input
        CP      1BH             ; Is it an escape ?
        JR      Z,AN1B          ; Yes - jump
        CP      08H             ; Is it a backspace ?
        JR      Z,AN1A          ; Yes - jump
        CP      0DH             ; Is it a carriage return ?
        JR      Z,AN19          ; Yes - jump
        LD      bc,7            ; Number of types of pieces + 1
        LD      hl,PCS          ; Address of piece symbol table
        CPIR                    ; Search
        JR      NZ,AN18         ; Jump if not found
        CALL    CHARTR          ; Accept and ignore separator
        CALL    CHARTR          ; Color of piece
        CP      42H             ; Is it black ?
        JR      NZ,rel022       ; No - skip
        SET     7,c             ; Black piece indicator
rel022: CALL    CHARTR          ; Accept and ignore separator
        CALL    CHARTR          ; Moved flag
        CP      31H             ; Has piece moved ?
        JR      NZ,AN18         ; No - jump
        SET     3,c             ; Set moved indicator
AN18:   LD      (ix+BOARD),c    ; Insert piece into board array
        CALL    DSPBRD          ; Update graphics board
AN19:   LD      a,(ANBDPS)      ; Current board position
        INC     a               ; Next
        CP      99            ; Done ?
        JR      NZ,AN08         ; No - jump
        JR      AN04            ; Jump
AN1A:   LD      a,(ANBDPS)      ; Prepare to go back a square
        SUB     3             ; To get around border
        CP      20            ; Off the other end ?
        JP      NC,AN08         ; No - jump
        LD      a,98            ; Wrap around to top of screen
AN0B:   JP      AN08            ; Jump
AN1B:   PRTLIN  CRTNES,14       ; Ask if correct
        CALL    CHARTR          ; Accept answer
        CP      4EH           ; Is it "N" ?
        JP      Z,AN04          ; No - jump
        CALL    ROYALT          ; Update positions of royalty
        call    CrtClear                  ; Blank screen
        CALL    INTERR          ; Accept color choice
AN1C:   PRTLIN  WSMOVE,17       ; Ask whose move it is
        CALL    CHARTR          ; Accept response
        CALL    DSPBRD          ; Display graphics board
        PRTLIN  TITLE4,15       ; Put up titles
        PRTLIN  TITLE3,15
        CP      57H           ; Is is whites move ?
        JP      Z,DRIV04        ; Yes - jump
        PRTBLK  MVENUM,3        ; Print move number
        PRTBLK  SPACE,6         ; Tab to blacks column
        LD      a,(KOLOR)       ; Computer's color
        AND     a             ; Is computer white ?
        JR      NZ,AN20         ; No - jump
        CALL    PLYRMV          ; Get players move
        CARRET                  ; New line
        JP      DR0C            ; Jump
AN20:   CALL    CPTRMV          ; Get computers move
        CARRET                  ; New line
        JP      DR0C            ; Jump

;***********************************************************
; UPDATE POSITIONS OF ROYALTY
;***********************************************************
; FUNCTION:   --  To update the positions of the Kings
;                 and Queen after a change of board position
;                 in ANALYS.
;
; CALLED BY:  --  ANALYS
;
; CALLS:      --  None
;
; ARGUMENTS:  --  None
;***********************************************************
ROYALT: LD      hl,POSK         ; Start of Royalty array
        LD      b,4             ; Clear all four positions
back06: LD      (hl),0
        INC     hl
        DJNZ    back06
        LD      a,21            ; First board position
RY04:   LD      (M1),a          ; Set up board index
        LD      hl,POSK         ; Address of King position
        LD      ix,(M1)
        LD      a,(ix+BOARD)    ; Fetch board contents
        BIT     7,a             ; Test color bit
        JR      Z,rel023        ; Jump if white
        INC     hl              ; Offset for black
rel023: AND     7             ; Delete flags, leave piece
        CP      KING          ; King ?
        JR      Z,RY08          ; Yes - jump
        CP      QUEEN         ; Queen ?
        JR      NZ,RY0C         ; No - jump
        INC     hl              ; Queen position
        INC     hl              ; Plus offset
RY08:   LD      a,(M1)          ; Index
        LD      (hl),a          ; Save
RY0C:   LD      a,(M1)          ; Current position
        INC     a               ; Next position
        CP      99            ; Done.?
        JR      NZ,RY04         ; No - jump
        RET                     ; Return

; Letters and numbers around the edge of the board
axis_table:
;	   x  y  V
        db 37,13,'8'
        db 37,16,'7'
        db 37,19,'6'
        db 37,22,'5'
        db 37,25,'4'
        db 37,28,'3'
        db 37,31,'2'
        db 37,34,'1'
        db 40,37,'a'
        db 43,37,'b'
        db 46,37,'c'
        db 49,37,'d'
        db 52,37,'e'
        db 55,37,'f'
        db 58,37,'g'
        db 61,37,'h'
;16
	db 38,11,'+'
	db 38,12,'|'
	db 38,13,'|'
	db 38,14,'|'
	db 38,15,'|'
	db 38,16,'|'
	db 38,17,'|'
	db 38,18,'|'
	db 38,19,'|'
	db 38,20,'|'
	db 38,21,'|'
	db 38,22,'|'
	db 38,23,'|'
	db 38,24,'|'
	db 38,25,'|'
	db 38,26,'|'
	db 38,27,'|'
	db 38,28,'|'
	db 38,29,'|'
	db 38,30,'|'
	db 38,31,'|'
	db 38,32,'|'
	db 38,33,'|'
	db 38,34,'|'
	db 38,35,'|'
	db 38,36,'+'
;+2 +3*8
	db 63,11,'+'
	db 63,12,'|'
	db 63,13,'|'
	db 63,14,'|'
	db 63,15,'|'
	db 63,16,'|'
	db 63,17,'|'
	db 63,18,'|'
	db 63,19,'|'
	db 63,20,'|'
	db 63,21,'|'
	db 63,22,'|'
	db 63,23,'|'
	db 63,24,'|'
	db 63,25,'|'
	db 63,26,'|'
	db 63,27,'|'
	db 63,28,'|'
	db 63,29,'|'
	db 63,30,'|'
	db 63,31,'|'
	db 63,32,'|'
	db 63,33,'|'
	db 63,34,'|'
	db 63,35,'|'
	db 63,36,'+'
;+2 +3*8
	db 39,11,'-'
	db 40,11,'-'
	db 41,11,'-'
	db 42,11,'-'
	db 43,11,'-'
	db 44,11,'-'
	db 45,11,'-'
	db 46,11,'-'
	db 47,11,'-'
	db 48,11,'-'
	db 49,11,'-'
	db 50,11,'-'
	db 51,11,'-'
	db 52,11,'-'
	db 53,11,'-'
	db 54,11,'-'
	db 55,11,'-'
	db 56,11,'-'
	db 57,11,'-'
	db 58,11,'-'
	db 59,11,'-'
	db 60,11,'-'
	db 61,11,'-'
	db 62,11,'-'
;+3*8
	db 39,36,'-'
	db 40,36,'-'
	db 41,36,'-'
	db 42,36,'-'
	db 43,36,'-'
	db 44,36,'-'
	db 45,36,'-'
	db 46,36,'-'
	db 47,36,'-'
	db 48,36,'-'
	db 49,36,'-'
	db 50,36,'-'
	db 51,36,'-'
	db 52,36,'-'
	db 53,36,'-'
	db 54,36,'-'
	db 55,36,'-'
	db 56,36,'-'
	db 57,36,'-'
	db 58,36,'-'
	db 59,36,'-'
	db 60,36,'-'
	db 61,36,'-'
	db 62,36,'-'
;+3*8 total 116
;
;	Print a character to the screen at (Cursor)
;	(cursor is not moved)
;	A = char
;	BC not affected
;
PrintChar:
	push	bc
	ld	bc,(Cursor)
	out	(c),a
	pop	bc
	ret
;
; This is the board drawing routine.
DSPBRD:
        PUSH    bc              ; Save registers
        PUSH    de
        PUSH    hl
        PUSH    af

        ld      hl, axis_table
        ld      b, 116
axis_loop:
        ld      e, (hl)		;col
        inc     hl
        ld      c, (hl)		;row
	push	bc
        call    CrtLocate
	pop	bc
        inc     hl
        ld      a, (hl)
        inc     hl
	call	PrintChar
        djnz    axis_loop

        LD      a,21            ; First board index
        ld      c, 8            ; Counter for 8 ranks
DSPBRD1: 
        ld      b, 8            ; Counter for 8 files in each rank
DSPBRD2:
        push    bc
        LD      (BRDPOS),a      ; Ready parameter
        CALL    CONVRT          ; X-Y coords of square into HL register H=col L=row
        CALL    display_piece
        LD      a, (BRDPOS)
        INC     a               ; Next square
        pop     bc
        djnz    DSPBRD2         ; Continue for all of this rank
        inc     a               ; Skip edges
        inc     a
        dec     c
        jr      nz, DSPBRD1

        POP     af              ; Restore registers
        POP     hl
        POP     de
        POP     bc
        ret

; This draws a square of the board, but empty with a black or white background.
; If is used in routines that "flash" one of the squares of the board.
;	H=col,L=row
;
BW:	defb	0

display_black_square:
	ld	a,(BW)
	inc	a
	ld	(BW),a
	and	1
	ld	de,WW_EMPTY
	jr	z,1f
	ld	de,BB_EMPTY
1:
	jp	show

; On entry to display_piece, the board location that
; we want to display must be in BRDPOS.
; Also, the x-y coords of the board location must be in hl.
; And the cursor must be positioned where we want to draw the piece.
; This routine draws the entire square and its content, so for an
; empty square it draws an empty square of the required colour.
; For a square with a piece in it draws the background of the square
; and the piece as well.
; If you request a red background it draws an empty square with a
; red background.
display_piece:
        PUSH    hl              ; Save registers
        PUSH    bc
        PUSH    de
        PUSH    ix
        PUSH    af
        call    store_background_colour
        ld      a, 0		; init foreground as white piece
        ld      (FOREGROUND_COLOUR), a
        LD      a,(BRDPOS)      ; Get board index
        LD      (M1),a          ; Save
        LD      ix,(M1)         ; Index into board array
        LD      a,(ix+BOARD)    ; Contents of board array
        AND     a               ; Is square empty ?
        JP      Z,display_space          ; Yes - jump
        CP      0FFH            ; Is it a border square ?
        JP      Z,display_space          ; Yes - jump
;???    LD      c,0             ; Clear flag register
        BIT     7,a             ; Is piece white ?
        JR      Z,wpiece        ; Yes - jump
        push    af
        LD      a, 1		; black piece
        ld      (FOREGROUND_COLOUR), a
        pop     af
wpiece:
        AND     7               ; Delete flags, leave piece (1 = pawn, 2 = Knight etc)
; By now we have the char in A, and the foreground and background colour is known
2:
        call show_this_piece
        pop af
        pop ix
        pop de
        pop bc
        pop hl
        ret
display_space:
	xor	a
	jr	2b
;
;	Set cursor at H (col), L (row)
;	DE,HL not affected
;
LocateHL:
	push	de
	ld	c,l		;row
	ld	e,h		;col
	call	CrtLocate
	pop	de
	ret
;
display_board_space:

	ld	a,(BACKGROUND_COLOUR)
	or	a		;if 1 (black)
	ld	a,BLANK		;choose blank
	jr	nz,1f
	ld	a,REV_BLANK	;else choose reverse blank (white)
1:
	ld	d,a		;save choice
				;fix cursor (left/down)
;bottom line x 3

	call	LocateHL
	ld	a,d
	call	PrintChar

	inc	h		;incr col
	call	LocateHL
	ld	a,d
	call	PrintChar

	inc	h		;incr col
	call	LocateHL
	ld	a,d
	call	PrintChar

;middle line x 3
	
	dec	h		;restore col
	dec	h

	dec	l		;decr row

	call	LocateHL
	ld	a,d
	call	PrintChar

	inc	h		;incr col
	call	LocateHL
	ld	a,d
	call	PrintChar

	inc	h		;incr col
	call	LocateHL
	ld	a,d
	call	PrintChar

;top line x 3
	
	dec	h		;restore col
	dec	h

	dec	l		;decr row

	call	LocateHL
	ld	a,d
	call	PrintChar

	inc	h		;incr col
	call	LocateHL
	ld	a,d
	call	PrintChar

	inc	h		;incr col
	call	LocateHL
	ld	a,d
	call	PrintChar
	
	ret

show_this_piece:
        cp  1
        jp z, show_pawn
        cp  2
        jp z, show_knight
        cp  3
        jp z, show_bishop
        cp  4
        jp z, show_rook
        cp  5
        jp z, show_queen
        cp  6
        jp z, show_king
        cp  7
        jp z, show_mated_king
	jp	display_board_space
;
;	DE=pointer of the 9 chars, starting from down/left
;	H=col,L=row
show:
;bottom line x 3
	call	LocateHL
	ld	a,(de)
	call	PrintChar
	inc	de
	inc	h		;incr col
	call	LocateHL
	ld	a,(de)
	call	PrintChar
	inc	de
	inc	h		;incr col
	call	LocateHL
	ld	a,(de)
	call	PrintChar
	inc	de
;middle line x 3
	dec	h		;restore col
	dec	h
	dec	l		;decr row
	call	LocateHL
	ld	a,(de)
	call	PrintChar
	inc	de
	inc	h		;incr col
	call	LocateHL
	ld	a,(de)
	call	PrintChar
	inc	de
	inc	h		;incr col
	call	LocateHL
	ld	a,(de)
	call	PrintChar
	inc	de
;top line x 3
	dec	h		;restore col
	dec	h
	dec	l		;decr row
	call	LocateHL
	ld	a,(de)
	call	PrintChar
	inc	de
	inc	h		;incr col
	call	LocateHL
	ld	a,(de)
	call	PrintChar
	inc	de
	inc	h		;incr col
	call	LocateHL
	ld	a,(de)
	call	PrintChar
	ret
;
;	compute Fore/Back/Ground combinations
;
;	returns:00B = white/white
;		10B = black/white
;		01B = white/black
;		11B = black/black
;
FBG:	ld	a,(FOREGROUND_COLOUR)
	add	a		;foreground * 2
	ld	b,a
	ld	a,(BACKGROUND_COLOUR)
	or	b		;and background
	ret
;
show_pawn:
	call	FBG
	or	a
	jr	z,1f		;WW
	dec	a
	jr	z,2f		;WB
	dec	a
	jr	z,3f		;BW
	ld	de,BB_PAWN	;else BB
	jp	show
1:	ld	de,WW_PAWN
	jp	show
2:	ld	de,WB_PAWN
	jp	show
3:	ld	de,BW_PAWN
	jp	show

show_knight:
	call	FBG
	or	a
	jr	z,1f		;WW
	dec	a
	jr	z,2f		;WB
	dec	a
	jr	z,3f		;BW
	ld	de,BB_KNIGHT	;else BB
	jp	show
1:	ld	de,WW_KNIGHT
	jp	show
2:	ld	de,WB_KNIGHT
	jp	show
3:	ld	de,BW_KNIGHT
	jp	show

show_bishop:
	call	FBG
	or	a
	jr	z,1f		;WW
	dec	a
	jr	z,2f		;WB
	dec	a
	jr	z,3f		;BW
	ld	de,BB_BISHOP	;else BB
	jp	show
1:	ld	de,WW_BISHOP
	jp	show
2:	ld	de,WB_BISHOP
	jp	show
3:	ld	de,BW_BISHOP
	jp	show

show_rook:
	call	FBG
	or	a
	jr	z,1f		;WW
	dec	a
	jr	z,2f		;WB
	dec	a
	jr	z,3f		;BW
	ld	de,BB_ROCK	;else BB
	jp	show
1:	ld	de,WW_ROCK
	jp	show
2:	ld	de,WB_ROCK
	jp	show
3:	ld	de,BW_ROCK
	jp	show

show_queen:
	call	FBG
	or	a
	jr	z,1f		;WW
	dec	a
	jr	z,2f		;WB
	dec	a
	jr	z,3f		;BW
	ld	de,BB_QUEEN	;else BB
	jp	show
1:	ld	de,WW_QUEEN
	jp	show
2:	ld	de,WB_QUEEN
	jp	show
3:	ld	de,BW_QUEEN
	jp	show

show_king:
	call	FBG
	or	a
	jr	z,1f		;WW
	dec	a
	jr	z,2f		;WB
	dec	a
	jr	z,3f		;BW
	ld	de,BB_KING	;else BB
	jp	show
1:	ld	de,WW_KING
	jp	show
2:	ld	de,WB_KING
	jp	show
3:	ld	de,BW_KING
	jp	show

show_mated_king:
	call	FBG
	or	a
	jr	z,1f		;WW
	dec	a
	jr	z,2f		;WB
	dec	a
	jr	z,3f		;BW
	ld	de,BB_MKING	;else BB
	jp	show
1:	ld	de,WW_MKING
	jp	show
2:	ld	de,WB_MKING
	jp	show
3:	ld	de,BW_MKING
	jp	show

store_background_colour:
        ld      a, h
        xor     l
        and     1
        ld      (BACKGROUND_COLOUR), a
        ret

BACKGROUND_COLOUR:
        db      0
FOREGROUND_COLOUR:
        db      0

;***********************************************************
; BOARD INDEX TO NORM ADDRESS SUBR.
;***********************************************************
; FUNCTION:   --  Converts a hexadecimal board index into
;                 a Norm address for the square.
;
; CALLED BY:  --  DSPBRD
;                 INSPCE
;                 ANALYS
;                 MATED
;
; CALLS:      --  DIVIDE
;                 MLTPLY
;
; ARGUMENTS:   -- Returns the Norm address in register pair
;                 H=col L=row
;***********************************************************
CONVRT: PUSH    bc              ; Save registers
        PUSH    de
        PUSH    af
        LD      a,(BRDPOS)      ; Get board index
        LD      d,a             ; Set up dividend
        SUB     a
        LD      e,10            ; Divisor
        CALL    DIVIDE          ; Index into D = rank(row) and A = file(col)
                                ; file (1-8) & rank (2-9)
        DEC     d               ; For rank (1-8)
        DEC     d               ; For rank (0-7)
        DEC     a               ; For file (0-7)
                                ; Now multiply rank by 3 and file by 3
        
        LD      c,d             ; Save C=rank for now
        LD      d,3             ; Multiplier for file
        LD      e,a             ; File number is multiplicand
        CALL    MLTPLY          ; Giving file displacement
        LD      a,d             ; Save
        ADD     a, 39           ; Move file across to suitable place on screen
        LD      h,a             ; Low order address byte

        LD      d,3             ; Rank multiplier
        ld      e, c            ; Rank
        call    MLTPLY
        ld      a, 35
        sub     d
        ld      l, a

        POP     af              ; Restore registers
        POP     de
        POP     bc
        RET                     ; Return

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

;***********************************************************
; POSITIVE INTEGER MULTIPLICATION
;   inputs D, E
;   output hi=A lo=D
;***********************************************************
MLTPLY: PUSH    bc
        SUB     a
        LD      b,8
ML04:   BIT     0,d
        JR      Z,rel025
        ADD     a,e
rel025: SRA     a
        RR      d
        DJNZ    ML04
        POP     bc
        RET

;***********************************************************
; EXECUTE MOVE SUBROUTINE
;***********************************************************
; FUNCTION:   --  This routine is the control routine for
;                 MAKEMV. It checks for double moves and
;                 sees that they are properly handled. It
;                 sets flags in the B register for double
;                 moves:
;                       En Passant -- Bit 0
;                       O-O        -- Bit 1
;                       O-O-O      -- Bit 2
;
; CALLED BY:   -- PLYRMV
;                 CPTRMV
;
; CALLS:       -- MAKEMV
;
; ARGUMENTS:   -- Flags set in the B register as described
;                 above.
;***********************************************************
EXECMV: PUSH    ix              ; Save registers
        PUSH    af
        LD      ix,(MLPTRJ)     ; Index into move list
        LD      c,(ix+MLFRP)    ; Move list "from" position
        LD      e,(ix+MLTOP)    ; Move list "to" position

        CALL    MAKEMV          ; Produce move

        LD      d,(ix+MLFLG)    ; Move list flags
        LD      b,0
        BIT     6,d             ; Double move ?
        JR      Z,EX14          ; No - jump
        LD      de,6            ; Move list entry width
        ADD     ix,de           ; Increment MLPTRJ
        LD      c,(ix+MLFRP)    ; Second "from" position
        LD      e,(ix+MLTOP)    ; Second "to" position
        LD      a,e             ; Get "to" position
        CP      c               ; Same as "from" position ?
        JR      NZ,EX04         ; No - jump
        INC     b               ; Set en passant flag
        JR      EX10            ; Jump
EX04:   CP      1AH             ; White O-O ?
        JR      NZ,EX08         ; No - jump
        SET     1,b             ; Set O-O flag
        JR      EX10            ; Jump
EX08:   CP      60H             ; Black 0-0 ?
        JR      NZ,EX0C         ; No - jump
        SET     1,b             ; Set 0-0 flag
        JR      EX10            ; Jump
EX0C:   SET     2,b             ; Set 0-0-0 flag
EX10:   
        CALL    MAKEMV          ; Make 2nd move on board

EX14:   POP     af              ; Restore registers
        POP     ix
        RET                     ; Return

;***********************************************************
; MAKE MOVE SUBROUTINE
;***********************************************************
; FUNCTION:   --  Moves the piece on the board when a move
;                 is made. It blinks both the "from" and
;                 "to" positions to give notice of the move.
;
; CALLED BY:  --  EXECMV
;
; CALLS:      --  CONVRT
;                 BLNKER
;                 INSPCE
;
; ARGUMENTS:  --  The "from" position is passed in register
;                 C, and the "to" position in register E.
;***********************************************************
MAKEMV: PUSH    af              ; Save register
        PUSH    bc
        PUSH    de
        PUSH    hl

        push    de
        LD      a,c             ; "From" position
        LD      (BRDPOS),a      ; Set up parameter
        CALL    CONVRT          ; Getting Norm address in HL
        call    blink_square
        pop     de

        LD      a,e             ; Get "to" position
        LD      (BRDPOS),a      ; Set up parameter
        CALL    CONVRT          ; Getting Norm address in HL
        call    blink_square

        POP     hl              ; Restore registers
        POP     de
        POP     bc
        POP     af
        RET                     ; Return

blink_square:
        ld      b, 5
blink_square1:
        push    bc
        push    hl
        CALL    LocateHL
        CALL    display_black_square
        call    delay
        pop     hl
        push    hl
        CALL    LocateHL
        CALL    display_piece
        call    delay
        pop     hl
        pop     bc
        djnz    blink_square1
        ret

delay:
        ld      bc, 200
more_delay:
        dec     bc
        push bc
        ld b, 255
even_more_delay:
        djnz    even_more_delay
        pop     bc
        ld      a, b
        or      c
        jr      nz, more_delay
        ret

BDOS equ 5
BDOS_Print_String equ 9         ; 09
BDOS_Console_Input equ 1
BDOS_Console_Output equ 2
BDOS_Console_Direct equ 6
ESC equ 27

Clear:	db	ESC,'H',ESC,'J','$'

CrtClear:
	ld	de,Clear
show_string_de:
        ld c, BDOS_Print_String
        call BDOS
        ret

print_a:
        push    af
        push    bc
        push    de
        push    hl
        ld      c, BDOS_Console_Output
        ld      e, a
        call    BDOS
        pop     hl
        pop     de
        pop     bc
        pop     af
        ret
;
copyright_message:
    db 13,10
    db 13,10
    db ' :::::::      ::     :::::::::   :::::::   :::::::  ::::    :::',13,10
    db ':+:   :+:   :+::+:   :+:    :+: :+:   :+: :+:   :+: :+:+:   :+:',13,10
    db '+:+        +:+  +:+  +:+    +:+ +:+       +:+   +:+ :+:+:+  +:+',13,10
    db '+#++++#++ +#++++#++: +#++:++#:  :#:       +#+   +:+ +#+ +:+ +#+',13,10
    db '      +#+ +#+    +#+ +#+    +#+ +#+  +#+# +#+   +#+ +#+  +#+#+#',13,10
    db '#+#   #+# #+#    #+# #+#    #+# #+#   #+# #+#   #+# #+#   #+#+#',13,10
    db ' #######  ###    ### ###    ###  #######   #######  ###    ####',13,10
    db 13,10
    db 'Sargon is a computer chess playing program designed and coded',13,10
    db 'by Dan and Kathe Spracklen. Copyright 1978. All rights reserved.',13,10 
    db 'No part of this publication may be reproduced',13,10
    db '     without prior written permission.',13,10,13,10
    db 'This version was ported to CP/M by John Squires in May 2021',13,10
    db 'for the Z80 Playground. It is based on the listing found at',13,10
    db 'github.com/billforsternz/retro-sargon.',13,10
    db 13,10
    db 'Adapted to Z80ALL by Ladislau Szilagyi in June 2023',13,10,13,10
    db '$'
;
;********************************************************************
;	Time lapse computing
;
StartTime:	defs	3	;H,M,S
StopTime:	defs	3	;H,M,S
DeltaTime:	defs	3	;H,M,S
;
StartSecs:	defs	2
StopSecs:	defs	2
DeltaSecs:	defs	2
;
TimeLapse:	defs	8	;00:00:00 using ASCII decimal digits
		defb	'$'

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
GetStartTime:
	call	GetTime		;E = seconds
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
GetStopTime:
	call	GetTime		;E = seconds
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
PrintLapseTime:
	call	ComputeLapse
	ld	de,TimeLapse
	jp	show_string_de
;
;********************************************************************
;
;	Font support routines
;
BLANK		equ	' '
REV_BLANK	equ	' ' XOR 80H
;
;	Custom chars bitmaps
;
;	789
;	456
;	123
;
;	White piece on Black Square
;
;	BASE
;
WB_BASE_1	equ	1
CUSTOM_1:
	defb	00000011B
	defb	00000111B
	defb	00001111B
	defb	00011111B
	defb	00111111B
	defb	00111111B
	defb	00000000B
	defb	00000000B

WB_BASE_2	equ	2
CUSTOM_2:
	defb	11111111B
	defb	11111111B
	defb	11111111B
	defb	11111111B
	defb	11111111B
	defb	11111111B
	defb	00000000B
	defb	00000000B

WB_BASE_3	equ	3
CUSTOM_3:
	defb	11000000B
	defb	11100000B
	defb	11110000B
	defb	11111000B
	defb	11111100B
	defb	11111100B
	defb	00000000B
	defb	00000000B
;
;	PAWN
;
WB_PAWN_4 	equ	BLANK

WB_PAWN_5	equ	4
CUSTOM_4:
	defb	01111110B
	defb	00111100B
	defb	01111110B
	defb	01111110B
	defb	11111111B
	defb	11111111B
	defb	11111111B
	defb	11111111B

WB_PAWN_6 	equ 	BLANK

WB_PAWN_7	equ	BLANK

WB_PAWN_8	equ	5
CUSTOM_5:
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00011000B
	defb	00111100B

WB_PAWN_9	equ	BLANK
;
;	KNIGHT
;
WB_KNIGHT_4	equ	6
CUSTOM_6:
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000001B
	defb	00000001B

WB_KNIGHT_5	equ	7
CUSTOM_7:
	defb	00011111B
	defb	00011111B
	defb	00111110B
	defb	01111110B
	defb	11111111B
	defb	11111111B
	defb	11111111B
	defb	11111111B

WB_KNIGHT_6	equ	8
CUSTOM_8:
	defb	10000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	10000000B
	defb	10000000B

WB_KNIGHT_7	equ	9
CUSTOM_9:
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000001B
	defb	00000011B
	defb	00000011B

WB_KNIGHT_8	equ	10
CUSTOM_10:
	defb	00000000B
	defb	00000000B
	defb	00110000B
	defb	01111100B
	defb	11111111B
	defb	11111111B
	defb	11111111B
	defb	10001111B

WB_KNIGHT_9	equ	11
CUSTOM_11:
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	10000000B
	defb	10000000B
	defb	10000000B
;
;	BISHOP
;
WB_BISHOP_4	equ	BLANK
	
WB_BISHOP_5	equ	12
CUSTOM_12:
	defb	00111100B
	defb	00111100B
	defb	01111110B
	defb	01111110B
	defb	11111111B
	defb	11111111B
	defb	11111111B
	defb	11111111B

WB_BISHOP_6	equ	BLANK

WB_BISHOP_7 equ	BLANK

WB_BISHOP_8	equ	13
CUSTOM_13:
	defb	00000000B
	defb	00000000B
	defb	00111100B
	defb	11111111B
	defb	11111111B
	defb	11111111B
	defb	01111110B
	defb	00111100B

WB_BISHOP_9	equ	BLANK
;
;	QUEEN
;
WB_QUEEN_4	equ	14
CUSTOM_14:
	defb	00000011B
	defb	00000111B
	defb	00001111B
	defb	00001111B
	defb	00000111B
	defb	00000011B
	defb	00000001B
	defb	00000001B

WB_QUEEN_5	equ	REV_BLANK

WB_QUEEN_6	equ	15
CUSTOM_15:
	defb	11000000B
	defb	11100000B
	defb	11110000B
	defb	11110000B
	defb	11100000B
	defb	11000000B
	defb	10000000B
	defb	10000000B

WB_QUEEN_7	equ	16
CUSTOM_16:
	defb	00000000B
	defb	00000000B
	defb	00100000B
	defb	00110000B
	defb	00011001B
	defb	00001111B
	defb	00000111B
	defb	00000011B

WB_QUEEN_8	equ	17
CUSTOM_17:
	defb	00000000B
	defb	00000000B
	defb	10000001B
	defb	11000011B
	defb	11100111B
	defb	11111111B
	defb	11111111B
	defb	11111111B

WB_QUEEN_9	equ	18
CUSTOM_18:
	defb	00000000B
	defb	00000000B
	defb	00000100B
	defb	00001100B
	defb	10011000B
	defb	11110000B
	defb	11100000B
	defb	11000000B
;
;	ROCK
;
WB_ROCK_4	equ	19
CUSTOM_19:
	defb	00111111B
	defb	00111111B
	defb	00111111B
	defb	00111111B
	defb	00111111B
	defb	00111111B
	defb	00111111B
	defb	00001111B

WB_ROCK_5	equ	REV_BLANK

WB_ROCK_6	equ	20
CUSTOM_20:
	defb	11111100B
	defb	11111100B
	defb	11111100B
	defb	11111100B
	defb	11111100B
	defb	11111100B
	defb	11111100B
	defb	11110000B

WB_ROCK_7	equ	21
CUSTOM_21:
	defb	00000000B
	defb	00000000B
	defb	00110001B	
	defb	00110001B	
	defb	00111111B
	defb	00111111B
	defb	00111111B
	defb	00111111B

WB_ROCK_8	equ	22
CUSTOM_22:
	defb	00000000B
	defb	00000000B
	defb	10001100B
	defb	10001100B
	defb	11111111B
	defb	11111111B
	defb	11111111B
	defb	11111111B

WB_ROCK_9	equ	23
CUSTOM_23:
	defb	00000000B
	defb	00000000B
	defb	00001100B
	defb	00001100B
	defb	11111100B
	defb	11111100B
	defb	11111100B
	defb	11111100B
;
;	KING
;
WB_KING_4	equ	24
CUSTOM_24:
	defb	00000011B
	defb	00000111B
	defb	00001111B
	defb	00001111B
	defb	00001111B
	defb	00000111B
	defb	00000011B
	defb	00000001B

WB_KING_5	equ	REV_BLANK

WB_KING_6	equ	25
CUSTOM_25:
	defb	11000000B
	defb	11100000B
	defb	11110000B
	defb	11110000B
	defb	11110000B
	defb	11100000B
	defb	11000000B
	defb	10000000B

WB_KING_7	equ	BLANK

WB_KING_8	equ	26
CUSTOM_26:
	defb	00000000B
	defb	00000000B
	defb	00011000B
	defb	00011000B
	defb	01111110B
	defb	01111110B
	defb	00011000B
	defb	11111111B

WB_KING_9	equ	BLANK
;
;	Black piece on White Square
;
;	BASE
;
BW_BASE_1	equ	WB_BASE_1 XOR 80H
BW_BASE_2	equ	WB_BASE_2 XOR 80H
BW_BASE_3	equ	WB_BASE_3 XOR 80H
;
;	PAWN
;
BW_PAWN_4 	equ	WB_PAWN_4 XOR 80H
BW_PAWN_5	equ	WB_PAWN_5 XOR 80H
BW_PAWN_6 	equ 	WB_PAWN_6 XOR 80H
BW_PAWN_7	equ	WB_PAWN_7 XOR 80H
BW_PAWN_8	equ	WB_PAWN_8 XOR 80H
BW_PAWN_9	equ	WB_PAWN_9 XOR 80H
;
;	KNIGHT
;
BW_KNIGHT_4	equ	WB_KNIGHT_4 XOR 80H
BW_KNIGHT_5	equ	WB_KNIGHT_5 XOR 80H
BW_KNIGHT_6	equ	WB_KNIGHT_6 XOR 80H
BW_KNIGHT_7	equ	WB_KNIGHT_7 XOR 80H
BW_KNIGHT_8	equ	WB_KNIGHT_8 XOR 80H
BW_KNIGHT_9	equ	WB_KNIGHT_9 XOR 80H
;
;	BISHOP
;
BW_BISHOP_4 	equ	WB_BISHOP_4 XOR 80H
BW_BISHOP_5	equ	WB_BISHOP_5 XOR 80H
BW_BISHOP_6	equ	WB_BISHOP_6 XOR 80H
BW_BISHOP_7 	equ	WB_BISHOP_7 XOR 80H
BW_BISHOP_8	equ	WB_BISHOP_8 XOR 80H
BW_BISHOP_9	equ	WB_BISHOP_9 XOR 80H
;
;	QUEEN
;
BW_QUEEN_4	equ	WB_QUEEN_4 XOR 80H
BW_QUEEN_5	equ	WB_QUEEN_5 XOR 80H
BW_QUEEN_6	equ	WB_QUEEN_6 XOR 80H
BW_QUEEN_7	equ	WB_QUEEN_7 XOR 80H
BW_QUEEN_8	equ	WB_QUEEN_8 XOR 80H
BW_QUEEN_9	equ	WB_QUEEN_9 XOR 80H
;
;	ROCK
;
BW_ROCK_4	equ	WB_ROCK_4 XOR 80H
BW_ROCK_5	equ	WB_ROCK_5 XOR 80H
BW_ROCK_6	equ	WB_ROCK_6 XOR 80H
BW_ROCK_7	equ	WB_ROCK_7 XOR 80H
BW_ROCK_8	equ	WB_ROCK_8 XOR 80H
BW_ROCK_9	equ	WB_ROCK_9 XOR 80H
;
;	KING
;
BW_KING_4	equ	WB_KING_4 XOR 80H
BW_KING_5	equ	WB_KING_5 XOR 80H
BW_KING_6	equ	WB_KING_6 XOR 80H
BW_KING_7	equ	WB_KING_7 XOR 80H
BW_KING_8	equ	WB_KING_8 XOR 80H
BW_KING_9	equ	WB_KING_9 XOR 80H
;
;	Black piece on Black Square
;
;	BASE
;
BB_BASE_1	equ	64
CUSTOM_64:
	defb	00000011B
	defb	00000100B
	defb	00001000B
	defb	00010000B
	defb	00100000B
	defb	00111111B
	defb	00000000B
	defb	00000000B

BB_BASE_2	equ	65
CUSTOM_65:
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	11111111B
	defb	00000000B
	defb	00000000B

BB_BASE_3	equ	66
CUSTOM_66:
	defb	11000000B
	defb	00100000B
	defb	00010000B
	defb	00001000B
	defb	00000100B
	defb	11111100B
	defb	00000000B
	defb	00000000B
;
;	PAWN
;
BB_PAWN_4 	equ	BLANK

BB_PAWN_5	equ	67
CUSTOM_67:
	defb	01000010B
	defb	00100100B
	defb	01000010B
	defb	01000010B
	defb	10000001B
	defb	10000001B
	defb	10000001B
	defb	10000001B

BB_PAWN_6 	equ 	BLANK

BB_PAWN_7	equ	BLANK

BB_PAWN_8	equ	68
CUSTOM_68:
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00011000B
	defb	00100100B

BB_PAWN_9	equ	BLANK
;
;	KNIGHT
;
BB_KNIGHT_4	equ	69
CUSTOM_69:
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000001B
	defb	00000001B

BB_KNIGHT_5	equ	70
CUSTOM_70:
	defb	00010000B
	defb	00010001B
	defb	00100010B
	defb	01000010B
	defb	10000001B
	defb	10000001B
	defb	00000000B
	defb	00000000B

BB_KNIGHT_6	equ	71
CUSTOM_71:
	defb	10000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	10000000B
	defb	10000000B

BB_KNIGHT_7	equ	72
CUSTOM_72:
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000001B
	defb	00000010B
	defb	00000010B

BB_KNIGHT_8	equ	73
CUSTOM_73:
	defb	00000000B
	defb	00000000B
	defb	00110000B
	defb	01001100B
	defb	10000011B
	defb	00000000B
	defb	01110000B
	defb	10001000B

BB_KNIGHT_9	equ	74
CUSTOM_74:
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	00000000B
	defb	10000000B
	defb	10000000B
	defb	10000000B
;
;	BISHOP
;
BB_BISHOP_4	equ	BLANK
	
BB_BISHOP_5	equ	75
CUSTOM_75:
	defb	00100100B
	defb	00100100B
	defb	01000010B
	defb	01000010B
	defb	10000001B
	defb	10000001B
	defb	10000001B
	defb	10000001B

BB_BISHOP_6	equ	BLANK

BB_BISHOP_7 equ	BLANK

BB_BISHOP_8	equ	76
CUSTOM_76:
	defb	00000000B
	defb	00000000B
	defb	00111100B
	defb	10000001B
	defb	10000001B
	defb	10000001B
	defb	01000010B
	defb	00100100B

BB_BISHOP_9	equ	BLANK
;
;	QUEEN
;
BB_QUEEN_4	equ	77
CUSTOM_77:
	defb	00000010B
	defb	00000100B
	defb	00001000B
	defb	00001000B
	defb	00000100B
	defb	00000010B
	defb	00000001B
	defb	00000001B

BB_QUEEN_5	equ	BLANK

BB_QUEEN_6	equ	78
CUSTOM_78:
	defb	01000000B
	defb	00100000B
	defb	00010000B
	defb	00010000B
	defb	00100000B
	defb	01000000B
	defb	10000000B
	defb	10000000B

BB_QUEEN_7	equ	79
CUSTOM_79:
	defb	00000000B
	defb	00000000B
	defb	00100000B
	defb	00011000B
	defb	00001101B
	defb	00000110B
	defb	00000100B
	defb	00000010B

BB_QUEEN_8	equ	80
CUSTOM_80:
	defb	00000000B
	defb	00000000B
	defb	10000001B
	defb	11000011B
	defb	00100100B
	defb	00011000B
	defb	00000000B
	defb	00000000B

BB_QUEEN_9	equ	81
CUSTOM_81:
	defb	00000000B
	defb	00000000B
	defb	00000100B
	defb	00001100B
	defb	10011000B
	defb	01100000B
	defb	00100000B
	defb	01000000B
;
;	ROCK
;
BB_ROCK_4	equ	82
CUSTOM_82:
	defb	00100000B
	defb	00100000B
	defb	00100000B
	defb	00100000B
	defb	00100000B
	defb	00100000B
	defb	00100000B
	defb	00011000B

BB_ROCK_5	equ	BLANK

BB_ROCK_6	equ	83
CUSTOM_83:
	defb	00000100B
	defb	00000100B
	defb	00000100B
	defb	00000100B
	defb	00000100B
	defb	00000100B
	defb	00000100B
	defb	00011000B

BB_ROCK_7	equ	84
CUSTOM_84:
	defb	00000000B
	defb	00000000B
	defb	00110000B	
	defb	00110000B	
	defb	00101111B
	defb	00100000B
	defb	00100000B
	defb	00100000B

BB_ROCK_8	equ	85
CUSTOM_85:
	defb	00000000B
	defb	00000000B
	defb	11000110B
	defb	11000110B
	defb	00111111B
	defb	00000000B
	defb	00000000B
	defb	00000000B

BB_ROCK_9	equ	86
CUSTOM_86:
	defb	00000000B
	defb	00000000B
	defb	00001100B
	defb	00001100B
	defb	11110100B
	defb	00000100B
	defb	00000100B
	defb	00000100B
;
;	KING
;
BB_KING_4	equ	87
CUSTOM_87:
	defb	00000011B
	defb	00000100B
	defb	00001000B
	defb	00001000B
	defb	00001000B
	defb	00000100B
	defb	00000010B
	defb	00000001B

BB_KING_5	equ	BLANK

BB_KING_6	equ	88
CUSTOM_88:
	defb	11000000B
	defb	00100000B
	defb	00010000B
	defb	00010000B
	defb	00010000B
	defb	00100000B
	defb	01000000B
	defb	10000000B

BB_KING_7	equ	BLANK

BB_KING_8	equ	89
CUSTOM_89:
	defb	00000000B
	defb	00000000B
	defb	00011000B
	defb	00011000B
	defb	01111110B
	defb	01111110B
	defb	00011000B
	defb	11100111B

BB_KING_9	equ	BLANK
;
;	White piece on White Square
;
;	BASE
;
WW_BASE_1	equ	BB_BASE_1 XOR 80H
WW_BASE_2	equ	BB_BASE_2 XOR 80H
WW_BASE_3	equ	BB_BASE_3 XOR 80H
;
;	PAWN
;
WW_PAWN_4 	equ	BB_PAWN_4 XOR 80H
WW_PAWN_5	equ	BB_PAWN_5 XOR 80H
WW_PAWN_6 	equ 	BB_PAWN_6 XOR 80H
WW_PAWN_7	equ	BB_PAWN_7 XOR 80H
WW_PAWN_8	equ	BB_PAWN_8 XOR 80H
WW_PAWN_9	equ	BB_PAWN_9 XOR 80H
;
;	KNIGHT
;
WW_KNIGHT_4	equ	BB_KNIGHT_4 XOR 80H
WW_KNIGHT_5	equ	BB_KNIGHT_5 XOR 80H
WW_KNIGHT_6	equ	BB_KNIGHT_6 XOR 80H
WW_KNIGHT_7	equ	BB_KNIGHT_7 XOR 80H
WW_KNIGHT_8	equ	BB_KNIGHT_8 XOR 80H
WW_KNIGHT_9	equ	BB_KNIGHT_9 XOR 80H
;
;	BISHOP
;
WW_BISHOP_4 	equ	BB_BISHOP_4 XOR 80H
WW_BISHOP_5	equ	BB_BISHOP_5 XOR 80H
WW_BISHOP_6	equ	BB_BISHOP_6 XOR 80H
WW_BISHOP_7 	equ	BB_BISHOP_7 XOR 80H
WW_BISHOP_8	equ	BB_BISHOP_8 XOR 80H
WW_BISHOP_9	equ	BB_BISHOP_9 XOR 80H
;
;	QUEEN
;
WW_QUEEN_4	equ	BB_QUEEN_4 XOR 80H
WW_QUEEN_5	equ	BB_QUEEN_5 XOR 80H
WW_QUEEN_6	equ	BB_QUEEN_6 XOR 80H
WW_QUEEN_7	equ	BB_QUEEN_7 XOR 80H
WW_QUEEN_8	equ	BB_QUEEN_8 XOR 80H
WW_QUEEN_9	equ	BB_QUEEN_9 XOR 80H
;
;	ROCK
;
WW_ROCK_4	equ	BB_ROCK_4 XOR 80H
WW_ROCK_5	equ	BB_ROCK_5 XOR 80H
WW_ROCK_6	equ	BB_ROCK_6 XOR 80H
WW_ROCK_7	equ	BB_ROCK_7 XOR 80H
WW_ROCK_8	equ	BB_ROCK_8 XOR 80H
WW_ROCK_9	equ	BB_ROCK_9 XOR 80H
;
;	KING
;
WW_KING_4	equ	BB_KING_4 XOR 80H
WW_KING_5	equ	BB_KING_5 XOR 80H
WW_KING_6	equ	BB_KING_6 XOR 80H
WW_KING_7	equ	BB_KING_7 XOR 80H
WW_KING_8	equ	BB_KING_8 XOR 80H
WW_KING_9	equ	BB_KING_9 XOR 80H

; piece definitions

WB_PAWN:	defb	WB_BASE_1,WB_BASE_2,WB_BASE_3,WB_PAWN_4,WB_PAWN_5,WB_PAWN_6,WB_PAWN_7,WB_PAWN_8,WB_PAWN_9
WB_KNIGHT:	defb	WB_BASE_1,WB_BASE_2,WB_BASE_3,WB_KNIGHT_4,WB_KNIGHT_5,WB_KNIGHT_6,WB_KNIGHT_7,WB_KNIGHT_8,WB_KNIGHT_9
WB_BISHOP:	defb	WB_BASE_1,WB_BASE_2,WB_BASE_3,WB_BISHOP_4,WB_BISHOP_5,WB_BISHOP_6,WB_BISHOP_7,WB_BISHOP_8,WB_BISHOP_9
WB_QUEEN:	defb	WB_BASE_1,WB_BASE_2,WB_BASE_3,WB_QUEEN_4,WB_QUEEN_5,WB_QUEEN_6,WB_QUEEN_7,WB_QUEEN_8,WB_QUEEN_9
WB_ROCK:	defb	WB_BASE_1,WB_BASE_2,WB_BASE_3,WB_ROCK_4,WB_ROCK_5,WB_ROCK_6,WB_ROCK_7,WB_ROCK_8,WB_ROCK_9
WB_KING:	defb	WB_BASE_1,WB_BASE_2,WB_BASE_3,WB_KING_4,WB_KING_5,WB_KING_6,WB_KING_7,WB_KING_8,WB_KING_9
WB_MKING:	defb	WB_BASE_1,WB_BASE_2,WB_BASE_3,WB_KING_4,WB_KING_5,WB_KING_6,WB_KING_7,BLANK,WB_KING_9

BW_PAWN:	defb	BW_BASE_1,BW_BASE_2,BW_BASE_3,BW_PAWN_4,BW_PAWN_5,BW_PAWN_6,BW_PAWN_7,BW_PAWN_8,BW_PAWN_9
BW_KNIGHT:	defb	BW_BASE_1,BW_BASE_2,BW_BASE_3,BW_KNIGHT_4,BW_KNIGHT_5,BW_KNIGHT_6,BW_KNIGHT_7,BW_KNIGHT_8,BW_KNIGHT_9
BW_BISHOP:	defb	BW_BASE_1,BW_BASE_2,BW_BASE_3,BW_BISHOP_4,BW_BISHOP_5,BW_BISHOP_6,BW_BISHOP_7,BW_BISHOP_8,BW_BISHOP_9
BW_QUEEN:	defb	BW_BASE_1,BW_BASE_2,BW_BASE_3,BW_QUEEN_4,BW_QUEEN_5,BW_QUEEN_6,BW_QUEEN_7,BW_QUEEN_8,BW_QUEEN_9
BW_ROCK:	defb	BW_BASE_1,BW_BASE_2,BW_BASE_3,BW_ROCK_4,BW_ROCK_5,BW_ROCK_6,BW_ROCK_7,BW_ROCK_8,BW_ROCK_9
BW_KING:	defb	BW_BASE_1,BW_BASE_2,BW_BASE_3,BW_KING_4,BW_KING_5,BW_KING_6,BW_KING_7,BW_KING_8,BW_KING_9
BW_MKING:	defb	BW_BASE_1,BW_BASE_2,BW_BASE_3,BW_KING_4,BW_KING_5,BW_KING_6,BW_KING_7,REV_BLANK,BW_KING_9

BB_PAWN:	defb	BB_BASE_1,BB_BASE_2,BB_BASE_3,BB_PAWN_4,BB_PAWN_5,BB_PAWN_6,BB_PAWN_7,BB_PAWN_8,BB_PAWN_9
BB_KNIGHT:	defb	BB_BASE_1,BB_BASE_2,BB_BASE_3,BB_KNIGHT_4,BB_KNIGHT_5,BB_KNIGHT_6,BB_KNIGHT_7,BB_KNIGHT_8,BB_KNIGHT_9
BB_BISHOP:	defb	BB_BASE_1,BB_BASE_2,BB_BASE_3,BB_BISHOP_4,BB_BISHOP_5,BB_BISHOP_6,BB_BISHOP_7,BB_BISHOP_8,BB_BISHOP_9
BB_QUEEN:	defb	BB_BASE_1,BB_BASE_2,BB_BASE_3,BB_QUEEN_4,BB_QUEEN_5,BB_QUEEN_6,BB_QUEEN_7,BB_QUEEN_8,BB_QUEEN_9
BB_ROCK:	defb	BB_BASE_1,BB_BASE_2,BB_BASE_3,BB_ROCK_4,BB_ROCK_5,BB_ROCK_6,BB_ROCK_7,BB_ROCK_8,BB_ROCK_9
BB_KING:	defb	BB_BASE_1,BB_BASE_2,BB_BASE_3,BB_KING_4,BB_KING_5,BB_KING_6,BB_KING_7,BB_KING_8,BB_KING_9
BB_MKING:	defb	BB_BASE_1,BB_BASE_2,BB_BASE_3,BB_KING_4,BB_KING_5,BB_KING_6,BB_KING_7,BLANK,BB_KING_9

WW_PAWN:	defb	WW_BASE_1,WW_BASE_2,WW_BASE_3,WW_PAWN_4,WW_PAWN_5,WW_PAWN_6,WW_PAWN_7,WW_PAWN_8,WW_PAWN_9
WW_KNIGHT:	defb	WW_BASE_1,WW_BASE_2,WW_BASE_3,WW_KNIGHT_4,WW_KNIGHT_5,WW_KNIGHT_6,WW_KNIGHT_7,WW_KNIGHT_8,WW_KNIGHT_9
WW_BISHOP:	defb	WW_BASE_1,WW_BASE_2,WW_BASE_3,WW_BISHOP_4,WW_BISHOP_5,WW_BISHOP_6,WW_BISHOP_7,WW_BISHOP_8,WW_BISHOP_9
WW_QUEEN:	defb	WW_BASE_1,WW_BASE_2,WW_BASE_3,WW_QUEEN_4,WW_QUEEN_5,WW_QUEEN_6,WW_QUEEN_7,WW_QUEEN_8,WW_QUEEN_9
WW_ROCK:	defb	WW_BASE_1,WW_BASE_2,WW_BASE_3,WW_ROCK_4,WW_ROCK_5,WW_ROCK_6,WW_ROCK_7,WW_ROCK_8,WW_ROCK_9;
WW_KING:	defb	WW_BASE_1,WW_BASE_2,WW_BASE_3,WW_KING_4,WW_KING_5,WW_KING_6,WW_KING_7,WW_KING_8,WW_KING_9
WW_MKING:	defb	WW_BASE_1,WW_BASE_2,WW_BASE_3,WW_KING_4,WW_KING_5,WW_KING_6,WW_KING_7,REV_BLANK,WW_KING_9

BB_EMPTY:	defb	BLANK,BLANK,BLANK,BLANK,BLANK,BLANK,BLANK,BLANK,BLANK
WW_EMPTY:	defb	REV_BLANK,REV_BLANK,REV_BLANK,REV_BLANK,REV_BLANK,REV_BLANK,REV_BLANK,REV_BLANK,REV_BLANK

Fonts_64_89:	defs	26 * 8
Fonts_1_26:	defs	26 * 8
;
;	Save fonts for 64 to 89 (26 chars)
;
Save_64_to_89:
	ld	e,26 * 8		;counter
	ld	c,0EH			;character values 0x40 (64) to 0x5F (95)
	ld	b,0			;(64)
	ld	hl,Fonts_64_89
1:
	in	a,(c)
	ld	(hl),a
	inc	hl
	inc	b
	dec	e
	jr	nz,1b
	ret
;
;	Load fonts for 64 to 89
;
Load_64_to_89:
	ld	hl,CUSTOM_64
Load_96:
	ld	e,26 * 8		;counter
	ld	c,0EH			;character values 0x40 (64) to 0x5F (95)
	ld	b,0			;(64)
1:
	ld	a,(hl)
	out	(c),a
	inc	hl
	inc	b
	dec	e
	jr	nz,1b
	ret
;
;	Restore fonts for 64 to 89
;
Restore_64_to_89:
	ld	hl,Fonts_64_89
	jr	Load_96
;
;	Save fonts for 1 to 26 (26 chars)
;
Save_1_to_26:
	ld	e,26 * 8		;counter
	ld	c,0CH			;character values 0x0 to 0x1F
	ld	b,8			;(1)
	ld	hl,Fonts_1_26
1:
	in	a,(c)
	ld	(hl),a
	inc	hl
	inc	b
	dec	e
	jr	nz,1b
	ret
;
;	Load fonts for 1 to 26
;
Load_1_to_26:
	ld	hl,CUSTOM_1		;font bitmaps
Load_1:
	ld	e,26 * 8		;counter
	ld	c,0CH			;character values 0x0 to 0x1F
	ld	b,8			;(1)
1:
	ld	a,(hl)
	out	(c),a
	inc	hl
	inc	b
	dec	e
	jr	nz,1b
	ret
;
;	Restore fonts for 64 to 89
;
Restore_1_to_26:
	ld	hl,Fonts_1_26
	jr	Load_1
;
;------------------------------------------------------------------
;
Cursor: defw    0               ;cursor registers
;
;       C=row=0...47
;       E=col=0...63
;
CrtLocate:
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
GetTime:
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
                               

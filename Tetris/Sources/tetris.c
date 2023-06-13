/* Micro Tetris, based on an obfuscated tetris, 1989 IOCCC Best Game
 *
 * Copyright (c) 1989  John Tromp <john.tromp@gmail.com>
 * Copyright (c) 2009-2021  Joachim Wiberg <troglobit@gmail.com>
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 * See the following URLs for more information, first John Tromp's page about
 * the game http://homepages.cwi.nl/~tromp/tetris.html then there's the entry
 * page at IOCCC http://www.ioccc.org/1989/tromp.hint
 *
 * Adapted to Z80ALL by Ladislau Szilagyi, May 2023
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "vgadrive.h"

#define clrscr()        CrtClear()
#define gotoxy(x,y)     CrtLocate(y,x)
#define reverse()       CrtReverse()
#define normal()        CrtNormal()
#define puts(p)         StringOut(p)

#define next_shape()	(&shapes[xrnd() % 7 * 5])

/* the board */
#define      B_COLS 12
#define      B_ROWS 48
#define      B_SIZE (B_ROWS * B_COLS)

#define TL     -B_COLS-1        /* top left */
#define TC     -B_COLS          /* top center */
#define TR     -B_COLS+1        /* top right */
#define ML     -1               /* middle left */
#define MR     1                /* middle right */
#define BL     B_COLS-1         /* bottom left */
#define BC     B_COLS           /* bottom center */
#define BR     B_COLS+1         /* bottom right */

/* These can be overridden by the user. */
#define DEFAULT_KEYS "jkl pq"
#define KEY_LEFT   0
#define KEY_RIGHT  2
#define KEY_ROTATE 1
#define KEY_DROP   3
#define KEY_PAUSE  4
#define KEY_QUIT   5

char buf[80];
char *keys = DEFAULT_KEYS;
int board[B_SIZE], shadow[B_SIZE];

int *shape;

int shapes[] = {
         7, TL, TC, MR, 1,      /* ""__   */
         8, TR, TC, ML, 1,      /* __""   */
         9, ML, MR, BC, 1,      /* "|"    */
         3, TL, TC, ML, 1,      /* square */
        12, ML, BL, MR, 1,      /* |"""   */
        15, ML, BR, MR, 1,      /* """|   */
        18, ML, MR,  2, 1,      /* ---- sticks out */
         0, TC, ML, BL, 1,      /* /    */
         1, TC, MR, BR, 1,      /* \    */
        10, TC, MR, BC, 1,      /* |-   */
        11, TC, ML, MR, 1,      /* _|_  */
         2, TC, ML, BC, 1,      /* -|   */
        13, TC, BC, BR, 1,      /* |_   */
        14, TR, ML, MR, 1,      /* ___| */
         4, TL, TC, BC, 1,      /* "|   */
        16, TR, TC, BC, 1,      /* |"   */
        17, TL, MR, ML, 1,      /* |___ */
         5, TC, BC, BL, 1,      /* _| */
         6, TC, BC,  2 * B_COLS, 1, /* | sticks out */
};

unsigned int     xrnd(void);
void    xrndseed(void);

void	InitRTC(void);
long	GetTime(void);

void draw(int x, int y, int c)
{
        gotoxy(x, y);

        if (c)
                reverse();
	
	CharOut(' '); /* puts(" "); */

	if (c)
		normal();
}

int wait(void)
{
        unsigned int    i,j;
        int c;

        for ( i = 0; i < 50; i++ )
        {
                for ( j = 0; j < 50; j++)
                {
                        if ((c = CharIn()) != -1)
                                return c;
                }
        }

        return -1;
}

int update(void)
{
        int x, y, c;

	GetTime();

        /* Display board. */
        for (y = 1; y < B_ROWS - 1; y++)
        {
                for (x = 0; x < B_COLS; x++)
                {
                        if (board[y * B_COLS + x] - shadow[y * B_COLS + x])
                        {
                                c = board[y * B_COLS + x]; /* color */

                                shadow[y * B_COLS + x] = c;

                                draw(x * 2 + 28, y, c);
                        }
                }
        }

        return wait();
}

/* Check if shape fits in the current position */
int fits_in(int *s, int pos)
{
        if (board[pos] || board[pos + s[1]] || board[pos + s[2]] || board[pos + s[3]])
                return 0;

        return 1;
}

/* place shape at pos with color */
void place(int *s, int pos, int c)
{
        board[pos] = c;
        board[pos + s[1]] = c;
        board[pos + s[2]] = c;
        board[pos + s[3]] = c;
}

void show_online_help(void)
{
        gotoxy(0, 11);
        puts("j     - left");
        gotoxy(0, 12);
        puts("k     - rotate");
        gotoxy(0, 13);
        puts("l     - right");
        gotoxy(0, 14);
        puts("space - drop");
        gotoxy(0, 15);
        puts("p     - pause");
        gotoxy(0, 16);
        puts("q     - quit");
}

void main(void)
{
        int c = 0, i, j, *ptr;
        int pos = 17;
        int *backup;
	unsigned long t;
	unsigned int h,m,s;

        /* Initialize board, grey border, used to be white(7) */
        ptr = board;

        for (i = B_SIZE; i; i--)
                *ptr++ = i < 25 || i % B_COLS < 2 ? 1 : 0;

        xrndseed();

        clrscr();
        show_online_help();

        gotoxy(0, 47);
        puts("Hit any key to begin playing TETRIS...");

        while (CharIn() == -1)
                ;

        CrtClearLine(47);

        shape = next_shape();

	InitRTC();

        while (1)
        {
                if (c < 0)
                {
                        if (fits_in(shape, pos + B_COLS))
                                pos += B_COLS;
                        else
                        {
                                place(shape, pos, 1);

                                for (j = 0; j < B_SIZE-2*B_COLS; j = B_COLS * (j / B_COLS + 1))
                                {
                                        for (; board[++j];)
                                        {
                                                if (j % B_COLS == 10)
                                                {
                                                        for (; j % B_COLS; board[j--] = 0)
                                                           ;
                                                        c = update();

                                                        for (; --j; board[j + B_COLS] = board[j])
                                                           ;
                                                        c = update();
                                                }
                                        }
                                }

                                shape = next_shape();

				pos = 17;
				
				if (!fits_in(shape, pos))
					c = keys[KEY_QUIT];
                        }
                }

		if (c == keys[KEY_QUIT])
			break;

                if (c == keys[KEY_LEFT])
                {
                        if (!fits_in(shape, --pos))
                                ++pos;
                }

                if (c == keys[KEY_ROTATE])
                {
                        backup = shape;
                        shape = &shapes[5 * *shape];    /* Rotate */

                        /* Check if it fits, if not restore shape from backup */
                        if (!fits_in(shape, pos))
                                shape = backup;
                }

                if (c == keys[KEY_RIGHT])
                {
                        if (!fits_in(shape, ++pos))
                                --pos;
                }

                if (c == keys[KEY_DROP])
                {
                        for (; fits_in(shape, pos + B_COLS); )
                                pos += B_COLS;
                }

                if (c == keys[KEY_PAUSE])
                {
                        /* wait for another KEY_PAUSE */
                        do
                        {
                                c = CharIn();

                                if (c == -1)
                                        continue;
                        }
                        while (c != keys[KEY_PAUSE]);
                }

                place(shape, pos, 1);
                c = update();
                place(shape, pos, 0);
        }

	clrscr();
	t = GetTime();
	s = t & 0xFF;
	m = t >> 8;
	h = (t >> 16) & 0xFF;
	printf("Elapsed time: %02u:%02u:%02u\r\n", h, m, s);
}

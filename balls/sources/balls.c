//	Ladislau Szilagyi, Sept 2024
//
//	only for Z80ALL

#include <stdio.h>

#define XMAX 123
#define YMAX 113
#define int_part(x) (x >> 8)
#define ONE_STEP 1

#define REV_BLANK	0x20+0x80

int xold,yold;          //fp    previous coord
int x,y;                //fp    crt coord
int x0,y0;              //fp    start coord
int halfPI = 0x192;     //fp    PI/2
int PI = 0x324;         //fp    PI
int twoPI = 0x648;      //fp    2*PI
int threePI = 0x96C;    //fp    3*PI
int delta;              //fp    movement increment
int angle;

void CrtSetup(void);
void CrtOut(char);
char CrtIn(void);
char CrtSts(void);
void putstr(char*);

void	PrintChar(int Y, int X, char ch);

int VirtualToRealRow(int vRow)
{
	int n = vRow/5;
	int v = vRow % 5;

	if (v == 0 || v == 1)
		return 1 + 2*n;
	else if (v == 2 || v == 3)
		return 2 + 2*n;
	else
		return 3 + 2*n;
}

int GetFontIndex(int vRow, int vCol)
{
	int v = vRow % 5;
	int x = vCol % 2;

	if (v == 0)
		return x == 0 ? 1 : 3;
	else if (v == 1)
		return x == 0 ? 2 : 4;
	else if (v == 2)
		return x == 0 ? 5 : 8;
	else if (v == 3)
		return x == 0 ? 6 : 10;
	else
		return x == 0 ? 7 : 9;
}

void show(int x, int y)
{
	PrintChar(VirtualToRealRow(y), 1 + (x/2), 0x40 + GetFontIndex(y, x));
}

void hide(int x, int y)
{
	PrintChar(VirtualToRealRow(y), 1 + (x/2), ' ');
}

void short_wait(void)
{
	int i;

	for (i=0; i<1000; i++)
		;
}

void xrndseed(void);
unsigned int xrnd(void);
void	Clear(void);

int sin(int);
int cos(int);

int mult(int count, int fpval)
{
        int ret=0;

        do
		ret += fpval;
        while (--count);

        return ret;
}

void show_boundaries(void)
{
	int i;

	Clear();

	for (i = 0; i < 64; i++)
		PrintChar(47, i, REV_BLANK);

	for (i = 0; i < 64; i++)
		PrintChar(0, i, REV_BLANK);

	for (i = 1; i <= 46; i++)
		PrintChar(i, 0, REV_BLANK);

	for (i = 1; i <= 46; i++)
		PrintChar(i, 63, REV_BLANK);

	PrintChar(24, 32, 0x40);
}

int safe_x(int x)
{
	if (int_part(x) == 0)
		x = 0x100 | (x & 0xFF);
	else if (int_part(x) == XMAX)
		x = ((XMAX-1) << 8) | (x & 0xFF);

	return x;
}

int safe_y(int y)
{
	if (int_part(y) == 0)
		y = 0x100 | (y & 0xFF);
	else if (int_part(y) == YMAX)
		y = ((YMAX-1) << 8) | (y & 0xFF);

	return y;
}

char keyhit();
char getkey();

void    main(void)
{
	int count1 = 0;
	int count2;
	int xmove, ymove;
	int xbasket, ybasket;
	int gotit = 0;

	CrtSetup();

	putstr("catch the ball game\r\n\n");
	putstr("the ball starts from the bottom-left corner,\r\n");
	putstr(" being thrown in random directions,\r\n");
	putstr(" and will bounce off the edges of the screen\r\n");
	putstr("you have to try to catch the ball, in 10 seconds, with\r\n");
 	putstr(" the small basket initially placed in the middle of the screen\r\n");
	putstr("you can move the basket using the keys\r\n");
	putstr(" s=left, d=right, x=down, e=up\r\n\nyou have 10 attempts");
	putstr(" at your disposal...\r\n\ngood luck!\r\n\npress any key to start\r\n\n");
	putstr("...and quit anytime with CTRL.C");

	CrtIn();

	Save_0_to_10();
	Load_0_to_10();

        xrndseed();

        do
        {
		count2 = 0;

		show_boundaries();	//clear screen, show boundaries & basket

		// set basket coord
		xbasket = 32;
		ybasket = 24;

                // set start coord
                x0 = xold = 0;
                y0 = yold = 0;

                // show object
                show(x0, y0);

                // compute random angle (< PI/2)
                angle = xrnd() % halfPI;

                delta = ONE_STEP;

                do
                {
                        short_wait();            //wait a little for each step, then...

			if (CrtSts())
			{			//if key hit...
				switch (CrtIn())
				{
					case 's':	//left
						if (xbasket != 1)
						{
							PrintChar(ybasket, xbasket, ' ');
							xbasket--;
							PrintChar(ybasket, xbasket, 0x40);

							if (xbasket == int_part(x)/2 &&
							    ybasket == int_part(y)/2)
							{
								gotit++;
								goto next;
							}
						}
						break;
					case 'd':	//right
						if (xbasket != 62)
						{
							PrintChar(ybasket, xbasket, ' ');
							xbasket++;
							PrintChar(ybasket, xbasket, 0x40);

							if (xbasket == int_part(x)/2 &&
							    ybasket == int_part(y)/2)
							{
								gotit++;
								goto next;
							}
						}
						break;
					case 'e':	//up
						if (ybasket != 46)
						{
							PrintChar(ybasket, xbasket, ' ');
							ybasket++;
							PrintChar(ybasket, xbasket, 0x40);

							if (xbasket == int_part(x)/2 &&
							    ybasket == int_part(y)/2)
							{
								gotit++;
								goto next;
							}
						}
						break;
					case 'x':	//down
						if (ybasket != 1)
						{
							PrintChar(ybasket, xbasket, ' ');
							ybasket--;
							PrintChar(ybasket, xbasket, 0x40);

							if (xbasket == int_part(x)/2 &&
							    ybasket == int_part(y)/2)
							{
								gotit++;
								goto next;
							}
						}
						break;
					case 3: Restore_0_to_10();
						exit(1);
					default:
						break;
				}
			}

			xmove = ymove = 0;

                        // compute crt coord, using the start coord, the crt distance and the crt angle
                        x = x0 + mult(delta, cos(angle));
                        y = y0 + mult(delta, sin(angle));

                        // if position changed ...
                        if (int_part(x) != int_part(xold) || int_part(y) != int_part(yold))
                        {
       				xmove = int_part(x) - int_part(xold);
				ymove = int_part(y) - int_part(yold);
				hide(int_part(xold), int_part(yold));
				xold = x;
				yold = y;
				show(int_part(x), int_part(y));

				if (xbasket == int_part(x)/2 && ybasket == int_part(y)/2)
				{
					gotit++;
					goto next;
				}
			}

                        // handle hitting the boundaries
                        if (xmove > 0 && int_part(x) == XMAX)
                        {
                                x0 = xold = x;          // set new start coord
                                y0 = yold = safe_y(y);

                                // compute new angle
                                if (angle < halfPI)
                                        angle = PI - angle;
                                else
                                        angle = threePI - angle;

                                delta = ONE_STEP;
                        }
                        else if (xmove < 0 && int_part(x) == 0)
                        {
                                x0 = xold = x;          // set new start coord
                                y0 = yold = safe_y(y);

                                // compute new angle
                                if (angle > PI)
                                        angle = threePI - angle;
                                else
                                        angle = PI - angle;

                                delta = ONE_STEP;
                        }
                        else if (ymove != 0 &&
				(int_part(y) == YMAX || int_part(y) == 0))
                        {
                                x0 = xold = safe_x(x);          // set new start coord
                                y0 = yold = y;

                                // compute new angle
                                angle = twoPI - angle;
                                delta = ONE_STEP;
                        }
                        else
                        {
                                delta += ONE_STEP;      // ... continue the movement using the old angle
                        }
                }
                while (count2++ < 1000);
next:;
        }
        while(count1++ < 10);

	Clear();

	Restore_0_to_10();

	printf("\r\nyou caught the ball %d times out of 10 attempts", gotit);
}


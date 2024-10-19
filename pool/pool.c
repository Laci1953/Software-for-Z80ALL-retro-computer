// Game of POOL for Z80ALL
//
// Ladislau Szilagyi, October 2024
//
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>

int mul(int,int);
int div(int,int);
int sin(int);
int cos(int);
int arctan(int);
int fpsqrt(int);
int xdivytofp(int,int);
int neg(int);
int positive(int);

void xrndseed(void);
unsigned int xrnd(void);

void CrtSetup(void);
void CrtOut(char);
char CrtIn(void);
char CrtSts(void);
void putstr(char*);
void getstr(char*);
void Clear(void);
void ClearTopLine(void);
void PrintStr(int,int,char*);
void PrintChar(int y, int x, char ch);

void Load_CH(int xf, int yf);

#define REV_BLANK	0x20+0x80

char buf[64];
char buftmp1[10];
char buftmp2[10];

int halfPI =  0x192;     //fp    PI/2
int PI =      0x324;     //fp    PI
int twoPI =   0x648;     //fp    2*PI
int threePI = 0x96C;     //fp    3*PI

// x = 0   & 1   : border
// x = 126 & 127 : border
// y = 0   & 1   : border
// y = 117 & 118 : text line
// y = 115 & 116 : border

// dynamic ball position from
// x = 2 to 124
// y = 2 to 113

#define XMIN 2
#define XMAX 124
#define YMIN 2
#define YMAX 113

// target ball position from
// X = 4 to 122
// Y = 5 to 110 (multiples of 5)

#define TXMIN 4
#define TYMIN 5
#define TXMAX 122
#define TYMAX 110

#define ROW1_BASKET 22
#define ROW2_BASKET 23
#define ROW3_BASKET 24

#define Y_BASKET_MIN 55
#define Y_BASKET_MAX 61

#define COL11_BASKET 12
#define COL12_BASKET 13
#define COL13_BASKET 14

#define COL21_BASKET 50
#define COL22_BASKET 51
#define COL23_BASKET 52

#define X_BASKET1_MIN 24
#define X_BASKET1_MAX 28

#define X_BASKET2_MIN 100
#define X_BASKET2_MAX 104

#define int_part(x) (x >> 8)

#define BALLS_GAP	40

char TrainingMode;	// 1 = ON
int _X0, _Y0, _X1, _Y1;	
int _x0, _y0, _x1, _y1;	// fixed point
int X0, Y0, X1, Y1, XCH, YCH;
int XCHf, YCHf;	//fractional part 0...7
// XCH + XCHf/8, YCH + YCHf/8
int x0, y0, x1, y1;	// fixed point
int colX0, rowY0;
int colX1, rowY1;
int colCH, rowCH;
int XCHfp, YCHfp;	// fixed point
int xper, yper;		// fixed point

char status;		// ball status
#define BOUNCED 1
#define BASKET 2
#define STOPPED 3
#define COLLIDED 4

int speed;		// fixed point
int angle;		// fixed point
int alpha;		// fixed point
int new_angle;		// fixed point

char keep_speed;	// 1 = keep same speed at impact

#define WHITE 0
#define BLACK 1
char moving_ball;	// 0 = white ball, 1 = black ball

char bounce;		// 1 = bounce back

char collision_exp;	// 1 = collision expected
int distance;		// fixed point
int ddelta;		// fixed point
int xp;			// fixed point
int yp;			// fixed point

#define ONE_STEP 1

int xstart, ystart;	//fp	start coord
int xold, yold;         //fp    previous coord
int xtmp, ytmp;         //fp    crt coord
int incr;		// movement increment
int xmove, ymove;
int counter;		// speed related
int init_counter;	// speed related
int brake_counter;

int tmpX[128];
int tmpY[128];

//
// Choose one point with the lowest decimal part for Y,
// given the vector:
// X * tan(alpha) – Y + yp – xp * tan(alpha) = 0
// and fill in coords for the white ball movement vector
void Choose(int xp, int yp, int alpha)
{
	int n, max;
	int x, y;
	int tan;

	if (moving_ball == BLACK)
		return;

	x0 = xp;
	X0 = int_part(x0);
	y0 = yp;
	Y0 = int_part(y0);

	tan = div(sin(alpha), cos(alpha));

	max = 0;

	for (n = 0; n < 128; n++)
	{
		x = n << 8;
		y = mul(x, tan) - mul(xp, tan) + yp;

		if (y < 0)
			continue;

		tmpX[max] = x;
		tmpY[max] = y;
		max++;
	}

	XCHfp = tmpX[0];
	YCHfp = tmpY[0];

	if (max > 1)
		for (n = 1; n < max; n++)
			if ((YCHfp & 0xFF) > (tmpY[n] & 0xFF))
			{
				XCHfp = tmpX[n];
				YCHfp = tmpY[n];
				tmpY[n] = 0xFF;
			}

	XCH = int_part(XCHfp);
	YCH = int_part(YCHfp);
}

int VirtualToRealRow(int vRow)
{
	int n = vRow/5;
	int v = vRow % 5;

	if (v == 0 || v == 1)
		return 2*n;
	else if (v == 2 || v == 3)
		return 1 + 2*n;
	else
		return 2 + 2*n;
}

int RealToVirtualRow(int vRow)
{
	int n = (vRow * 10)/4;
	int v = (vRow * 10) % 4;

	if (v)
		return n+1;
	else
		return n;
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
	PrintChar(VirtualToRealRow(y), (x/2), 0x40 + GetFontIndex(y, x));
}

void hide(int x, int y)
{
	PrintChar(VirtualToRealRow(y), (x/2), ' ');
}

// count = integer
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
		PrintChar(46, i, REV_BLANK);

	for (i = 0; i < 64; i++)
		PrintChar(0, i, REV_BLANK);

	for (i = 1; i <= 45; i++)
		PrintChar(i, 0, REV_BLANK);

	for (i = 1; i <= 45; i++)
		PrintChar(i, 63, REV_BLANK);

	for (i = COL11_BASKET; i <= COL13_BASKET; i++)
		PrintChar(0, i, ' ');

	for (i = COL21_BASKET; i <= COL23_BASKET; i++)
		PrintChar(0, i, ' ');

	for (i = COL11_BASKET; i <= COL13_BASKET; i++)
		PrintChar(46, i, ' ');

	for (i = COL21_BASKET; i <= COL23_BASKET; i++)
		PrintChar(46, i, ' ');

	for (i = ROW1_BASKET; i <= ROW3_BASKET; i++)
		PrintChar(i, 0, ' ');

	for (i = ROW1_BASKET; i <= ROW3_BASKET; i++)
		PrintChar(i, 63, ' ');
}

void short_wait(void)
{
	int i;

	for (i=0; i<500; i++)
		;
}

char CheckYBasket(int v)
{
	if (v >= Y_BASKET_MIN && v <= Y_BASKET_MAX)
		return 1;
	else
		return 0;
}

char CheckXBasket(int v)
{
	if ((v >= X_BASKET1_MIN && v <= X_BASKET1_MAX) || (v >= X_BASKET2_MIN && v <= X_BASKET2_MAX))
		return 1;
	else
		return 0;
}

void SetWhiteBallSafeCoord(void)
{
	int X,Y;

	X = int_part(xtmp);
	Y = int_part(ytmp);

	hide(X, Y);

	colX0 = X / 2;
	rowY0 = VirtualToRealRow(Y);

	X0 = colX0 * 2;
	x0 = X0 << 8;
	Y0 = RealToVirtualRow(rowY0);
	y0 = Y0 << 8;
}

void SetBlackBallSafeCoord(void)
{
	int X,Y;

	X = int_part(xtmp);
	Y = int_part(ytmp);

	hide(X, Y);

	colX1 = X / 2;
	rowY1 = VirtualToRealRow(Y);

	X1 = colX1 * 2;
	x1 = X1 << 8;
	Y1 = RealToVirtualRow(rowY1);
	y1 = Y1 << 8;
}

//
// Moves a ball from (xstart, ystart) at angle
//
// xstart, ystart, angle
// counter, init_counter & brake counter must be set
//
// returns 
//	BOUNCED if ball hit the boundaries
//	BASKET if ball drops to basket
//	STOPPED if ball stopped
//
char move_ball(void)
{
	//start moving the ball
	incr = ONE_STEP;
		
	xold = xstart;
	yold = ystart;

	do
	{
		short_wait();           // wait a little for each step, then...
			
		counter--;		// decrement counter

		if (counter == 0)
		{			// move the ball
					// first, apply brake rules (each 10 movements, speed decreases...)
			brake_counter--;

			if (brake_counter == 0)
			{
				brake_counter = 10;
				init_counter++;
				speed--;

				if (speed == 0)
				{
					if (moving_ball == WHITE)
					{
						SetWhiteBallSafeCoord();
						PrintChar(rowY0, colX0, 0x41);
					}
					else
					{
						SetBlackBallSafeCoord();
						PrintChar(rowY1, colX1, 0x41);
					}

					return STOPPED;
				}
			}

			counter = init_counter;

			xmove = ymove = 0;

                       	// compute crt coord, using the start coord, the crt distance and the crt angle
                       	xtmp = xstart + mult(incr, cos(angle));
                       	ytmp = ystart + mult(incr, sin(angle));

                       	// if position changed ...
                       	if (int_part(xtmp) != int_part(xold) || int_part(ytmp) != int_part(yold))
                       	{
       				xmove = int_part(xtmp) - int_part(xold);
				ymove = int_part(ytmp) - int_part(yold);
			}

                       	// handle hitting the boundaries
                       	if (xmove > 0 && int_part(xtmp) >= XMAX)
                       	{
				if (CheckYBasket(int_part(ytmp)))
					return BASKET;

				xstart = xold;          		// set new start coord
				ystart = yold;

				// compute new angle
				if (angle < halfPI)
                      	    		angle = PI - angle;
				else
					angle = threePI - angle;

				Choose(xstart, ystart, angle);

				return BOUNCED;
                       	}
			else if (xmove < 0 && int_part(xtmp) <= XMIN)
			{
				if (CheckYBasket(int_part(ytmp)))
					return BASKET;

                                xstart = xold;          		// set new start coord
                               	ystart = yold;

                               	// compute new angle
                               	if (angle > PI)
                                     	angle = threePI - angle;
                               	else
                                       	angle = PI - angle;

				Choose(xstart, ystart, angle);

				return BOUNCED;
                       	}
                       	else if (ymove != 0 && int_part(ytmp) <= YMIN)
                       	{
				if (CheckXBasket(int_part(xtmp)))
					return BASKET;

                                xstart = xold;          		// set new start coord
                               	ystart = yold;

                               	// compute new angle
                               	angle = twoPI - angle;

				Choose(xstart, ystart, angle);

				return BOUNCED;
                       	}
                       	else if (ymove != 0 && int_part(ytmp) >= YMAX)
                       	{
				if (CheckXBasket(int_part(xtmp)))
					return BASKET;

                                xstart = xold;          		// set new start coord
                               	ystart = yold;

                               	// compute new angle
                               	angle = twoPI - angle;

				Choose(xstart, ystart, angle);

				return BOUNCED;
                       	}
                       	else
                       	{
				hide(int_part(xold), int_part(yold));
				xold = xtmp;
				yold = ytmp;
				show(int_part(xtmp), int_part(ytmp));

				if (moving_ball == WHITE)
					PrintChar(rowY1, colX1, 0x40);
				else
					PrintChar(rowY0, colX0, 0x40);

                               	incr += ONE_STEP;      // ... continue the movement using the old angle
                       	}

			if (xmove != 0 || ymove != 0)
			{	// if ball moved...
				// check distance between balls
				if ((moving_ball == WHITE) && (collision_exp == 1) && 
				    (abs(xtmp - x1) < 0x300 && abs(ytmp - y1) < 0x300))
				{
					// collision !
					// only impacted ball (black) will move...

					SetWhiteBallSafeCoord();

					collision_exp = 0;	

					// impacted ball (black) will start from (x1,y1)... 
					xstart = x1;
					ystart = y1;

					if (!keep_speed)
					{
						angle = new_angle; //using new angle

						// with an initial speed = speed * cos(alpha)

						speed = int_part( positive(mult(speed, cos(alpha))) );

						if (speed == 0)
							return STOPPED;
					}

					// change fonts, show white ball as a static ball
					moving_ball = BLACK;
					BLoad_0_to_10(); // load fonts for the black ball

					PrintChar(rowY0, colX0, 0x40);
					PrintChar(rowY1, colX1, 0x41);

					init_counter = counter = 26 - speed; 	//set up speed control
					brake_counter = 10;			//set up brake control

					return COLLIDED;
				}
				else if ((moving_ball == BLACK) && (status == BOUNCED) &&
				         (abs(xtmp - x1) < 0x300 && abs(ytmp - y1) < 0x300))
				{
					//stop black ball
					SetBlackBallSafeCoord();

					moving_ball = WHITE;
					Load_0_to_10(); // load fonts for the white ball
					PrintChar(rowY1, colX1, 0x40);	//black ball
					PrintChar(rowY0, colX0, 0x41);	//white ball

					return STOPPED;
				}
			}
		}
	} while(1);
}

//
// determine coord for the two balls
// (x1,y1) is the target
//
void get_balls_coord(void)
{
	// get random (x0,y0)
	_X0 = 2 * (xrnd() % ((XMAX-XMIN)/2)) + XMIN + 1;
	_Y0 = 2 * (xrnd() % ((TYMAX-TYMIN)/2)) + TYMIN + 1;

	// choose (x1,y1) so that |x0-x1| > BALLS_GAP and |y0-y1| > BALLS_GAP
	do
		_X1 = 2 * (xrnd() % ((TXMAX-TXMIN)/2)) + TXMIN + 1;
	while (abs(_X0 - _X1) < BALLS_GAP);

	do 
		_Y1 = 2 * (xrnd() % ((TYMAX-TYMIN)/2)) + TYMIN + 1;
	while (abs(_Y0 - _Y1) < BALLS_GAP);

	_x0 = _X0 << 8;
	_y0 = _Y0 << 8;

	_x1 = _X1 << 8;
	_y1 = _Y1 << 8;
}

// TO DO - use custom fonts for '+', return also XCHf, YCHf
//
// determine crosshair coord (col, row)
// and show-it
//
void get_cross_coord(void)
{
	if (X1 >= X0)
		colCH = colX1 + 1;
	else
		colCH = colX1 - 1;

	if (Y1 >= Y0)
		rowCH = rowY1 + 1;	
	else
		rowCH = rowY1 - 1;

	if (colCH == 0 || colCH == 63 || rowCH == 0 || rowCH == 45)
	{
		colCH = 32;
		rowCH = 24;
	}

	XCHf = YCHf = 4;
	Load_CH(XCHf, YCHf);
	
	PrintChar(rowCH, colCH, 0x4B);
}

void move_up_ch(void)
{
	if (YCHf == 7)
	{
		if (rowCH < 45 && ((rowCH + 1 != rowY0) || (colCH != colX0)) && ((rowCH + 1 != rowY1) || (colCH != colX1)))
		{
			rowCH = rowCH + 1;
			YCHf = 0;
		}
	}
	else
		YCHf++;
}

void move_down_ch(void)
{
	if (YCHf == 0)
	{
		if (rowCH > 1 && ((rowCH - 1 != rowY0) || (colCH != colX0)) && ((rowCH - 1 != rowY1) || (colCH != colX1)))
		{
			rowCH = rowCH - 1;
			YCHf = 7;
		}
	}
	else
		YCHf--;
}

void move_left_ch(void)
{
	if (XCHf == 0)
	{
		if (colCH > 1 && ((colCH - 1 != colX0) || (rowCH != rowY0)) && ((colCH - 1 != colX1) || (rowCH != rowY1)))
		{
			colCH = colCH - 1;
			XCHf = 7;
		}
	}
	else
		XCHf--; 
}

void move_right_ch(void)
{
	if (XCHf == 7)
	{
		if (colCH < 62 && ((colCH + 1 != colX0) || (rowCH != rowY0)) && ((colCH + 1 != colX1) || (rowCH != rowY1)))
		{
			colCH = colCH + 1;
			XCHf = 0;
		}
	}
	else
		XCHf++;
}

//returns 1 if CR was hit
char MoveCH(char dir)
{
	PrintChar(rowCH, colCH, ' ');

	switch (dir)
	{
	case 'x':	move_down_ch(); break;
	case 'e':	move_up_ch(); break;
	case 's':	move_left_ch(); break;
	case 'd':	move_right_ch(); break;
	default:	break;
	}

	Load_CH(XCHf, YCHf);
	
	PrintChar(rowCH, colCH, 0x4B);

	return (dir == 0xD) ? 1 : 0;
}

int tofp(int x, int y)
{
	int intp, modulo;

	if (x < y)
		return xdivytofp(x, y);

	intp = (x / y) << 8;

	modulo = x % y;

	if (modulo == 0)
		return intp;
	else
		return intp + xdivytofp(modulo, y);
}

int vxdivytofp(long x, long y)
{
	if ((x & 0xFFFF0000) || (y & 0xFFFF0000))
		return xdivytofp((int)(x >> 16), (int)(y >> 16));
	else
		return xdivytofp((int)(x & 0xFFFF), (int)(y & 0xFFFF));
}

int ltofp(long x, long y)
{
	long lintp;
	long modulo;
	int intp;

	if (x < y)
		return vxdivytofp(x, y);

	lintp = x / y;
	intp = (int)(lintp & 0xFFFF);
	modulo = x - y * lintp;

	if (modulo == 0)
		return (intp << 8);
	else
		return (intp << 8) + vxdivytofp(modulo, y);
}

//
// Compute distance from a point(xp,yp) to a line(x1,y1,x2,y2)
// x2+x2f/8,y2+y2f/8
int DistanceTo(int xp, int yp, int x1, int y1, int x2, int x2f, int y2, int y2f)
{
	int a = 8*y1 - 8*y2 - y2f;
	int b = 8*x2 + x2f - 8*x1;
	int c = x1*(8*y2 + y2f) - (8*x2 + x2f)*y1;
	int f;
	long ff;
	long tmp;
	long aprox;
	int dd;

	f = abs(a*xp + b*yp + c);
	ff = (long)f*(long)f;
	tmp = (long)a*(long)a + (long)b*(long)b;

	aprox = ff / tmp;	//try rough estimate...

	if (aprox > 4)		//distance > 2
		return 0x201;
				//distance < 2, compute-it
	dd = ltofp(ff, tmp);

	return fpsqrt(dd);
}

//
// Compute the X coordinate of the intersection of the perpendicular from a point(xp,yp) on a line(x1,y1,x2,y2)
// x2+x2f/8,y2+y2f/8
int Xper(int xp, int yp, int x1, int y1, int x2, int x2f, int y2, int y2f)
{
	int a = 8*y1 - 8*y2 - y2f;
	int b = 8*x2 + x2f - 8*x1;
	int c = x1*(8*y2 + y2f) - (8*x2 + x2f)*y1;
	int tmp;
	long s;

	tmp = a*a + b*b;
	s = (long)b*(long)b*(long)xp - (long)a*(long)b*(long)yp - (long)a*(long)c;

	return ltofp(s, (long)tmp);
}

//
// Compute the Y coordinate of the intersection of the perpendicular from a point(xp,yp) on a line(x1,y1,x2,y2)
// x2+x2f/8,y2+y2f/8
int Yper(int xp, int yp, int x1, int y1, int x2, int x2f, int y2, int y2f)
{
	int a = 8*y1 - 8*y2 - y2f;
	int b = 8*x2 + x2f - 8*x1;
	int c = x1*(8*y2 + y2f) - (8*x2 + x2f)*y1;
	int tmp;
	long s;

	tmp = a*a + b*b;
	s = (long)a*(long)a*(long)yp - (long)a*(long)b*(long)xp - (long)b*(long)c;

	return ltofp(s, (long)tmp);
}

//
// compute angle for vector [(xa,ya),(xb,yb)]
//
int ComputeAngle(int xa, int ya, int xb, int yb)	//fixed point
{
	int tan;

	if (yb == ya)
	{
		if (xb > xa)
			angle = 0;
		else
			angle = PI;
	}
	else if (xb == xa)
	{
		if (yb > ya)
			angle = halfPI;
		else
			angle = PI + halfPI;
	}
	else
	{
		tan = div(yb - ya, xb - xa);

		if (tan < 0)
			tan = neg(tan);

		angle = arctan(tan);

		if (xb < xa)
		{
			if (yb < ya)
				angle = angle + PI;
			else
				angle = PI - angle;
		}
		else
		{
			if (yb < ya)
				angle = twoPI - angle;
		}
	}

	return angle;
}

void fixedtoa(int fp, char* buf)
{
	char tmpbuf[8];
	int decpart = fp & 0xFF;
	int decval = 0;

	sprintf(buf, "%d", fp >> 8);
	
	if (decpart & 0x80)
		decval += 5000;

	if (decpart & 0x40)
		decval += 2500;

	if (decpart & 0x20)
		decval += 1250;

	if (decpart & 0x10)
		decval += 625;

	if (decpart & 0x08)
		decval += 312;

	if (decpart & 0x04)
		decval += 156;

	if (decpart & 0x02)
		decval += 78;

	if (decpart & 0x01)
		decval += 39;

	if (decval)
	{
		sprintf(tmpbuf, ".%d", decval);
		strcat(buf, tmpbuf);
	}
}

int main(int argc, char** argv)
{
	char ch;

	TrainingMode = (argc > 1) ? 1 : 0;

	CrtSetup();
	xrndseed();

	Save_0_to_11();
	Load_0_to_10(); //load fonts for the white ball

	Clear();
	printf("the little game of pool\r\n\n");
	printf("your job is to aim (using the crosshair '+') and hit the @ ball\r\n");
	printf(" with the A ball, with an appropriate force, in order\r\n");
	printf(" to push it into one of the 6 available pockets...\r\n\n");
	printf("the balls will bounce back when hitting the rim,\r\n");
	printf(" and will collide according to the laws of physics\r\n");
	printf("also, friction will slow their movement speed\r\n\n");

	if (TrainingMode)
		printf("you are in the training mode...\r\n");

	printf("hit any key to start:");
	CrtIn();

	SetCursor();

	get_balls_coord();	//set balls positions
train:
	X0 = _X0;
	Y0 = _Y0;
	X1 = _X1;
	Y1 = _Y1;
	x0 = _x0;
	y0 = _y0;
	x1 = _x1;
	y1 = _y1;

	show_boundaries();	//clear screen, show boundaries

	PrintChar(VirtualToRealRow(Y0), X0/2, 0x41);
	PrintChar(VirtualToRealRow(Y1), X1/2, 0x40);
again:
	colX0 = X0 / 2;
	rowY0 = VirtualToRealRow(Y0);
	colX1 = X1 / 2;
	rowY1 = VirtualToRealRow(Y1);

	get_cross_coord();	//set crosshair coord
				//returns XCH, XCHf, YCH, YCHf

	moving_ball = WHITE;	
	collision_exp = 0;	// collision not (yet) detected

	PrintStr(47, 0,"q=quit or aim (s=left,d=right,x=down,e=up) then hit <cr>");
	
	ch = CrtIn();
	
	if (ch == 'q')
		goto quit;
	
	do
	{
		if (MoveCH(ch))
			break;
		
		ch = CrtIn();
	}
	while (1);

	XCH = colCH * 2 + 1;
	XCHfp = (XCH << 8) + (XCHf * 0x20);

	YCH = RealToVirtualRow(rowCH) + 1;
	YCHfp = (YCH << 8) + (YCHf * 0x20); 

	ClearTopLine();
	fixedtoa(XCHfp, buftmp1);
	fixedtoa(YCHfp, buftmp2);
	sprintf(buf, "aim point coord:x=%s y=%s;hit any key", buftmp1, buftmp2);
	PrintStr(47, 0, buf);
	CrtIn();

	do
	{
		ClearTopLine();
		PrintStr(47, 0, "hit force? (1=smallest, 25=highest):");
		SetCursor();
		getstr(buf);
		ClearTopLine();
		speed = atoi(buf);
	}
	while (speed == 0 || speed > 25);

	PrintChar(0,0,REV_BLANK);
	init_counter = counter = 26 - speed; 	//set up speed control
	brake_counter = 10;			//set up brake control

	PrintChar(rowCH, colCH, ' ');	//erase crosshairs

	angle = ComputeAngle(x0, y0, XCHfp, YCHfp);	//compute initial ball movement angle

recompute:

	xstart = x0;
	ystart = y0;

	//compute distance from the target ball center to the movement vector
	distance = DistanceTo(X1, Y1, X0, Y0, XCH, XCHf, YCH, YCHf);

	if (distance < 0x1E0)
	{
		collision_exp = 1; //collision expected, compute impact point

		// impacted ball will move along (xp,yp) (X1,Y1) vector
		// where the speed at collision will be the speed of the moving ball
		// when aprox distance between balls become < 3

		if (distance < 0x020) //approximate for small distances...
		{	
			// keep same angle and speed
			keep_speed = 1;
			xp = x0;
			yp = y0;
		}
		else
		{
			// compute collision parameters
			keep_speed = 0;

			xper = Xper(X1, Y1, X0, Y0, XCH, XCHf, YCH, YCHf);
			yper = Yper(X1, Y1, X0, Y0, XCH, XCHf, YCH, YCHf);

			ddelta = fpsqrt(0x400 - mul(distance, distance));

			xp = xper - mul(ddelta, cos(angle));
			yp = yper - mul(ddelta, sin(angle));

			alpha = arctan(div(distance, ddelta));	// the angle between the two vectors

			if (angle < ComputeAngle(x0, y0, x1, y1))
			{
				new_angle = angle + alpha;
				if (new_angle > twoPI)
					new_angle = new_angle - twoPI;
			}
			else
			{
				new_angle = angle - alpha;
				if (new_angle < 0)
					new_angle = twoPI + new_angle;
			}

			// impacted ball initial speed = speed * cos(alpha)
			// moving at new angle = angle +- alpha
			// where the speed will be the speed of the moving ball when distance between balls become < 3
		}
	}
	else
	{
		// no direct impact, continue moving the ball; 
		// at first bounce back impact, use impact coord as start coord
		// with angle being recomputed
			
		collision_exp = 0;
	}

	do
	{
		status = move_ball();

		if (status == BOUNCED)
		{
			if (moving_ball == WHITE)
				goto recompute;
		}
		else if (status == STOPPED)
		{
			Load_0_to_10(); //load fonts for the white ball
			PrintChar(VirtualToRealRow(Y0), X0/2, 0x41);
			PrintChar(VirtualToRealRow(Y1), X1/2, 0x40);

			if (TrainingMode)
			{
				ClearTopLine();
				PrintStr(47, 0, "hit any key...");
				CrtIn();
				goto train;
			}
			else
				goto again;
		}
		else if (status == BASKET)
		{
			hide(int_part(xold), int_part(yold));

			ClearTopLine();

			if (moving_ball == BLACK)
				PrintStr(47,0,"well done, target ball dropped to pocket! hit any key...");
			else
				PrintStr(47,0,"bad luck, wrong ball dropped to pocket! hit any key...");

			CrtIn();
			goto quit;
		}
	}
	while (1);
quit:
	Clear();
	Restore_0_to_11();
	exit(0);
}

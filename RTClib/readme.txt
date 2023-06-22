DS1302 real time clock support library

Can be called from C or assembler

void	InitRTC(void); 	/* writes 00:00:00 to the top-right corner of the screen */
			/* current cursor position on screen NOT affected */

long	GetTime(void); 	/* writes HH:MM:SS to the top-right corner of the screen */
			/* current cursor position on screen NOT affected */
			/* returns E = seconds, D = minutes, L = hours, H = 0 */

void	GetStartTime(void);
void	GetStopTime(void);
void	PrintLapseTime(void);	/* writes (StopTime - StartTime) as HH:MM:SS */
				/* at the current cursor position on screen */

Use ZAS (Z80AS) to assemble the library

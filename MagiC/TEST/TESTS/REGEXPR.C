/*********************************************************************
*
* Dieses Modul enth�lt die Pattern-Match-Routine.
*
*********************************************************************/

#include <tos.h>
#include <tosdefs.h>
#include <string.h>

#define TRUE   1
#define FALSE  0
#define EOS    '\0'
#define NULL        ( ( void * ) 0L )


/*********************************************************************
*
*  Meine "toupper" mit Ber�cksichtigung von Umlauten.
*
*********************************************************************/

#pragma warn -pia
char toupper( unsigned char c )
{
	register char *s;
	static char lower_s[] = "��������������";
	static char upper_s[] = "��������������";

	if	(c < 'a')
		return(c);
	if	(c <= 'z')
		return(c & 0x5f);
	if	(!(s = strchr(lower_s, c)))
		return(c);
	return(upper_s[s - lower_s]);
}
#pragma warn +pia


/*********************************************************************
*
* Wandelt eine Zeichenkette in Gro�schrift um.
*
*********************************************************************/

void upperstring( char *s )
{
	while(*s)
		*s++ = toupper(*s);
}


/*********************************************************************
*
* Pattern-Match-Routine.
* vollst�ndige regul�re Ausdr�cke mit Rekursion.
*
*********************************************************************/

int pattern_match(char *pattern, char *fname)
{
	/* solange beide Zeichenketten nicht leer sind */

	while((*pattern) && (*fname))
		{
		if	(*pattern == '*')
			{
			/* erst unwahrscheinlicheren Fall als Rekursion */
			if	(pattern_match(pattern+1, fname))
				return(TRUE);
			fname++;
			continue;
			}
		if	((*pattern == '?') || (toupper(*fname) == *pattern))
			{
			pattern++;
			fname++;
			continue;
			}
		return(FALSE);
		}

	/* jetzt ist mindesten eine Zeichenkette leer */

	if	((*pattern) == (*fname))
		return(TRUE);		/* beide EOS */

	/* jetzt ist genau eine Zeichenkette leer */

	if	(*fname)
		return(FALSE);		/* pattern leer, fname nicht */

	/* jetzt ist pattern nicht leer, fname ist leer */

	while((*pattern) == '*')
		pattern++;
	return(!(*pattern));	/* OK, wenn nur '*'e �brig */
}

void readline(char *s, int len);

int main( void )
{
	char pattern[128],fname[128];


	Cconws("\r\nMuster: ");readline(pattern, 127);
	upperstring(pattern);
	Cconws("\r\n => ");
	Cconws(pattern);
	Cconws("\r\n");

	for	(;;)
		{
		Cconws("\r\nTestdatei: ");readline(fname, 127);
		if	(pattern_match(pattern, fname))
			Cconws("\r\n => Match\r\n");
		else	Cconws("\r\n => Mismatch\r\n");
		}
}


void readline(char *s, int len)
{
	long ret;

	ret = Fread(STDIN, (long) len, s);
	if	(ret < 0)
		Pterm((int) ret);
	s[ret] = '\0';
}

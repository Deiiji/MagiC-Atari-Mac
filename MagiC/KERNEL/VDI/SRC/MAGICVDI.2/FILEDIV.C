/*
	Tabulatorweite: 3
	Kommentare ab: Spalte 60											*Spalte 60*
*/

#include <PORTAB.H>

#include <FILEDIV.H>
#include "MEMORY.H"
#include "TOS.H"

/* vereinfachte Variante von FILEDIV.C */

/*----------------------------------------------------------------------------------------*/
/* ben”tigte externe Funktionen																				*/
/*----------------------------------------------------------------------------------------*/
extern	void	*Malloc_sys( int32 len );							/* Funktion fr Speicheranforderung */
extern	int16	Mfree_sys( void *addr );							/* Funktion fr Speicherfreigabe */

/*----------------------------------------------------------------------------------------*/
/* Atari-Datei laden																								*/
/* Der Speicher fr die Datei wird mit Malloc_sys angefordert										*/
/* Funktionsresultat:	Zeiger auf die Datei oder 0L (Fehler)										*/
/* name:						absoluter Pfad mit Dateinamen													*/
/* length:					Zeiger auf Langwort fr die Dateil„nge										*/
/*----------------------------------------------------------------------------------------*/
void *load_file( int8 *name, int32 *length )
{
	#define	LF_FLAGS	FA_READONLY + FA_HIDDEN + FA_SYSTEM + FA_ARCHIVE	/* Flags fr Fsfirst() */

	void	*addr;
	DTA	dta;
	DTA	*old_dta;

	addr = 0L;
	
	old_dta = Fgetdta();													/* Adresse der bisherigen DTA */
	Fsetdta( &dta );														/* neue DTA setzen */
	
	if ( Fsfirst( name, LF_FLAGS ) == 0 )							/* Datei vorhanden? */
	{
		if (( addr = Malloc_sys( dta.d_length )) != 0 )			/* Speicher anfordern	*/	
		{
			*length = read_file( name, addr, 0L, dta.d_length );
			
			if  ( *length != dta.d_length )							/* Datei unvollst„ndig?	*/
			{
				Mfree_sys( addr );
				addr = 0L;
			}
		}
	}
	Fsetdta( old_dta );													/* alte DTA setzen */
	
	return( addr );														/* Adresse zurckgeben */

	#undef	LF_FLAGS
}

/*----------------------------------------------------------------------------------------*/
/* Atari-Dateiabschnitt laden																					*/
/* Funktionsresultat:	L„nge der eingelesenen Daten													*/
/* name:						Name der Datei																		*/
/*	dest:						Zieladresse der Daten															*/
/*	offset:					Abstand vom Anfang der Datei													*/
/*	len:						L„nge der einzulesenden Daten													*/
/*----------------------------------------------------------------------------------------*/
int32	read_file( int8 *name, void *dest, int32 offset, int32 len )
{
	int32	handle;
	int32	read;
	
	read = 0;
	handle = Fopen( name, FO_READ );									/* Datei ”ffnen */
	if ( handle > 0 )														/* Datei offen? */
	{
		Fseek( offset, (int16) handle, 0 );							/* Position relativ zum Dateianfang	*/
		read = Fread((int16) handle, len, dest );					/* Daten einlesen */
		Fclose((int16) handle );										/* Datei schliežen */
	}

	return( read );														/* Anzahl der eingelesenen Bytes */
}


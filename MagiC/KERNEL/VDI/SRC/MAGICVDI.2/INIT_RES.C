#include	"LANGUAGE.H"

#include	<PORTAB.h>
#include <stdio.h>
#include <stddef.h>
#include	<stdlib.h>

#include	"MEMORY.H"
#include	"STRING.H"
#include	"TOS.H"
#include	"DRIVERS.H"
#include	"NVDI_WK.H"
#include	"VDI.H"
#include	"FILEDIV.H"

#include	"INIT_RES.H"

extern	void	*load_prg( BYTE *name );

/*----------------------------------------------------------------------------------------*/
/* Bildschirmtreiber fÅr den Macintosh laden																*/
/* Funktionsresultat:	Zeiger auf den Treiberstart oder 0L											*/
/*	pm:						Zeiger auf die PixMap des Bildschirms										*/
/*	gdos_path:				Pfad, in dem der Treiber gesucht werden muû								*/
/*----------------------------------------------------------------------------------------*/
void	*load_MAC_driver( VDI_DISPLAY *display, BYTE *gdos_path )
{
	BYTE	name[128];
	
	strgcpy( name, gdos_path );

	switch ((int) display->bm.bits )
	{
		case	1:		strgcat( name, "MFM2.SYS" );		break;
		case	2:
		{
			if ( display->bm.px_format == PX_ATARI2 )				/* 4 Farben, 640 * 200 KompatibilitÑtsmodus? */
				strgcat( name, "MFM4IP.SYS" );
			else
				strgcat( name, "MFM4.SYS" );
			
			break;
		}
		case	4:
		{
			if ( display->bm.px_format == PX_ATARI4 )				/* 16 Farben 320 * 200 KompatibilitÑtsmodus? */
				strgcat( name, "MFM16IP.SYS" );
			else
				strgcat( name, "MFM16.SYS" );

			break;
		}
		case	8:		strgcat( name, "MFM256.SYS" );	break;
		case	16:	strgcat( name, "MFM32K.SYS" );	break;
		case	32:	strgcat( name, "MFM16M.SYS" );	break;
	}
	
	return( load_prg( name ));
}
		
/*----------------------------------------------------------------------------------------*/
/* Bildschirmtreiber fÅr den Atari laden																	*/
/* Funktionsresultat:	Zeiger auf den Treiberstart oder 0L											*/
/*	res:						Xbios-Auflîsung (sshiftmd)														*/
/*	modecode:				Moduswort fÅr den Falcon														*/
/*	gdos_path:				Pfad, in dem der Treiber gesucht werden muû								*/
/*----------------------------------------------------------------------------------------*/
void	*load_ATARI_driver( WORD res, WORD modecode, BYTE *gdos_path )
{
	BYTE	name[128];
	
	strgcpy( name, gdos_path );
	
	switch ( res )
	{
		case	0:		strgcat( name, "MFA16.SYS" );		break;	/* ST-niedrig */
		case	1:		strgcat( name, "MFA4.SYS" );		break;	/* ST-mittel */
		case	2:		strgcat( name, "MFA2.SYS" );		break;	/* ST-hoch */
		case	3:		switch( modecode & 7 )							/* Falcon	*/
						{
							case	0:	strgcat( name, "MFA2.SYS" );		break;
							case	1:	strgcat( name, "MFA4.SYS" );		break;
							case	2:	strgcat( name, "MFA16.SYS" );		break;
							case	3:	strgcat( name, "MFA256.SYS" );	break;
							case	4:	strgcat( name, "MFA32K.SYS" );	break;
							
							default:	strgcat( name, "MFA2.SYS" );
						}
						break;
		case	4:		strgcat( name, "MFA16.SYS" );		break;	/* TT-mittel */
		case	6:		strgcat( name, "MFA2.SYS" );		break;	/* TT-hoch */
		case	7:		strgcat( name, "MFA256.SYS" );	break;	/* TT-niedrig */
		
		default:		strgcat( name, "MFA2.SYS" );
	}
	return( load_prg( name ));
}
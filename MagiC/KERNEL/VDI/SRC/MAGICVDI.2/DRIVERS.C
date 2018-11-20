/*
	Tabulatorweite: 3
	Kommenatare ab: Spalte 60											*Spalte 60*
*/

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

#define	OFFSCREEN_ptr OSC_ptr
#define	OFFSCREEN_count OSC_count

extern	BYTE	gdos_path[128];
extern	DRIVER	*OFFSCREEN_ptr;
extern	WORD		OFFSCREEN_count;
extern	NVDI_STRUCT	nvdi_struct;

#define MAX_HANDLE 128

extern	WK closed;
extern	WK *wk_tab[MAX_HANDLE];

extern	void	wk_init( DEVICE_DRIVER *dev, DRIVER *off, WK *wk );
extern	void	clear_bitmap( WK *wk );
extern	void	transform_bitmap( MFDB *src, MFDB *des, WK *wk );

extern	void	clear_cpu_caches( void );

WORD	init_NOD_drivers( void );
WORD	init_offscreen_drivers( BYTE *tmp_path );
DRIVER	*load_NOD_driver( ORGANISATION *info );
WORD	unload_NOD_driver( DRIVER *drv );
void	*load_prg( BYTE *name );
extern	void	*init_mono_NOD( DRVR_HEADER *head );
WORD	load_mono_NOD( void );

WK		*create_bitmap( DEVICE_DRIVER *device_driver, WK *dev_wk, MFDB *m, WORD *intin );
WORD	delete_bitmap( WK *wk );
WK		*create_wk( LONG wk_len );
WORD	delete_wk( WK *wk );

/*----------------------------------------------------------------------------------------*/
/* Offscreen-Treiber im Ordner gdos_path scannen					 									*/
/*	Da sowohl OSD- als auch NOD-Treiber gesucht werden, kann fÅr ein Bitformat mehr als 	*/
/*	ein Treiber vorhanden sein. Das ist jedoch unkritisch, da init_offscreen_drivers die	*/
/*	Treiber rÅckwÑrts einsortiert, d.h. der letzte gefundene Treiber ist der erste in der	*/
/*	Liste. Daher werden bevorzugt die OSD-Treiber geladen.											*/
/* Funktionsresultat:	1, wenn alles in Ordnung ist													*/
/*----------------------------------------------------------------------------------------*/
WORD	init_NOD_drivers( void )
{
	BYTE	tmp_path[256];

	OFFSCREEN_count = 0;
	OFFSCREEN_ptr = 0L;

	strgcpy( tmp_path, gdos_path );
	strgcat( tmp_path, "*.NOD" );
	init_offscreen_drivers( tmp_path );								/* alle NOD-Treiber suchen */

	strgcpy( tmp_path, gdos_path );
	strgcat( tmp_path, "*.OSD" );
	init_offscreen_drivers( tmp_path );								/* alle OSD-Treiber suchen */
	
	if ( load_mono_NOD() == 0 )										/* monochromer Treiber vorhanden? */
		return( 0 );

	if ( OFFSCREEN_count == 0 )										/* sind Åberhaupt Treiber vorhanden? */
		return( 0 );

	return( 1 );
}

WORD	init_offscreen_drivers( BYTE *tmp_path )
{
	DTA 	dta;
	DTA	*old_dta;

	old_dta = Fgetdta();
	Fsetdta( &dta );

	if ( Fsfirst( tmp_path, 0 ) == 0 )	/* Datei gefunden */
	{
		do
		{
			BYTE	name[256];
			DRVR_HEADER	head;
			
			strgcpy( name, gdos_path );
			strgcat( name, dta.d_fname );

			read_file( name, (UBYTE *) &head, sizeof( PH ),  + sizeof( DRVR_HEADER ));	/* Treiberheader laden */

			if (( strgcmp( head.magic, OFFSCREEN_MAGIC ) == 0 ) && ( head.version > 0x280 ))
			{
				DRIVER	*drv;
				
				if (( drv = Malloc_sys( sizeof( DRIVER ))) != 0 )		/* Speicher fÅr Treiberstruktur anfordern */
				{

					strgcpy( drv->file_name, dta.d_fname );
					drv->file_size = dta.d_length;
					drv->file_path = gdos_path;
					
					drv->info = head.info;
					drv->used = 0;
					drv->code = 0L;

					drv->next = OFFSCREEN_ptr;
					OFFSCREEN_ptr = drv;
					OFFSCREEN_count++;
				}
			}
		} while ( Fsnext() == 0 );
	}

	Fsetdta( old_dta );

	return( 1 );
}

WORD	load_mono_NOD( void )
{
	ORGANISATION	info = { 2, 1, 2, 1, 0, 0, 0 };
	DRIVER	*drv;

	drv = load_NOD_driver( &info );
	
	if ( drv )
	{
		init_mono_NOD( drv->code );
		return( 1 );
	}
	return( 0 );
}

/*----------------------------------------------------------------------------------------*/
/* Offscreen-Treiber laden													 									*/
/* Funktionsresultat:	Zeiger auf die Treiberstruktur oder 0										*/
/* info:						Zeiger auf die Treiberbeschreibung											*/
/*----------------------------------------------------------------------------------------*/
DRIVER	*load_NOD_driver( ORGANISATION *info )
{
	DRIVER	*drv;

	drv = OFFSCREEN_ptr;
	
	while ( drv )
	{
		/* öbereinstimmende Merkmale ÅberprÅfen */
		if (( drv->info.colors == info->colors ) && ( drv->info.planes == info->planes ) &&
			 ( drv->info.format == info->format ) && (( drv->info.flags & info->flags ) == info->flags ))
		{
			if ( drv->code == 0L )
			{
				BYTE	name[256];
				
				strgcpy( name, drv->file_path );
				strgcat( name, drv->file_name );
			
				drv->code = (DRVR_HEADER *) load_prg( name );
			}
				
			if ( drv->code )	/* Treiber geladen? */
			{
				if ( drv->used == 0 )	/* ist der Treiber das erste Mal geladen worden? */
					drv->wk_len = drv->code->init( (void *)&nvdi_struct );	/* dann initialisieren */
				
				drv->used++;
				return( drv );
			}
		}	
		drv = drv->next;
	}
	return( 0L );
}

/*----------------------------------------------------------------------------------------*/
/* Offscreen-Treiber freigeben											 									*/
/* Funktionsresultat:	1																						*/
/* drv:						Zeiger auf die Treiberstruktur												*/
/*----------------------------------------------------------------------------------------*/
WORD	unload_NOD_driver( DRIVER *drv )
{
	drv->used--;
	
	if ( drv->used == 0 )	/* Treiber nicht mehr benutzt? */
	{
		Mfree_sys( drv->code );	/* Speichr freigeben */
		drv->code = 0L;	
	}
	return( 1 );
}

/*----------------------------------------------------------------------------------------*/
/* Programm-Datei laden und relozieren									 									*/
/* Funktionsresultat:	Zeiger auf den Programmstart oder 0											*/
/* name:						Zeiger auf den kompletten Pfad mit Namen									*/
/*----------------------------------------------------------------------------------------*/
void	*load_prg( BYTE *name )
{
	DTA 	dta;
	DTA	*old_dta;
	void	*addr;

	addr = 0L;

	old_dta = Fgetdta();
	Fsetdta( &dta );

	if ( Fsfirst( name, 0 ) == 0 )
	{
		LONG	handle;
		
		handle = Fopen( name, FO_READ );
		if ( handle > 0 )
		{
			PH	phead;
			
			/* Programmheader laden */
			if ( Fread( (WORD) handle, sizeof( PH ), &phead ) == sizeof( PH ))
			{
				if ( phead.ph_branch == PH_MAGIC )	/* bra.s am Anfang? */
				{
					LONG	len;
					
					len = dta.d_length + phead.ph_blen - phead.ph_slen;	/* anzufordernder Speicher	*/
				
					if (( addr = Malloc_sys( len )) != 0 )
					{
						LONG	TD_len;
						LONG	TDB_len;
						
						TD_len = phead.ph_tlen + phead.ph_dlen;	/* LÑnge von Text- und Data-Segment */
						TDB_len = TD_len + phead.ph_blen;	/* LÑnge von Text-, Data- und BSS-Segment */

						if ( Fread( (WORD) handle, TD_len, addr ) == TD_len )	/* Code und Daten laden */
						{
							UBYTE	*relo;
							LONG	relo_len;
							
							Fseek( phead.ph_slen, (WORD) handle, 1 );	/* Symboltabelle Åberspringen */
							clear_mem( phead.ph_blen, ((BYTE *) addr ) + TD_len );	/* BSS-Segment lîschen */
							
							relo = ((UBYTE *) addr ) + TDB_len;	/* Zeiger auf die Relokationsdaten */
							
							relo_len = dta.d_length - sizeof( PH ) - phead.ph_tlen - phead.ph_dlen - phead.ph_slen;	/* LÑnge der Relokationsdaten */
							if ( Fread( (WORD) handle, relo_len, relo ) == relo_len )
							{
								LONG	relo_offset;
								
								relo_offset = *(LONG *)relo;	/* Startoffset fÅr Relokationsdaten */
								relo += 4;
								if ( relo_offset )	/* Relokationsdaten vorhanden? */
								{
									UBYTE	*code_ptr;
									UBYTE	relo_val;

									code_ptr = ((UBYTE *) addr ) + relo_offset;	/* erstes zu relozierendes Langwort */
									*(ULONG *)code_ptr += (ULONG) addr;
									
									while (( relo_val = *relo++ ) != 0 )
									{
										if ( relo_val == 1 )	
											code_ptr += 254;
										else
										{
											(UBYTE *)code_ptr += relo_val;
											*(ULONG *)code_ptr += (ULONG) addr;
										}
									}
								}
								Mshrink_sys( addr, TDB_len );		/* Speicher fÅr Relokationsdaten freigeben */
							}
							else
							{
								Mfree_sys( addr );
								addr = 0L;
							}
						}
						else
						{
							Mfree_sys( addr );
							addr = 0L;
						}
					}
				}
			}
			Fclose( (WORD) handle );
		}
	}
	Fsetdta( old_dta );

	if ( addr )																/* Programm geladen? */
		clear_cpu_caches();												/* Caches lîschen */

	return( addr );
}

/*----------------------------------------------------------------------------------------*/
/* Offscreen-Treiber laden, Workstation îffnen und initialisieren	und ggf. Speicher fÅr	*/
/* die Bitmap anfordern.																						*/
/*																														*/
/* Funktionsresultat:	Zeiger auf die Workstation oder 0L											*/
/* device_driver:			Zeiger auf die Struktur des GerÑtetreibers, dessen Handle bei		*/
/*								v_opnbm() Åbergeben wurde														*/
/* dev_wk:					Zeiger auf die zum GerÑtetreiber gehîrende Workstation				*/
/* m:							Zeiger auf den MFDB der Bitmap												*/
/* intin:					intin-Array wie es bei v_opnbm() vorliegt									*/
/*----------------------------------------------------------------------------------------*/
WK	*create_bitmap( DEVICE_DRIVER *device_driver, WK *dev_wk, MFDB *m, WORD *intin )
{
	WK *wk;
	DRIVER	*drv;
	ORGANISATION	info;

	wk = 0L;
	
	info.colors = *(LONG *)(intin + 15);
	info.planes = intin[17];
	info.format = intin[18];
	info.flags = intin[19];
	info.reserved[0] = 0;
	info.reserved[1] = 0;
	info.reserved[2] = 0;
	
	if ( info.colors == 0 ) /* keine spezielle Organisation definiert? */
	{
		if (( m->fd_nplanes == 0 ) ||
			 ( m->fd_nplanes == device_driver->addr->info.planes ))	/* Organisation wie der Bildschirmtreiber? */
			info = device_driver->addr->info;
		else
			info.planes = 1;
	}

	if ( info.planes == 1 )					/* monochrom? */
	{
		info.colors = 2;
		info.format = 2;
		info.flags = 1;
	}

	drv = load_NOD_driver( &info );		/* Offscreen-Treiber laden und initialisieren */

	if ( drv )
	{
		wk = create_wk( drv->wk_len );	/* Workstation anlegen */
		
		if ( wk )
		{
			wk->bitmap_info = info;							/* Bitmap-Beschreibung setzen */
			wk_init( (DEVICE_DRIVER *) 0L, drv, wk );	/* Workstation initialisieren */
						
			if ( intin[11] )					/* wurde die Bitmap-Grîûe angegeben? */
			{
				wk->res_x = intin[11];
				wk->res_y = intin[12];
			}
			else
			{										/* Bitmap-Grîûe des Bildschirms Åbernehmen */
				wk->res_x = dev_wk->res_x;
				wk->res_y = dev_wk->res_y;
			}
			if ( intin[13] )					/* wurde die Pixel-Grîûe angegeben? */
			{
				wk->pixel_width = intin[13];
				wk->pixel_height = intin[14];
			}
			else
			{
				wk->pixel_width = dev_wk->pixel_width;
				wk->pixel_height = dev_wk->pixel_height;
			}

			wk->bitmap_dx = (( wk->res_x + 16 ) & 0xfff0 ) - 1;
			wk->bitmap_dy = wk->res_y;
			wk->clip_xmax = wk->res_x;
			wk->clip_ymax = wk->res_y;
			wk->bitmap_width = (WORD) ((LONG) (wk->res_x + 1) * (wk->planes + 1) / 8 );
			wk->bitmap_len = (LONG) wk->bitmap_width * (wk->res_y + 1 );
			wk->bitmap_drvr = drv;
			
			if ( m->fd_addr == 0L )					/* wurde kein Speicherblock Åbergeben? */
			{
				m->fd_w = wk->res_x + 1;
				m->fd_h = wk->res_y + 1;
				m->fd_nplanes = wk->planes + 1;
				m->fd_stand = 0;
				m->fd_wdwidth = wk->bitmap_width / ( wk->planes + 1) / 2 ;
				m->fd_addr = Malloc_sys( wk->bitmap_len );

				wk->bitmap_addr = m->fd_addr;
				if ( m->fd_addr )						/* Speicher vorhanden? */
				{
					wk->bitmap_info.flags |= 0x8000;	/* Bitmap wurde alloziert */
					clear_bitmap( wk );				/* Bitmap lîschen */
				}
				else
				{
					unload_NOD_driver( drv );		/* Offscreen-Treiber entfernen */
					delete_wk( wk );					/* Workstation lîschen */
					return( 0L );
				}
			}
			else
			{
				wk->bitmap_addr = m->fd_addr;
				wk->bitmap_width = m->fd_wdwidth * 2 * m->fd_nplanes;
				if ( m->fd_stand )					/* Standardformat? */
				{
					MFDB	des;
					
					des = *m;
					des.fd_stand = 0;
					
					des.fd_addr = Malloc_sys( wk->bitmap_len );
					
					if ( des.fd_addr )
					{
						transform_bitmap( m, &des, wk );
						copy_mem( wk->bitmap_len, des.fd_addr, m->fd_addr );
					}
					else
					{
						des.fd_addr = m->fd_addr;					
						transform_bitmap( m, &des, wk );
					}
				}
			}
		}
	}
	return( wk );
}

/*----------------------------------------------------------------------------------------*/
/* Offscreen-Treiber schlieûen, ggf. Speicher fÅr die Bitmap und die Workstation frei-		*/
/* geben.																											*/
/*																														*/
/* Funktionsresultat:	1																						*/
/* wk:						Zeiger auf die	Workstation														*/
/*----------------------------------------------------------------------------------------*/
WORD	delete_bitmap( WK *wk )
{
	unload_NOD_driver( wk->bitmap_drvr );		/* Offscreen-Treiber entfernen */
	if ( wk->bitmap_info.flags & 0x8000 )		/* Speicher freigeben alloziert? */
		Mfree_sys( wk->bitmap_addr );				
	delete_wk( wk );									/* Workstation entfernen */

	return( 1 );
}

/*----------------------------------------------------------------------------------------*/
/* Speicher fÅr eine Workstation anfordern und lîschen, die Workstation in wk_tab ein-		*/
/* tragen und das	Handle in der Workstation vermerken.												*/
/*																														*/
/* Funktionsresultat:	Zeiger auf die Workstation oder 0L											*/
/* wk_len:					LÑnge der Workstation															*/
/*----------------------------------------------------------------------------------------*/
WK	*create_wk( LONG wk_len )
{
	WK 	*wk;
	WORD	handle;
	
	wk = 0L;
	
	for ( handle = 2; handle <= MAX_HANDLE; handle++ )
	{
		if ( wk_tab[handle-1] == &closed )	/* freier Eintrag? */
		{
			wk = Malloc_sys( wk_len );			/* Speicher anfordern */
			
			if ( wk )
			{
				clear_mem( wk_len, wk );		/* lîschen */
				wk->wk_handle = handle;			/* Handle eintragen */
				wk_tab[handle-1] = wk;			/* Eintrag in der Workstation-Tabelle setzen */
			}
			break;	
		}
	}
	return( wk );
}

/*----------------------------------------------------------------------------------------*/
/* Speicher einer Workstation zurÅckgeben	und das Handle freigeben								*/
/*																														*/
/* Funktionsresultat:	1, wenn die Workstation freigegeben werden konnte						*/
/* wk_len:					LÑnge der Workstation															*/
/*----------------------------------------------------------------------------------------*/
WORD	delete_wk( WK *wk )
{
	if ( wk_tab[ wk->wk_handle - 1 ] == wk )
	{
		wk_tab[ wk->wk_handle - 1 ] = &closed;
		Mfree_sys( wk );
		return( 1 );
	}
	return( 0 );
}

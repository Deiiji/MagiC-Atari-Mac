/*
	Tabulatorweite: 3
	Kommentare ab: Spalte 60											*Spalte 60*
*/

#include	"MXVDI.H"
#include	<MAC/QDRAW.H>													/* PixMap-Strukur */

/*----------------------------------------------------------------------------------------*/
/* Struktur fÅr die KompatibilitÑt mit alten MM-Versionen											*/
/*----------------------------------------------------------------------------------------*/
#pragma PRAGMA_PACKED_ALIGN											/* Strukturelemente byteweise anordnen */

typedef struct
{
	int32		magic;														/* ist 'MagC' */
	void		*syshdr;														/* Adresse des Atari-Syshdr */
	void		*keytabs;													/* 5*128 Bytes fÅr Tastaturtabellen */
	int32		ver;															/* Version */
	int16		cpu; 															/* CPU (30=68030, 40=68040) */
	int16		fpu;															/* FPU (0=nix,4=68881,6=68882,8=68040) */
	void		*boot_sp; 													/* sp fÅrs Booten */
	void		*biosinit;													/* nach Initialisierung aufrufen */
	PixMap	*pixmap;														/* Daten fÅrs VDI */
	void		*offs_32k;													/* Adressenoffset fÅr erste 32k im MAC */
	void		*a5;															/* globales Register a5 fÅr Mac-Programm */
	int32		tasksw;														/* != NULL, wenn Taskswitch erforderlich */
	void		*gettime;													/* Datum und Uhrzeit ermitteln */
	void		*bombs;														/* Atari-Routine, wird vom MAC aufgerufen */
	void		*syshalt;													/* "System halted", String in a0 */
	void		*coldboot;
	void		*debugout;													/* fÅrs Debugging */
	void		*prtis;														/* FÅr Drucker (PRT) */
	void		*prtos;
	void		*prtin;
	void		*prtout;
	void		*serconf;													/* Rsconf fÅr ser1 */
	void		*seris;														/*  FÅr ser1 (AUX) */
	void		*seros;
	void		*serin;
	void		*serout;
	void		*xfs;															/* Routinen fÅr das XFS */
	void		*xfs_dev;													/* Zugehîriger Dateitreiber */
	void		*set_physbase;												/* Bildschirmadresse bei Setscreen umsetzen (a0 zeigt auf den Stack von Setscreen()) */
	void		*VsetRGB;													/* Farbe setzen (a0 zeigt auf den Stack bei VsetRGB()) */
	void		*VgetRGB;													/* Farbe erfragen (a0 zeigt auf den Stack bei VgetRGB()) */
	VDI_SETUP_TROUBLE	*error;											/* Fehlermeldung in d0.l an das Mac-System zurÅckgeben */
} OLD_MACSYS;

#pragma PRAGMA_RESET_ALIGN												/* Einstellung zurÅcksetzen */

extern OLD_MACSYS	MSys;													/* fÅr alte MagiCMac-Version importieren (bei neuen nur Dummy) */

/*----------------------------------------------------------------------------------------*/
/* Statische Daten																								*/
/*----------------------------------------------------------------------------------------*/
static VDI_SETUP_DATA	setup;
static VDI_DISPLAY		display;

VDI_SETUP_DATA	*MM_init( VDI_SETUP_DATA *in_setup );

VDI_SETUP_DATA	*MM_init( VDI_SETUP_DATA *in_setup )
{
	if ( in_setup )
	{
		PixMap	*pm;

		if ( in_setup->magic == VDI_SETUP_MAGIC )					/* wurde uns eine VDI_SETUP_DATA-Struktur Åbergeben? */
			return( in_setup );											/* dann mÅssen wir nicht konvertieren */

		pm = (PixMap *) in_setup;										/* altes MagiCMac: Åbergibt Zeiger auf PixMap */

		display.magic = VDI_DISPLAY_MAGIC;
		display.length = sizeof( VDI_DISPLAY );
		display.format = 0;
		display.reserved = 0;
		
		display.next = 0;													/* keine weiteren Monitore */
		display.display_id = 0;
		display.flags = VDI_DISPLAY_ACTIVE;
		display.reserved1 = 0;
		
		display.hdpi = (fixed) pm->hRes;								/* Pixelgrîûe in dpi (16.16) */
		display.vdpi = (fixed) pm->vRes;
		display.reserved2 = 0;
		display.reserved3 = 0;

		display.reserved4 = 0;
		display.reserved5 = 0;
		display.reserved6 = 0;
		display.reserved7 = 0;

		/* Bitmapbeschreibung aufbauen */
		display.bm.magic = CBITMAP_MAGIC;
		display.bm.length = sizeof( GCBITMAP );					/* StrukturlÑnge */
		display.bm.format = 0;											/* Strukturformat (0) */
		display.bm.reserved = 0;										/* reserviert (0) */

		display.bm.addr = (uint8 *) pm->baseAddr;					/* Bildschirmadresse */
		display.bm.width = pm->rowBytes & 0x3fff;					/* Breite in Bytes (obere zwei Bits von QD mÅssen ausmaskiert werden) */
		display.bm.bits = pm->pixelSize;

		if ( pm->planeBytes == 2 )										/* Emulation eines ATARI-Pixelformats? */
		{
			if ( display.bm.bits == 1 )
				display.bm.px_format = PX_PREF1;
			else if ( display.bm.bits == 2 )							/* 4 Farben, 640 * 200 KompatibilitÑtsmodus */
				display.bm.px_format = PX_ATARI2;
			else
				display.bm.px_format = PX_ATARI4;					/* 16 Farben 320 * 200 KompatibilitÑtsmodus */
		}
		else																	/* normales MAC-Pixelformat */
		{
			if ( display.bm.bits <= 8 )
				display.bm.px_format = PX_PREFn( display.bm.bits );
			else if ( display.bm.bits == 16 )						/* 16 Bit xRGB? */
				display.bm.px_format = PX_PREF15;
			else																/* 32 Bit xRGB? */
				display.bm.px_format = PX_PREF32;
		}

		display.bm.xmin = pm->bounds.left;							/* minimale diskrete x-Koordinate der Bitmap */
		display.bm.ymin = pm->bounds.top;							/* minimale diskrete y-Koordinate der Bitmap */
		display.bm.xmax = pm->bounds.right;							/* maximale diskrete x-Koordinate der Bitmap + 1 */
		display.bm.ymax = pm->bounds.bottom;						/* maximale diskrete y-Koordinate der Bitmap + 1 */
	
		display.bm.ctab = 0;												/* Verweis auf die Farbtabelle ist hier 0 */
		display.bm.itab = 0;												/* Verweis auf die inverse Farbtabelle ist hier 0 */
		display.bm.color_space = CSPACE_RGB;						/* Farbraum, entweder CSPACE_RGB oder CSPACE_GRAY (um Graustufenbetrieb vernÅnftig zu unterstÅtzen) */
		display.bm.reserved1 = 0;										/* reserviert */
	
		
		setup.magic = VDI_SETUP_MAGIC;
		setup.length = sizeof( VDI_SETUP_DATA );
		setup.format = 0;
		setup.reserved = 0;
		
		setup.displays = &display;
		setup.report_error = MSys.error;								/* Funktion fÅr den VDI-GAU */
		setup.reserved1 = 0;
		setup.reserved2 = 0;
	
		return( &setup );
	}
	return( 0 );															/* Direkter Hardwarezugriff fÅr Atari */
}

/*
	Tabulatorweite: 3
	Kommentare ab: Spalte 60											*Spalte 60*
*/

#include	<Types2B.h>
#include	<Colors2B.h>

#ifndef	__VDI_SETUP__
#define	__VDI_SETUP__

/*----------------------------------------------------------------------------------------*/
/* Monitorbeschreibung																							*/
/*----------------------------------------------------------------------------------------*/
#define	VDI_DISPLAY_MAGIC	CHAR_CONST32('vdid')
#define	VDI_DISPLAY_ACTIVE	1

#pragma PRAGMA_PACKED_ALIGN											/* Strukturelemente byteweise anordnen */

typedef struct VDI_DISPLAY
{
	int32			magic;													/* Strukturkennung 'vdim' */
	int32			length;													/* StrukturlÑnge */
	int32			format;													/* Strukturformat (0) */
	int32			reserved;												/* reserviert (0) */
	
	struct VDI_DISPLAY	*next;										/* Zeiger auf nÑchste Bildschirmbeschreibung */
	int32			display_id;												/* Monitorkennung (erstmal nur von 0 aufsteigend zÑhlend) */
	int32			flags;													/* VDI_DISPLAY_ACTIVE */
	int32			reserved1;												/* reserviert (0) */

	fixed			hdpi;
	fixed			vdpi;
	int32			reserved2;												/* reserviert (0) */
	int32			reserved3;												/* reserviert (0) */

	int32			reserved4;												/* reserviert (0) */
	int32			reserved5;												/* reserviert (0) */
	int32			reserved6;												/* reserviert (0) */
	int32			reserved7;												/* reserviert (0) */

	GCBITMAP	bm;															/* Beschreibung des Grafikspeichers */

} VDI_DISPLAY;

#pragma PRAGMA_RESET_ALIGN												/* Einstellung zurÅcksetzen */


#if 0
	Folgenden Aufbau sollte eine GCBITMAP fÅr einen Monitor haben:

{
	CBITMAP_MAGIC,															/* Strukturkennung 'cbtm' */
	sizeof( GCBITMAP ),													/* StrukturlÑnge */
	0,																			/* Strukturformat (0) */
	0,																			/* reserviert (0) */

	vram_address,															/* Adresse des Grafikspeichers */
	vram_width,																/* Breite einer Zeile in Bytes */
	vram_bits,																/* Bits pro Pixel */
	vram_px_format,														/* Pixelformat (siehe Color2B.h) */

	display_xmin,															/* minimale diskrete x-Koordinate der Bitmap (0 - solange wir nur einen Monitor unterstÅtzen) */
	display_ymin;															/* minimale diskrete y-Koordinate der Bitmap (0 - solange wir nur einen Monitor unterstÅtzen) */
	display_xmax;															/* maximale diskrete x-Koordinate der Bitmap + 1 */
	display_ymax;															/* maximale diskrete y-Koordinate der Bitmap + 1 */

	0,																			/* Verweis auf die Farbtabelle ist hier 0 */
	0,																			/* Verweis auf die inverse Farbtabelle ist hier 0 */
	display_cspace,														/* Farbraum, entweder CSPACE_RGB oder CSPACE_GRAY (um Graustufenbetrieb vernÅnftig zu unterstÅtzen) */
	0,																			/* reserviert */
}
#endif


/*----------------------------------------------------------------------------------------*/
/* Info-Struktur fÅr Initialisierung des VDIs. Wird bei vdi_blinit() Åbergeben				*/
/*----------------------------------------------------------------------------------------*/

typedef int32	VDI_SETUP_TROUBLE( int32 err );
#define	VDI_DRIVER_MISSING	-1


#define	VDI_SETUP_MAGIC	CHAR_CONST32('vdii')

#pragma PRAGMA_PACKED_ALIGN											/* Strukturelemente byteweise anordnen */

typedef struct
{
	int32			magic;													/* Strukturkennung 'vdii' */
	int32			length;													/* StrukturlÑnge */
	int32			format;													/* Strukturformat (0) */
	int32			reserved;												/* reserviert (0) */

	VDI_DISPLAY	*displays;												/* Liste der angeschlossenen Monitore */
	VDI_SETUP_TROUBLE	*report_error;
	int32			reserved1;												/* reserviert (0) */
	int32			reserved2;												/* reserviert (0) */

} VDI_SETUP_DATA;

#pragma PRAGMA_RESET_ALIGN												/* Einstellung zurÅcksetzen */

#endif																		/* __VDI_SETUP__ */
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
	int32			length;													/* Strukturl�nge */
	int32			format;													/* Strukturformat (0) */
	int32			reserved;												/* reserviert (0) */
	
	struct VDI_DISPLAY	*next;										/* Zeiger auf n�chste Bildschirmbeschreibung */
	int32			display_id;												/* Monitorkennung (erstmal nur von 0 aufsteigend z�hlend) */
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

#pragma PRAGMA_RESET_ALIGN												/* Einstellung zur�cksetzen */


#if 0
	Folgenden Aufbau sollte eine GCBITMAP f�r einen Monitor haben:

{
	CBITMAP_MAGIC,															/* Strukturkennung 'cbtm' */
	sizeof( GCBITMAP ),													/* Strukturl�nge */
	0,																			/* Strukturformat (0) */
	0,																			/* reserviert (0) */

	vram_address,															/* Adresse des Grafikspeichers */
	vram_width,																/* Breite einer Zeile in Bytes */
	vram_bits,																/* Bits pro Pixel */
	vram_px_format,														/* Pixelformat (siehe Color2B.h) */

	display_xmin,															/* minimale diskrete x-Koordinate der Bitmap (0 - solange wir nur einen Monitor unterst�tzen) */
	display_ymin;															/* minimale diskrete y-Koordinate der Bitmap (0 - solange wir nur einen Monitor unterst�tzen) */
	display_xmax;															/* maximale diskrete x-Koordinate der Bitmap + 1 */
	display_ymax;															/* maximale diskrete y-Koordinate der Bitmap + 1 */

	0,																			/* Verweis auf die Farbtabelle ist hier 0 */
	0,																			/* Verweis auf die inverse Farbtabelle ist hier 0 */
	display_cspace,														/* Farbraum, entweder CSPACE_RGB oder CSPACE_GRAY (um Graustufenbetrieb vern�nftig zu unterst�tzen) */
	0,																			/* reserviert */
}
#endif


/*----------------------------------------------------------------------------------------*/
/* Info-Struktur f�r Initialisierung des VDIs. Wird bei vdi_blinit() �bergeben				*/
/*----------------------------------------------------------------------------------------*/

typedef int32	VDI_SETUP_TROUBLE( int32 err );
#define	VDI_DRIVER_MISSING	-1


#define	VDI_SETUP_MAGIC	CHAR_CONST32('vdii')

#pragma PRAGMA_PACKED_ALIGN											/* Strukturelemente byteweise anordnen */

typedef struct
{
	int32			magic;													/* Strukturkennung 'vdii' */
	int32			length;													/* Strukturl�nge */
	int32			format;													/* Strukturformat (0) */
	int32			reserved;												/* reserviert (0) */

	VDI_DISPLAY	*displays;												/* Liste der angeschlossenen Monitore */
	VDI_SETUP_TROUBLE	*report_error;
	int32			reserved1;												/* reserviert (0) */
	int32			reserved2;												/* reserviert (0) */

} VDI_SETUP_DATA;

#pragma PRAGMA_RESET_ALIGN												/* Einstellung zur�cksetzen */

#endif																		/* __VDI_SETUP__ */
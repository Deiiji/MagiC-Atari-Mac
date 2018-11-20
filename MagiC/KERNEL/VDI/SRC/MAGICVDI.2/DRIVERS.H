#define	OFFSCREEN_MAGIC "OFFSCRN"
#define	DEVICE_MAGIC "NVDIDRV"
#define	MIN_VERSION

/* Bitmapformat */
typedef struct
{
	LONG	colors;					/* Anzahl der gleichzeitig verfÅgbaren Farben */
	WORD	planes;					/* Anzahl der Planes */
	WORD	format;					/* Formatangabe (0-2) */
	WORD	flags;					/* Formatflags */
	WORD	reserved[3];			/* reserviert */
}ORGANISATION;

/*	Formatflags: siehe auch NEUE_FKT.TXT
	bit
	0: normales Format
	1:	Falcon 32k-Format:	d.h.	5 Rot-Bits, 5 GrÅn-Bits, 1 Overlay-Bit, 5 Blau-Bits
	7:	Bytes vertauscht, d.h. Intel-Modell 
*/

/* GerÑtetreiber (type) */
#define	N_OFFSCREEN	0
#define	N_SCREEN		1
#define	N_PLOTTER	11
#define	N_PRINTER	21
#define	N_META		31
#define	N_MEMORY		61
#define	N_IMAGE		91

/* Treiberheader am Anfang von GerÑte- und Offscreen-Treibern */
typedef struct DRVR_tag
{
	WORD	bra;										/* anfÑngliches bra.s */
	BYTE	magic[8];								/* entweder "NVDIDRV" oder "OFFSCRN" */ 
	WORD	version;									/* Versionsnummer, mindestens 0x290 */
	WORD	header_len;								/* LÑnge des Headers */
	WORD	type;										/* Treibertyp */
	LONG	(*init)( void *nvdi_struct );		/* Treiber initialisieren */
	LONG	(*reset)( void *nvdi_struct );	/* Treiber entfernen */
	void	(*wk_init)();							/* Workstation initialisieren, a6 enthÑlt Zeiger auf WK, d1 Zeiger auf pb oder 0L */
	void	(*wk_reset)();							/* Workstation entfernen, a6 enthÑlt Zeiger auf WK, d1 Zeiger auf pb oder 0L */
	void	(*opnwkinfo)( WORD *intout, WORD *ptsout );	/* Ausgaben von v_opnwk() etc. vornehmen, evtl. Auflîsung Ñndern, a6 zeigt auf WK */
	void	(*extndinfo)( WORD *intout, WORD *ptsout );	/* Ausgaben von vq_extnd() vornehmen, evtl. Auflîsung Ñndern, a6 zeigt auf WK */
	void	(*scrninfo)( WORD *intout, WORD *ptsout );	/* Ausgaben von vq_scrninfo() vornehmen */
	BYTE	*name;									/* Zeiger auf den Treibernamen, max 128 Bytes inkl. Nullbyte */
	void	*special;								/* Treiberspezifische Informationen, hÑngen vom Treibertyp type ab, zB. PRN_SLCT */
	LONG	res[3];									/* reserviert */
	ORGANISATION	info;							/* Beschreibung des Bitmapformats */
}DRVR_HEADER;

/* Verwaltungstruktur fÅr Offscreen-Treiber */	
typedef struct DRIVER_tag
{
	struct DRIVER_tag	*next;					/* Zeiger auf den nÑchsten Eintrag oder 0L */
	
	DRVR_HEADER	*code;							/* Zeiger auf den Treiberheader oder 0L */
	LONG	wk_len;									/* LÑnge der Workstation fÅr den Treiber */
	WORD	used;										/* gibt an, wie oft der Treiber benutzt wird */

	ORGANISATION	info;							/* Bitmaporganisation */

	BYTE	file_name[16];							/* Dateiname */
	ULONG	file_size;								/* Dateigrîûe */
	BYTE	*file_path;								/* Pfad fÅr den Treiber */
} DRIVER;

/* Verwaltungsstruktur fÅr GerÑtetreiber */
typedef struct
{
	BYTE			name[9];							/* Dateiname ohne Endung .SYS */
	BYTE			status;							/* Treibertyp (GDOS-, ATARI-VDI oder NVDI-Treiber) */
	WORD			use;								/* gibt an, wie oft der Treiber benutzt wird */
	DRVR_HEADER	*addr;							/* Zeiger auf den Treiberheader oder 0L */
	LONG			wk_len;							/* LÑnge der Workstation fÅr den Treiber */
	DRIVER		*offscreen;						/* Zeiger auf die Struktur des benutzten Offscreen-Treibers */
	WORD			open_hdl;						/* Handle, mit dem das GerÑt geîffnet wurde */
	WORD			res26;							/* reserviert */
	WORD			res28;							/* reserviert */
	WORD			res30;							/* reserviert */
} DEVICE_DRIVER;

/* NVDI-Struktur, der NVDI-Cookie zeigt hierauf */

/* es fehlen noch Funktionen zum
	-	Ñndern der Cache-Grîûen
	-	Scannen des Font-Ordners
	-	ZurÅckliefern des Pfads fÅr einen Font (ID)
*/

typedef struct
{
	WORD	version;
	LONG	datum;
	WORD	conf;
	void	*aes_wk;
	WORD	*fills;
	void	**wks;
	BYTE	*path;
	void	*drivers;
	void	*gdos_fonts;

	void	*fonthdr;
	void	*sys_font_info;
	UBYTE	**colmaptab;
	
	WORD	*opnwk_work_out;
	WORD	*extnd_work_out;
	
	WORD	no_wks;
	WORD	max_vdi;
	WORD	status;
	
	WORD	res58;	

	void	*vdi_tab;
	void	*linea_tab;
	void	*gemdos_tab;
	void	*bios_tab;
	void	*xbios_tab;
	void	**mouse_tab;

	WORD	res84;
	WORD	blitter;
	WORD	modecode;
	WORD	xbios_res;
	
	LONG	cookie_CPU;
	LONG	cookie_VDO;
	LONG	cookie_MCH;

	WORD	first_device;
	WORD	cpu020;
	WORD	magix;
	WORD	mint;

	LONG	(*search_cookie)( LONG name );
	LONG	(*init_cookie)( LONG name, LONG val );
	LONG	(*reset_cookie)( LONG name );
	
	void	(*init_virtual_vbl)();	
	void	(*reset_virtual_vbl)();	

	void	*(*Malloc_sys)( LONG len );
	WORD	(*Mfree_sys)( void *addr );

	void	*(*nmalloc)( LONG len );
	void	(*nmfree)( void *addr );

	void	*(*load_file)( BYTE *name, LONG *length );
	void	*(*load_prg)( BYTE *name );
	DRIVER	*(*load_NOD_driver)( ORGANISATION *info );
	WORD	(*unload_NOD_driver)( DRIVER *drv );
	WORD	(*init_NOD_drivers)( void );
	WORD	(*id_to_font_file)( WORD id, BYTE *file_name );
	WORD	(*set_FONT_pathes)( WORD count, LONG output_vec, BYTE **pathes );
	WORD	(*get_FONT_path)( WORD index, BYTE *path );
	WORD	(*set_caches)( LONG acache, LONG bcache, LONG fcache, LONG kcache, LONG wcache, LONG res );
	void	(*get_caches)( LONG *acache, LONG *bcache, LONG *fcache, LONG *kcache, LONG *wcache, LONG *res );
	WORD	(*get_FIF_path)( BYTE *path );
	WORD	(*get_INF_name)( BYTE *name );

	void	*vdi_setup_ptr;

} NVDI_STRUCT;

#if offsetof( NVDI_STRUCT, nmalloc ) != 140
	Fehler!!
#endif

/* Abfrage fÅr Kobold-Funktion */
#if offsetof( NVDI_STRUCT, id_to_font_file ) != 168
	Fehler!!
#endif

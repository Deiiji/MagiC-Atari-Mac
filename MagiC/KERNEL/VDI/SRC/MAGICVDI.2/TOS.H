/* attributes for Fcreate/Fsfirst/Fsnext: */

#define FA_READONLY     0x01
#define FA_HIDDEN       0x02
#define FA_SYSTEM       0x04
#define FA_VOLUME       0x08
#define FA_SUBDIR       0x10
#define FA_ARCHIVE      0x20

/* Fopen-Modi */
#define FO_READ         0
#define FO_WRITE        1
#define FO_RW           2

/* Fseek-Modi */
#define	FS_ABS 0	/* Dateianfang */
#define	FS_REL 1	/* relativ zur aktuellen Position */
#define	FS_END 2	/* Dateiende */

#define	PH_MAGIC 0x601a				/*Magic des Programmheaders */


typedef struct
{
	WORD	ph_branch;
	LONG	ph_tlen;
	LONG	ph_dlen;
	LONG	ph_blen;
	LONG	ph_slen;
	LONG	ph_res1;
	LONG	ph_prgflags;
	WORD	ph_absflag;
} PH;

typedef struct
{
    char            d_reserved[21];
    unsigned char   d_attrib;
    unsigned int    d_time;
    unsigned int    d_date;
    unsigned long   d_length;
    char            d_fname[14];
} DTA;

typedef struct baspag   /* used by Pexec */
{
        void    *p_lowtpa;
        void    *p_hitpa;
        void    *p_tbase;
        long    p_tlen;
        void    *p_dbase;
        long    p_dlen;
        void    *p_bbase;
        long    p_blen;
        DTA     *p_dta;
        struct baspag *p_parent;
        long    p_resrvd0;
        char    *p_env;
        char    p_stdfh[6];
        char    p_resrvd1;
        char    p_curdrv;
        long    p_resrvd2[18];
        char    p_cmdlin[128];
} BASPAG;

/* system variable _sysbase (0x4F2L) points to next structure         */
typedef struct _syshdr
{
    unsigned       os_entry;   /* $00 BRA to reset handler             */
    unsigned       os_version; /* $02 TOS version number               */
    void           *os_start;  /* $04 -> reset handler                 */
    struct _syshdr *os_base;   /* $08 -> baseof OS                     */
    void           *os_membot; /* $0c -> end BIOS/GEMDOS/VDI ram usage */
    void           *os_rsv1;   /* $10 << unused,reserved >>            */
    long           *os_magic;  /* $14 -> GEM memoryusage parm. block   */
    long           os_gendat;  /* $18 Date of system build($MMDDYYYY)  */
    int            os_palmode; /* $1c OS configuration bits            */
    int            os_gendatg; /* $1e DOS-format date of systembuild   */
/*
    The next three fields are only available in TOS versions 1.2 and
    greater
*/
    void           *_root;     /* $20 -> base of OS pool               */
    long           *kbshift;   /* $24 -> keyboard shift state variable */
    BASPAG         **_run;     /* $28 -> GEMDOS PID of current process */
    void           *p_rsv2;    /* $2c << unused, reserved >>           */
} SYSHDR;

extern	LONG	Bconin( WORD dev );
extern	void	Bconout( WORD dev, WORD c );

extern	WORD	Cconws( const BYTE *buf );

extern	WORD	Dgetdrv( void );
extern	WORD	Dgetpath( BYTE *buf, WORD driveno );

extern	DTA	*Fgetdta( void );
extern	void	Fsetdta( DTA *dta );
extern	WORD	Fsfirst( const BYTE *filename, WORD attr );
extern	WORD	Fsnext( void );

extern	LONG	Fcreate( BYTE *name, WORD attrib );
extern	LONG	Fopen( const BYTE *filename, WORD mode );
extern	LONG	Fseek( LONG offset, WORD handle, WORD seekmode );
extern	LONG	Fread( WORD handle, LONG count, void *buf );
extern	LONG	Fwrite( WORD handle, LONG count, void *buf );						
extern	WORD	Fclose( WORD handle );

extern	void	*Malloc_sys( LONG len );
extern	WORD	Mfree_sys( void *addr );
extern	WORD	Mshrink_sys( void *addr, LONG size );


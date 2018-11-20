extern	void	copy_mem( LONG len, void *s, void *d );		/* Bytes kopieren */
extern	void	clear_mem( LONG len, void *s );					/* Bytes lîschen */
extern	void	copy_mem_aln( LONG len, void *s, void *d );	/* Bytes kopieren, Adressen sind gerade und die Anzahl ist eine Vielfache von zwei */
extern	void  *fill_mem( void *s, WORD val, LONG len );		/* Speicher mit Bytes fÅllen */
extern	void	strgcpy( void *d, void *s );						/* C-String kopieren	*/
extern	void	strgcat( void *d, void *s );						/* an einen C-String anhÑngen	*/
extern	WORD	strgcmp( BYTE *s1, BYTE *s2 );					/* zwei C-Strings vergleichen */
extern	LONG	strglen( BYTE *s );									/* LÑnge eines C-Strings ermitteln */
extern	BYTE	*strgupr( BYTE *s );									/* C-String in Groûbuchstaben umwandeln */
extern	BYTE	*intstrg( ULONG i, BYTE *s );						/* Zahl in einen C-String umwandeln */
extern	LONG	strgint( BYTE *s );									/* C-String in eine Zahl umwandeln */

						.INCLUDE "INCLUDE\TOS.I"
						
						.EXPORT	Cconws		
						.EXPORT	Dgetdrv
						.EXPORT	Dgetpath
						.EXPORT	Fgetdta
						.EXPORT	Fsetdta
						.EXPORT	Fsfirst
						.EXPORT	Fsnext
						.EXPORT	Fcreate
						.EXPORT	Fopen
						.EXPORT	Fseek
						.EXPORT	Fread
						.EXPORT	Fclose
						.EXPORT	Fwrite
						.EXPORT	Malloc_sys
						.EXPORT	Mfree_sys
						.EXPORT	Mshrink_sys
						
						.EXPORT	Bconin
						.EXPORT	Bconout
						
;LONG	Bconin( WORD dev );
Bconin:				movem.l	d1-d2/a0-a2,-(sp)
						move.w	d0,-(sp)
						move.w	#BCONIN,-(sp)
						trap		#BIOS
						addq.l	#4,sp
						movem.l	(sp)+,d1-d2/a0-a2
						rts


;void	Bconout( WORD dev, WORD c );
Bconout:				movem.l	d0-d2/a0-a2,-(sp)
						move.w	d1,-(sp)
						move.w	d0,-(sp)
						move.w	#BCONOUT,-(sp)
						trap		#BIOS
						addq.l	#6,sp
						movem.l	(sp)+,d0-d2/a0-a2
						rts

;WORD	Cconws( const BYTE *buf );
Cconws:				movem.l	d1-d2/a0-a2,-(sp)
						move.l	a0,-(sp)
						move.w	#CCONWS,-(sp)
						trap		#GEMDOS
						addq.l	#6,sp
						movem.l	(sp)+,d1-d2/a0-a2
						rts

;WORD	Dgetdrv( void );
Dgetdrv:				movem.l	d1-d2/a0-a2,-(sp)
						move.w	#DGETDRV,-(sp) ;Laufwerksnummer erfragen
						trap		#GEMDOS
						addq.l	#2,sp
						movem.l	(sp)+,d1-d2/a0-a2
						rts

;WORD	Dgetpath( BYTE *buf, WORD driveno )
Dgetpath:			movem.l	d1-d2/a0-a2,-(sp)
						move.w	d0,-(sp)
						move.l	a0,-(sp)
						move.w	#DGETPATH,-(sp) ;Laufwerksnummer erfragen
						trap		#GEMDOS
						addq.l	#8,sp
						movem.l	(sp)+,d1-d2/a0-a2
						rts

;DTA	*Fgetdta( void );
Fgetdta:				movem.l	d1-d2/a1-a2,-(sp)
						move.w	#FGETDTA,-(sp)
						trap		#GEMDOS
						addq.l	#2,sp
						move.l	d0,a0 			;Adresse der DTA
						movem.l	(sp)+,d1-d2/a1-a2
						rts

;void	Fsetdta( DTA *dta );
Fsetdta:				movem.l	d0-d2/a0-a2,-(sp)
						move.l	a0,-(sp) 		;Adresse der neuen DTA (dta)
						move.w	#FSETDTA,-(sp)
						trap		#GEMDOS
						addq.l	#6,sp
						movem.l	(sp)+,d0-d2/a0-a2
						rts

;WORD	Fsfirst( const BYTE *filename, WORD attr );
Fsfirst:				movem.l	d1-d2/a0-a2,-(sp)
						move.w 	d0,-(sp)
						move.l	a0,-(sp) 		;Dateiname mit Pfadangabe
						move.w	#FSFIRST,-(sp) ;DTA der Datei erfragen
						trap		#GEMDOS
						addq.l	#8,sp
						movem.l	(sp)+,d1-d2/a0-a2
						rts
						
;WORD	Fsnext( void );
Fsnext:				movem.l	d1-d2/a0-a2,-(sp)
						move.w	#FSNEXT,-(sp)
						trap		#GEMDOS
						addq.l	#2,sp
						movem.l	(sp)+,d1-d2/a0-a2
						rts

.MODULE Fcreate
;LONG	Fcreate( BYTE *name, WORD attrib );						
						movem.l	d1-d2/a0-a2,-(sp)
						move.w	d0,-(sp)			;Attribute
						move.l	a0,-(sp) 		;Name
						move.w	#FCREATE,-(sp)	
						trap		#GEMDOS
						addq.l	#8,sp
						movem.l	(sp)+,d1-d2/a0-a2
						rts
.ENDMOD

;LONG	Fopen( const BYTE *filename, WORD mode );
Fopen:				movem.l	d1-d2/a0-a2,-(sp)
						move.w 	d0,-(sp)			;Modus
						move.l	a0,-(sp)			;Dateiname
						move.w	#FOPEN,-(sp)
						trap		#GEMDOS
						addq.l	#8,sp
						movem.l	(sp)+,d1-d2/a0-a2
						rts

;LONG	Fseek( LONG offset, WORD handle, WORD seekmode );
Fseek:				movem.l	d1-d2/a0-a2,-(sp)
						move.w	d2,-(sp) 		;Modus
						move.w	d1,-(sp) 		;Handle
						move.l	d0,-(sp) 		;Offset
						move.w	#FSEEK,-(sp)
						trap		#GEMDOS
						lea		10(sp),sp
						movem.l	(sp)+,d1-d2/a0-a2
						rts

;LONG	Fread( WORD handle, LONG count, void *buf );
Fread:				movem.l	d1-d2/a0-a2,-(sp)
						move.l	a0,-(sp) 		;Bufferadresse
						move.l	d1,-(sp) 		;LÑnge
						move.w	d0,-(sp) 		;Handle
						move.w	#FREAD,-(sp)	
						trap		#GEMDOS
						lea		12(sp),sp
						movem.l	(sp)+,d1-d2/a0-a2
						rts
						
;WORD	Fclose( WORD handle );
Fclose:				movem.l	d1-d2/a0-a2,-(sp)
						move.w	d0,-(sp) 		;Handle
						move.w	#FCLOSE,-(sp)	;Datei schlieûen
						trap		#GEMDOS
						addq.l	#4,sp
						movem.l	(sp)+,d1-d2/a0-a2
						rts

.MODULE Fwrite
;LONG	Fwrite( WORD handle, LONG count, void *buf );						
						movem.l	d1-d2/a0-a2,-(sp)
						move.l	a0,-(sp)
						move.l	d1,-(sp)
						move.w	d0,-(sp)			;Handle
						move.w	#FWRITE,-(sp)	
						trap		#GEMDOS
						lea		12(sp),sp
						movem.l	(sp)+,d1-d2/a0-a2
						rts
.ENDMOD
						
;void	*Malloc_sys( LONG len );
;Speicher allozieren
;Eingaben
;d0.l LÑnge des Speicherbereichs
;Ausgaben
;d0.l Adresse des Speicherblocks oder 0 (Fehler)
;a0.l	Adresse des Speicherblocks oder 0 (Fehler)
Malloc_sys:			movem.l	d1-d3/a1-a2,-(sp)

						move.w	#DONT_FREE+SUPER_MEM+TT_RAM_pref,d1
						moveq		#MXALLOC,d2
						
malloc:				move.w	d1,-(sp)			;Modus
						move.l	d0,-(sp)			;LÑnge
						move.w	d2,-(sp)			;Opcode
						trap		#GEMDOS
						addq.l	#8,sp

						move.l	d0,d1
						subq.l	#1,d1				;wurde ein 0 Bytes langer Bereich angefordert?
						bne.s		malloc_exit
						moveq		#0,d0				;kein Speicher

malloc_exit:		move.l	d0,a0
						movem.l	(sp)+,d1-d3/a1-a2
						rts

;WORD	Mfree_sys( void *addr );
;Allozierten Speicher zurÅckgeben
;Eingaben
;a0.l Adresse des Speicherblocks
;Ausgaben
;d0.w evtl. -40 (falsche Adresse)
Mfree_sys:			movem.l	d1-d2/a0-a2,-(sp)
						move.l	a0,-(sp) 		;Bereichsadresse
						move.w	#MFREE,-(sp)
						trap		#GEMDOS
						addq.l	#6,sp
						movem.l	(sp)+,d1-d2/a0-a2
						rts

;WORD	Mshrink_sys( void *addr, LONG size );
;Eingaben
;d0.l neue LÑnge des Speicherblocks
;a0.l Adresse des Speicherblocks
;Ausgaben
;d0.w evtl. -40 (falsche Adresse) oder -67 (Speicherblock vergrîûert)
Mshrink_sys: 		movem.l	d1-d2/a0-a2,-(sp)
						move.l	d0,-(sp) 		;BereichslÑnge
						move.l	a0,-(sp) 		;Bereichsadresse
						clr.w 	-(sp)
						move.w	#MSHRINK,-(sp)
						trap		#GEMDOS
						lea		12(sp),sp
						movem.l	(sp)+,d1-d2/a0-a2
						rts


						.END
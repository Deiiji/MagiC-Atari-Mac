;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;'1. Kontrollfunktionen'

;XBIOS-Aufl�sung f�r NVDI-Treiber setzen
;Vorgaben:
;kein Register wird ver�ndert

;Eingaben:
;d1.l pb
;d3.w Ger�tekennung - 1
;Ausgaben
;XBIOS-Aufl�sung wird evtl. ver�ndert
set_xbios_res: 	cmp.w 	#FALCONMDS+1,d3 ;Falcon-Modus?
						bne.s 	set_xbios_rsave
						cmpi.w	#FALCON_VIDEO,video ;Falcon?
						beq.s 	set_falcon_res
set_xbios_rsave:	movem.l	d0-d1,-(sp)
						move.w	resolution,d0	;Xbios-Aufl�sung +1
						tst.w 	d3 				;aktuelle Aufl�sung ?
						beq.s 	set_res_exit
						moveq 	#ST_HIGH+1,d1	;hohe ST-Aufl�sung (Xbios)
						cmpi.w	#TT_VIDEO,video ;TT ?
						bne.s 	set_res_mono
						moveq 	#TT_HIGH+1,d1	;hohe TT-Aufl�sung (Xbios)
set_res_mono:		cmp.w 	d1,d0 			;momentan Monochrombetrieb ?
						beq.s 	set_res_exit
						cmp.w 	d1,d3 			;Monochrombetrieb gew�nscht ?
						beq.s 	set_res_exit
						move.w	d3,d0 			;gew�nschte Aufl�sung
						subq.w	#1,d0 			;XBIOS-Aufl�sung
						cmp.w 	#7,d0 			;Aufl�sung vorhanden ?
						bgt.s 	set_act_res
						btst		d0,#%101000 	;Aufl�sung vorhanden ?
						beq.s 	set_xbios_res2
set_act_res:		move.w	resolution,d0
						subq.w	#1,d0
set_xbios_res2:	bsr		set_resolution ;neue Aufl�sung setzen
set_res_exit:		movem.l	(sp)+,d0-d1
						rts

;XBIOS-Aufl�sung auf Falcon f�r NVDI-Treiber setzen
;Vorgaben:
;kein Register wird ver�ndert
;Eingaben:
;d1.l pb
;d3.w Ger�tekennung - 1
;Ausgaben
;XBIOS-Aufl�sung wird evtl. ver�ndert
set_falcon_res:	movem.l	d0-d2/a0-a2,-(sp)

						move.l	d1,-(sp)
						move.w	#-1,-(sp)
						move.w	#VSETMODE,-(sp)
						trap		#XBIOS
						addq.l	#4,sp
						movea.l	(sp)+,a0 		;pb
						movea.l	pb_ptsout(a0),a0
						move.w	d0,modecode 	;aktuellen modecode sichern
						cmp.w 	(a0),d0			;gew�nschte Aufl�sung schon eingestellt?
						beq.s 	set_flc_res_exit

						move.w	(a0),modecode
						
						move.w	(a0),-(sp)		;modecode
						move.w	#FALCONMDS,-(sp) ;Falcon-Aufl�sungen
						moveq 	#-1,d0			;Adressen nicht �ndern
						move.l	d0,-(sp) 		;Physbase
						move.l	d0,-(sp) 		;Logbase
						move.w	#SETSCREEN,-(sp)
						trap		#XBIOS

						lea		14(sp),sp

set_flc_res_exit: movem.l	(sp)+,d0-d2/a0-a2
						rts

;Ger�tetreiber laden
;Vorgaben:
;
;Eingaben:
;d3.w Ger�tekennung - 1
;a3.l Zeiger auf Treibereintrag in der Treibertabelle
;Ausgaben
;d0.l Zeiger auf den Treiberstart oder 0 (keinen Treiber gefunden)
;		oder NO_NVDI_DRVR (keinen NVDI-Treiber gefunden)
;d1.l pb
;d3.w Ger�tekennung - 1
;a0.l Zeiger auf den Treiberstart
;a3.l Zeiger auf Treibereintrag in der Treibertabelle
opnwk_load_drvr:	bsr		set_xbios_res	;XBIOS-Aufl�sung setzen => Treiber wird geladen
						move.l	screen_driver+driver_addr,d0	;Zeiger auf den Treiber
						movea.l	d0,a0 								;Treiberstart
						tst.l		d0										;Treiber vorhanden?
						bne.s		opnwk_drv_planes
						rts

opnwk_drv_planes:	movem.l	d0-d2/a0-a2,-(sp)
						move.w	DRVR_planes(a0),d0				;unterst�tzte Plane-Anzahl des geladenen Treibers						
						cmp.w		PLANES.w,d0							;ist der richtige Treiber geladen?
						beq.s		opnwk_dpl_exit

						bsr		unload_scr_drvr					;vorhandenen Treiber entfernen
						bsr		load_scr_drvr						;neuen Bilschirmtreiber laden

opnwk_dpl_exit:	movem.l	(sp)+,d0-d2/a0-a2
						rts

;Bildschirmtreiber �ffnen
;Vorgaben:
;
;Eingaben:
;d1.l pb
;d3.w Ger�tekennung - 1
;a1.l contrl
;a2.l intin
;a3.l Treiberstruktur
;a4.l intout
;a5.l ptsout
;Ausgaben:
;d1.l pb
;d3.w Ger�tekennung - 1
;d4.w Handle 1
;a1.l contrl
;a2.l intin
;a4.l intout
;a5.l ptsout
open_nvdi_drvr:	move.w	d3,first_device
						movea.l	aes_wk_ptr,a6		;Workstation des AES
						move.l	a6,wk_tab			;in die Wk-Tabelle eintragen
						moveq 	#1,d4 				;Handle
						move.w	d3,driver_id(a6)	;Treiber-ID speichern
						move.w	d4,wk_handle(a6)
						move.w	d4,handle(a1)
						addq.w	#1,driver_use(a3)	;Semaphore erh�hen
						move.w	d4,driver_open_hdl(a3)
						bsr		init_fonthdr		;Fontheader f�r LINE-A erstellen
						bsr		init_res 			;Line-A/VDI-Variablen initialisieren
						bsr		init_interrupts	;Interrupts einklinken
						movem.l	d1/a0-a1,-(sp)
						movea.l	a3,a0
						movea.l	driver_offscreen(a3),a1
						bsr		wk_defaults 		;Workstation initialisieren
						movem.l	(sp)+,d1/a0-a1
						movem.l	d1/a0-a1/a6,-(sp)	
						movea.l	a3,a0
						movea.l	driver_offscreen(a3),a1
						movea.l	linea_wk_ptr,a6
						bsr	 	wk_defaults			;LINEA-Workstation initialisieren
						movem.l	(sp)+,d1/a0-a1/a6

;Seit MagiC 6 wird der Bildschirm beim v_opnwk() nicht mehr gel�scht,
;da w�hrend des Bootens ein Logo angezeigt wird.
;						moveq 	#V_CLRWK,d0
;						movem.l	d1/a0-a1,-(sp)
;						bsr		call_nvdi_fkt
;						movem.l	(sp)+,d1/a0-a1


						bra		opnwk_io

;Ausgabekoordinaten n�tigenfalls ins NDC-Format konvertieren
;Dispatcher eintragen und Koordinaten n�tigenfalls ins NDC-Format konvertieren
;Vorgaben:
;Register d0-d4/a0-a2.l werden ver�ndert
;Eingaben:
;d1.l pb
;a2.l intin
;a3.l Zeiger auf Treibereintrag in der Treibertabelle
;a6.l Workstation
;Ausgaben:
;die Koordinaten im ptsout werden, wenn n�tig, ins NDC-System gewandelt
set_dispatcher:	move.l	#handle_found,(a6) ;RC-Dispatcher-Adresse
						move.b	driver_status(a3),driver_type(a6)
						rts

; OPEN WORKSTATION (VDI 1)
v_opnwk: 			movem.l	d1-d7/a2-a5,-(sp)
						movem.l	(a0),a1-a5				;contrl, intin, ptsin, intout, ptsout

						bsr		get_resolution			;aktuelle Aufl�sung erfragen

						move.w	(a2),d3					;Ger�tekennung
						subq.w	#1,d3 					;- 1
						cmpi.w	#MAX_ID-1,d3			;g�ltig ?
						bhi		opnwk_err_exit

						lea		screen_driver,a3
						tst.w 	driver_use(a3)			;Ger�t schon ge�ffnet?
						bne		opnwk_open_error
						bsr		opnwk_load_drvr		;Ger�tetreiber laden
						tst.l 	d0 						;keinen Treiber gefunden?
						beq		opnwk_err_load

						bsr		open_nvdi_drvr ;NVDI-Treiber initialisieren

						tst.l		vdi_setup_ptr.w						;kein direkter Hardware-Zugriff (Mac)?
						beq.s		v_opnwk_eddi

						lea		CONTRL.w,a0				;Zeiger auf den LineA-PB
						move.l	a0,d1						;eigener pb
						lea		contrl.w,a1				;contrl
						move.l	a1,(a0)+
						lea		intin.w,a2				;intin
						move.l	a2,(a0)+
						move.l	#ptsin,(a0)+
						move.l	#intout,(a0)+
						move.l	#ptsout,(a0)+

						move.w	#VST_FONT,(a1)
						move.w	#1,n_intin(a1)
						clr.w		n_ptsin(a1)
						move.w	#1,handle(a1)

						move.w	#1,(a2)					;Systemfont einstellen

						moveq		#115,d0
						trap		#2							;reentranter Aufruf f�r MagiCMac (killt SpeedoGDOS)

v_opnwk_eddi:		move.l	#'EdDI',d0				;Offscreen-Funktionen sind vorhanden
						move.l	#eddi_dispatcher,d1
						bsr 		init_cookie
						
opn_handle_exit:	movem.l	(sp)+,d1-d7/a2-a5
						rts

;Treiber schon per v_opnwk ge�ffnet
;Eingaben
;d3.w Ger�tekennung -1
;d4.w Handle
;a6.l Workstation
opnwk_open_error: move.l	a6,d0
						bsr		Mfree 			;Workstation-Speicher zur�ckgeben
						lsl.w 	#2,d4
						lea		wk_tab0,a6
						move.l	#closed,0(a6,d4.w) ;Workstation-Eintrag l�schen
						move.w	d3,d0
						addq.w	#1,d0 			;Ger�tekennung

opnwk_err_no_wk:									;Alle Workstations belegt
opnwk_err_id:										;Ung�ltige Ger�tekennung wurde �bergeben
opnwk_err_mem:										;Nicht gen�gend Speicher zum �ffnen einer Workstation vorhanden
opnwk_err_msg: 	
opnwk_err_load:									;Fehler beim Laden des Ger�tetreibers
opnwk_err_exit:	movem.l	(sp)+,d1-d7/a2-a5
						movea.l	d1,a0
						movea.l	(a0),a1			;contrl
						clr.w 	handle(a1)		;Fehler
						rts

;Speicher f�r eine Workstation allozieren
;Vorgaben:
;Register d0/d2/d4/a6.l werden ver�ndert
;Eingaben:
;a1.l contrl
;d3.w Ger�tekennung -1
;Ausgaben
;d0.w evtl. Fehlermeldung
;d3.w Ger�tekennung -1
;d4.w Handle oder 0 im Fehlerfall
;a1.l contrl, contrl[6] enth�lt das Handle
;a3.l Zeiger auf den Treibereintrag
;a6.l Workstationadresse, wk_handle und driver_id werden gesetzt
alloc_wk:			moveq 	#0,d4 			;Vorbesetzung mit Handle 0
						moveq 	#MAX_HANDLE-2,d2 ;Z�hler f�rs Handle
						lea		wk_tab+4,a6 ;Zeiger auf die Workstationtabelle, ersten Eintrag ignorieren
opnwk_loop: 		cmpi.l	#closed,(a6)+	;Eintrag frei ?
						dbeq		d2,opnwk_loop
						eori.w	#MAX_HANDLE-1,d2 ;Handle -1
						bpl.s 	opnwk_all_len	;alles belegt ?
						moveq 	#NOT_ENOUGH_WKS,d0
						bra.s 	alloc_wk_exit
opnwk_all_len: 	move.l	#WK_LENGTH,d0	;minimale L�nge der WK
						cmpi.b	#DRIVER_NVDI,driver_status(a3) ;NVDI-Treiber?
						bne.s 	opnwk_get_mem
						move.l	driver_wk_len(a3),d0
opnwk_get_mem: 	move.w	d0,-(sp)
						bsr		MallocA			;Speicher f�r die WK anfordern
						tst.l 	d0 				;Fehler ?
						bne.s 	opnwk_save_wk
						addq.l	#2,sp
						moveq 	#NOT_ENOUGH_MEM,d0
						bra.s 	alloc_wk_exit
opnwk_save_wk: 	move.w	d2,d4
						addq.w	#1,d4 			;Handle
						move.l	d0,-(a6) 		;WK-Adresse speichern
						movea.l	d0,a6
						move.w	(sp)+,d2
						lsr.w 	#1,d2
						subq.w	#1,d2
opnwk_clr_wk:		clr.w 	(a6)+
						dbra		d2,opnwk_clr_wk
						movea.l	d0,a6
						move.w	d3,driver_id(a6) ;Treiber-ID speichern
						move.w	d4,wk_handle(a6)
alloc_wk_exit: 	move.w	d4,handle(a1)
						rts

;Speicher f�r Workstation zur�ckgeben
;Vorgaben:
;Register d0/a0 werden ver�ndert
;Eingaben:
;d0.w Handle
;a6.l Workstation
;Ausgaben:
;-
free_wk: 			lsl.w 	#2,d0
						lea		wk_tab0,a0 ;Zeiger auf die Workstationtabelle
						move.l	#closed,0(a0,d0.w) ;Eintrag frei
						move.l	a6,d0
						bra		Mfree 			;Speicher zur�ckgeben

;Aufl�sung ermitteln
;Ausgaben:
;resolution.w	aktuelle Aufl�sung +1
get_resolution:	movem.l	d0-d2/a0-a2,-(sp)
						moveq 	#0,d0
						move.b	sshiftmd.w,d0
						addq.w	#1,d0
						move.w	d0,resolution	;aktuelle Aufl�sung +1
						movem.l	(sp)+,d0-d2/a0-a2
						rts

;Aufl�sung setzen
;Eingaben:
;d0.w gew�nschte Aufl�sung
;Ausgaben:
; -
set_resolution:	movem.l	d0-d2/a0-a2,-(sp)
						move.w	d0,-(sp) 		;neue Aufl�sung
						moveq 	#-1,d0			;Adressen nicht �ndern
						move.l	d0,-(sp) 		;Physbase
						move.l	d0,-(sp) 		;Logbase
						move.w	#SETSCREEN,-(sp)
						trap		#XBIOS
						lea		12(sp),sp
						movem.l	(sp)+,d0-d2/a0-a2
						rts

;Eingaben:
;d1.l pb
;a3.l Zeiger auf die Treiberstruktur
;a6.l Workstation
opnwk_io:			bsr		init_arrays 	;LINE-A-Variablen setzen
						bsr.s 	v_opnwk_in		;intin ber�cksichtigen
						bsr.s 	v_opnwk_out 	;intout/ptsout besetzen
opnwk_io_exit: 	rts

;Ausgaben von v_opnwk/v_opnvwk in intout und ptsout
;Vorgaben:
;kein Register wird ver�ndert
;Eingaben:
;d1.l pb
;a4.l intout
;a5.l ptsout
;a6.l Workstation
;Ausgaben:
;work_out[0..56] in intout und ptsout
v_opnwk_out:		movem.l	d0-d2/a0-a5,-(sp)
						move.l	device_drvr(a6),d0
						beq.s		v_opnwk_out_off
						movea.l	d0,a2
						movea.l	driver_addr(a2),a2
						bra.s		v_opnwk_out_call
v_opnwk_out_off:	movea.l	bitmap_drvr(a6),a2
						movea.l	DRIVER_code(a2),a2
v_opnwk_out_call:	movea.l	DRVR_opnwkinfo(a2),a2
						movea.l	a4,a0
						movea.l	a5,a1
						jsr		(a2)
v_opnwk_out_exit: movem.l	(sp)+,d0-d2/a0-a5
						rts

;NVDI-Funktion aufrufen
;Vorgaben:
;d0/a0/a1 werden ver�ndert
;Eingaben:
;d0.w Funktionsnummer
;d1.l pb
;a6.l Workstation
;Ausgaben:
;d1.l pb
call_nvdi_fkt: 	lsl.w 	#3,d0
						lea		vdi_tab(pc),a0
						move.l	4(a0,d0.w),-(sp)
						movea.l	d1,a0 			;pb
						rts

;Eingaben aus intin bei v_opnwk()/v_opnvwk() setzen
;Vorgaben:
;kein Register wird ver�ndert
;Eingaben:
;d1.l pb
;a6.l Workstation
;Ausgaben:
;verschiedene Eintragungen in der Workstation
v_opnwk_in: 		movem.l	d0-d1/a0-a1/a3,-(sp)
						movea.l	d1,a0
						lea		pb_intin(a0),a3
						addq.l	#2,(a3)			;Linientyp		  intin[1]
						moveq 	#VSL_TYPE,d0
						bsr.s 	call_nvdi_fkt
						addq.l	#2,(a3)			;Linienfarbe	  intin[2]
						moveq 	#VSL_COLOR,d0
						bsr.s 	call_nvdi_fkt
						addq.l	#2,(a3)			;Markertyp		  intin[3]
						moveq 	#VSM_TYPE,d0
						bsr.s 	call_nvdi_fkt
						addq.l	#2,(a3)			;Markerfarbe	  intin[4]
						moveq 	#VSM_COLOR,d0
						bsr.s 	call_nvdi_fkt
						movea.l	d1,a0
						pea		opnwk_tcolor(pc)
						cmpi.w	#319,res_y(a6) ;mindestens 320 Pixel H�he?
						blt		vst_height6
						bra		vst_height13	;Zeichenh�he
opnwk_tcolor:		addq.l	#4,(a3)			;Textfarbe		  intin[6]
						moveq 	#VST_COLOR,d0
						bsr.s 	call_nvdi_fkt
						addq.l	#2,(a3)			;F�llmustertyp   intin[7]
						moveq 	#VSF_INTERIOR,d0
						bsr.s 	call_nvdi_fkt
						addq.l	#2,(a3)			;F�llmusterindex intin[8]
						moveq 	#VSF_STYLE,d0
						bsr.s 	call_nvdi_fkt
						addq.l	#2,(a3)			;F�llmusterfarbe intin[9]
						moveq 	#VSF_COLOR,d0
						bsr.s 	call_nvdi_fkt
						subi.l	#18,(a3) 		;Zeiger auf intin korrigieren
						movem.l	(sp)+,d0-d1/a0-a1/a3
						rts

init_fonthdr:		movem.l	d0-d1/a0-a2,-(sp)
						lea		font_hdr1,a1 ;6*6  Fontheader
						lea		font_hdr2,a2 ;8*8  Fontheader
						lea		FONT_RING.w,a0
						move.l	a1,(a0)+
						move.l	a2,(a0)+
						clr.l 	(a0)+ 			;keine GDOS-Fonts
						clr.l 	(a0)+ 			;Ende der Liste
						move.w	#1,FONT_COUNT.w ;Anzahl der Zeichens�tze
						move.l	a2,DEF_FONT.w	;Zeiger auf den Systemfont
						move.l	dat_table(a2),V_FNT_AD.w
						moveq 	#8,d0 			;Zeichenh�he
						moveq 	#0,d1
						move.w	V_REZ_VT.w,d1	;vertikale Aufl�sung
						cmpi.w	#400,d1			;kleinen Font verwenden?
						blt.s 	init_nvdi_exit
						moveq 	#16,d0			;Zeichenh�he
						lea		font_hdr3,a2	;8*16 Fontheader
init_nvdi_exit:	move.l	a2,DEF_FONT.w
						move.l	dat_table(a2),V_FNT_AD.w
						move.w	d0,V_CEL_HT.w	;Zeichenh�he
						divu		d0,d1
						subq.w	#1,d1
						move.w	d1,V_CEL_MY.w	;h�chste Zeilennummer
						movem.l	(sp)+,d0-d1/a0-a2
						rts

;VDI-Variablen in LINEA abh�ngig von der XBIOS-Aufl�sung initialisieren
;Vorgaben:
;kein Register wird zerst�rt
;Eingaben:
;resolution
;a3.l Zeiger auf aktuellen Treibereintrag
;a6.l Zeiger auf die Workstation
;Ausgaben:
;DEV_TAB, SIZ_TAB und INQ_TAB werden gesetzt
init_res:			movem.l	d0-d2/a0-a2,-(sp)
						movea.l	driver_addr(a3),a2
						movea.l	DRVR_opnwkinfo(a2),a2
						lea		DEV_TAB0.w,a0
						lea		SIZ_TAB.w,a1
						jsr		(a2)

						movea.l	driver_addr(a3),a2
						movea.l	DRVR_extndinfo(a2),a2
						lea		INQ_TAB0.w,a0	;intout f�r vq_extnd
						lea		-64(sp),sp
						movea.l	sp,a1				;ptsout f�r vq_extnd
						jsr		(a2)
						lea		64(sp),sp
						
init_res_exit:		movem.l	(sp)+,d0-d2/a0-a2
						rts

;Timer-Interrupts, Mausinterruptroutine und Mauszeichenroutine installieren
;Vorgaben:
;kein Register wird ver�ndert
;Eingaben:
;-
;Ausgaben:
;etv_timer, USER_TIM, NEXT_TIM, USER_BUT, USER_CUR, USER_MOT, ... werden gesetzt
init_interrupts:	movem.l	d0-a6,-(sp)
						move		sr,-(sp)
						ori		#$0700,sr		;Interrupts sperren

						move.w	#etv_timer/4,d0
						lea		sys_timer(pc),a0 ;neue etv_timer-Routine
						lea		old_etv_timer,a1
						bsr		change_vec

						move.l	#dummy,USER_TIM.w
						move.l	old_etv_timer,NEXT_TIM.w
						move.l	#dummy,USER_BUT.w
						move.l	#user_cur,USER_CUR.w
						move.l	#dummy,USER_MOT.w

						lea		mouse_form(pc),a2
						bsr		transform_in	;Mauszeiger
						clr.w 	MOUSE_BT.w		;keine Maustaste gedr�ckt
						clr.b 	CUR_MS_STAT.w	;keine Mausbewegung
						clr.b 	MOUSE_FLAG.w	;Maus zeichnen
						moveq 	#1,d0
						move.b	d0,M_HID_CT.w	;Maus darf nicht gezeichnet werden
						move.b	d0,CUR_FLAG.w
						move.l	DEV_TAB0.w,d0
						lsr.l 	#1,d0
						bclr		#15,d0			;Bit l�schen
						move.l	d0,GCURX.w
						move.l	d0,CUR_X.w
						movea.l	vbl_queue.w,a0
						move.l	#vbl_mouse,(a0) ;VBL-Mausroutine

						lea		mouse_int_lower(pc),a0
						move.l	a0,-(sp) 		;Mausinterruptroutine
						pea		mouse_param(pc) ;Parameter f�r Initmous
						moveq 	#1,d0 			;Initmouse/relativer Mausmodus
						move.l	d0,-(sp)
						trap		#XBIOS
						lea		12(sp),sp
						move		(sp)+,sr
						movem.l	(sp)+,d0-a6
						rts

mouse_param:		DC.B 0						;topmode
						DC.B 0						;buttons
						DC.B 1						;xparam
						DC.B 1						;yparam

;Mauszeiger
mouse_form: 		DC.W 1						;mf_xhot
						DC.W 1						;mf_yhot
						DC.W 1						;mf_nplanes - immer 1
						DC.W 0						;mf_fg - Maskenfarbe
						DC.W 1						;mf_bg - Cursorfarbe
;Maske
						DC.W %1100000000000000	;1
						DC.W %1110000000000000	;2
						DC.W %1111000000000000	;3
						DC.W %1111100000000000	;4
						DC.W %1111110000000000	;5
						DC.W %1111111000000000	;6
						DC.W %1111111100000000	;7
						DC.W %1111111110000000	;8
						DC.W %1111111111000000	;9
						DC.W %1111111111100000	;10
						DC.W %1111111000000000	;11
						DC.W %1110111100000000	;12
						DC.W %1100111100000000	;13
						DC.W %1000011110000000	;14
						DC.W %11110000000 		;15
						DC.W %1110000000			;16
;Sprite
						DC.W %0						;1
						DC.W %100000000000000	;2
						DC.W %110000000000000	;3
						DC.W %111000000000000	;4
						DC.W %111100000000000	;5
						DC.W %111110000000000	;6
						DC.W %111111000000000	;7
						DC.W %111111100000000	;8
						DC.W %111111110000000	;9
						DC.W %111110000000000	;10
						DC.W %110110000000000	;11
						DC.W %100011000000000	;12
						DC.W %11000000000 		;13
						DC.W %1100000000			;14
						DC.W %1100000000			;15
						DC.W %0						;16

;LINE-A-Variablen beim �ffnen der Workstation besetzen (Kompatibilit�t!)
init_arrays:		movem.l	d0/a0/a6,-(sp)
						moveq 	#-1,d0
						lea		intin,a6
						move.l	d0,(a6)			;f�r TEMPUS WORD
						lea		COLBIT0.w,a0
						move.l	d0,(a0)+ 		;COLBIT0/COLBIT1
						move.l	d0,(a0)+ 		;COLBIT2/COLBIT3
						move.l	d0,(a0)+ 		;LSTLIN/LNMASK.w
						move.w	d0,TEXTFG.w
						clr.w 	TEXTBG.w
						move.l	font_hdr3+dat_table,FBASE.w
						move.w	font_hdr3+form_width,FWIDTH.w
						move.l	buffer_ptr,SCRTCHP.w
						move.w	#NVDI_BUF_SIZE/2,SCRPT2.w
						move.l	#fill0,PATPTR.w
						clr.w 	PATMSK.w
						move.w	#1,V_HID_CNT.w	;Cursor aus !
						clr.w 	MFILL.w			;kein Mehrfarbmuster
						cmpi.w	#8,PLANES.w
						blt.s 	init_la_exit
						clr.l 	COLBIT4.w
						clr.l 	COLBIT6.w
init_la_exit: 		movem.l	(sp)+,d0/a0/a6
						rts

;wk_init( DEVICE_DRIVER *dev, DRIVER *off, WK *wk );
wk_init:				move.l	a6,-(sp)
						movea.l	8(sp),a6
						moveq		#0,d1
						bsr.s		wk_defaults
						movea.l	(sp)+,a6
						rts
						
;Workstation initialisieren
;Vorgaben:
;kein register wird ver�ndert
;Eingaben:
;d1.l pb oder 0L
;a0.l Zeiger auf die Ger�tetreiber-Struktur DEVICE_DRIVER
;a1.l Zeiger auf den Offscreen-Treiber-Struktur DRIVER
;a6.l Workstation
;Ausgaben:
;Die Workstation wird initialisert
wk_defaults:		movem.l	d0-d2/a0-a1,-(sp)
					
						move.l	#handle_found,(a6) ;RC-Dispatcher-Adresse
						clr.l 	disp_addr2(a6)
						move.l	DEV_TAB0.w,res_x(a6) ;Aufl�sung
						move.l	DEV_TAB3.w,pixel_width(a6)

						move.w	PLANES.w,d0 	;Anzahl der Bildebenen
						subq.w	#1,d0
						move.w	d0,planes(a6)	;Anzahl der Bildebenen -1
						move.w	DEV_TAB13.w,d0
						subq.w	#1,d0
						move.w	d0,colors(a6)	;Anzahl der Farben -1

						move.b	#DRIVER_NVDI,driver_type(a6) ;NVDI-Treiber

						clr.w 	t_bitmap_gdos(a6) ;noch keine Fonts geladen
						clr.w 	res_ratio(a6)	;Seitenverh�ltnis
						cmpa.l	aes_wk_ptr,a6		;erste WK ?
						beq.s 	wk_arrays
						movea.l	aes_wk_ptr,a0
						move.w	res_ratio(a0),res_ratio(a6)
wk_arrays:
						move.b 	#$0f,input_mode(a6)	;alle Eingabeeinheiten auf Sample
;Bezier
						move.w	#5,bez_qual(a6) ;Bezier maximale Qualit�t
						clr.l 	bez_buffer(a6) ;kein speziell Bezier-Puffer vorhanden
						clr.l 	bez_buf_len(a6) ;L�nge des Bezier-Buffers ist 0
;Clipping
						clr.l 	clip_xmin(a6)	;clip_xmin/clip_ymin
						move.l	res_x(a6),clip_xmax(a6) ;clip_xmax/clip_ymax
						clr.w 	wr_mode(a6) 	;wr_mode

;Linienattribute
						lea		l_width(a6),a0
						move.w	#L_WIDTH_MIN,l_width(a6) ;l_width
						clr.l 	l_start(a6) 	;l_start/l_end
						clr.l 	l_lastpix(a6)	;l_lastpix/l_style
						lea		l_styles(a6),a0
						move.l	#%11111111111111111111111111110000,(a0)+
						move.l	#%11100000111000001111111100011000,(a0)+
						move.l	#%11111111000000001111000110011000,(a0)+
						move.w	#$ffff,(a0)+	;l_sdstyle

;Textattribute
						clr.l 	t_effects(a6)			;t_effects/t_rotation
						clr.l 	t_hor(a6)				;t_hor/t_ver
						move.w	#T_SYSTEM_FACE,t_number(a6)	;t_number
						move.l	#font_hdr1,t_pointer(a6)	;t_pointer
						move.l	buffer_ptr,buffer_addr(a6)	;t_buffer
						move.l	#NVDI_BUF_SIZE,buffer_len(a6)
						clr.w 	t_point_height(a6)	;H�he per vst_height gesetzt
						clr.l 	t_bitmap_fonts(a6)	;t_next_font
						clr.b		t_font_type(a6)		;Bitmap-Font
						move.b	#1,t_mapping(a6)		;ASCII-Mapping
						move.w	#-1,t_no_kern(a6)		;Pair-Kerning aus!
						clr.w		t_no_track(a6)			;keine Kerning-Tracks vorhanden
						clr.w		t_skew(a6)				;keine Schr�gstellung
						clr.w		t_track_index(a6)		;kein Track-Index
						clr.l		t_track_offset(a6)
						move.w	#255,t_ades(a6)

;F�llattribute
						move.w	#ON,f_perimeter(a6) ;Umrahmung ein
						lea		f_saddr(a6),a0
						move.l	a0,f_spointer(a6) ;Zeiger
						clr.w		f_splanes(a6)
						move.l	#fill0,f_fill0(a6)
						move.l	#fill1,f_fill1(a6)
						move.l	#fill2_1,f_fill2(a6)
						move.l	#fill3_1,f_fill3(a6)
						lea		fill4_1,a1
						moveq 	#7,d0 			;Langwortz�hler
init_wk_fill:		move.l	(a1)+,(a0)+
						dbra		d0,init_wk_fill

						move.w	#9,m_height(a6) ;Default-Markerh�he
						
						move.l	#text,p_gtext(a6)
						move.l	#v_escape_in,p_escapes(a6)
						
						movem.l	(sp),d0-d2/a0-a1
;Off-Screen-Bitmap
						move.l	a0,device_drvr(a6)
						move.l	a1,bitmap_drvr(a6)

						move.l	a0,d0				;Ger�tetreiber vorhanden?
						beq.s		wkdef_off
						movea.l	driver_addr(a0),a0

						move.l	DRVR_colors(a0),bitmap_colors(a6)	;Anzahl der gleichzeitig darstellbaren Farben
						move.w	DRVR_planes(a0),bitmap_planes(a6)	;Anzahl der Ebenen
						move.w	DRVR_format(a0),bitmap_format(a6)	;Pixelformat
						move.w	DRVR_flags(a0),bitmap_flags(a6)		;Bit-Organisation
						
wkdef_off:			move.l	a1,d0				;Offscreen-Treiber vorhanden?
						beq.s		wkdef_drv
						movea.l	DRIVER_code(a1),a1
						movea.l	DRVR_wk_init(a1),a1
						jsr		(a1)				;Offscreen-Treiber anspringen
						
wkdef_drv:			movem.l	(sp),d0-d2/a0-a1
						
						move.l	a0,d0				;Ger�tetreiber vorhanden?
						beq.s		wkdef_exit
						movea.l	driver_addr(a0),a0
						movea.l	DRVR_wk_init(a0),a0
						jsr		(a0)				;Ger�tetreiber anspringen

wkdef_exit:			moveq		#0,d0
						move.w	pixel_width(a6),d0			;Pixelbreite
						move.w	pixel_height(a6),d1			;Pixelh�he
						move.w	d0,d2
						lsr.w		#1,d2
						add.w		d2,d0								;Pixelbreite * 1.5
						divu		d1,d0								;durch Pixelh�he teilen
						subq.w	#1,d0								;Seitenverh�ltnis
																		;< 0: vertikal stauchen
																		;0  : quadratisches Pixelverh�ltnis
																		;> 0: vertikal dehnen
						move.w	d0,res_ratio(a6)

						movem.l	(sp)+,d0-d2/a0-a1
						rts

init_mono_NOD:		movem.l	d3-d7/a2-a6,-(sp)
						move.l	a0,mono_DRVR
						movea.l	linea_wk_ptr,a6
						move.l	DRVR_wk_init(a0),a1
						jsr		(a1)
						move.l	p_bitblt(a6),mono_bitblt
						move.l	p_expblt(a6),mono_expblt
						movem.l	(sp)+,d3-d7/a2-a6
						rts

Bconout: 			movem.l	d0-d2/a0-a2,-(sp)
						move.w	d0,-(sp)
						move.w	#CON,-(sp)
						move.w	#BCONOUT,-(sp)
						trap		#BIOS
						addq.l	#6,sp
						movem.l	(sp)+,d0-d2/a0-a2
						rts


;Treiber mit in contrl[6] vorgegebem Handle aufrufen
;Vorgaben:
;kein Register wird zerst�rt
;Eingaben:
;d1.l pblock
;a6.l Workstation (disp_addr2)
;Ausgaben:
;-
cldrvr:				movem.l	d0-d2/a0-a2,-(sp)
						movea.l	disp_addr2(a6),a0 ;Zeiger auf den Treiber
						jsr		(a0)				;Treiber aufrufen
						movem.l	(sp)+,d0-d2/a0-a2
						rts

; OPEN VIRTUAL SCREEN WORKSTATION (VDI 100)
v_opnvwk:			movem.l	d1-d7/a2-a5,-(sp)
						movem.l	(a0),a1-a5
						cmpi.w	#1,opcode2(a1) ;v_opnbm()?
						bne.s 	v_opnvwk_id
						cmpi.w	#20,n_intin(a1) ;richtige Parameteranzahl?
						beq	 	v_opnbm
v_opnvwk_id:		move.w	driver_id(a6),d3 ;Ger�tekennung
						movea.l	device_drvr(a6),a3
						move.w	wk_handle(a6),d7 ;Handle der physikalischen Workstation
						bsr		alloc_wk 		;Workstation-Speicher allozieren
						tst.w 	d4 				;Fehler?
						beq.s 	v_opnvwk_exit
						movem.l	a0-a1,-(sp)
						movea.l	a3,a0
						movea.l	driver_offscreen(a3),a1
						bsr		wk_defaults 	;Workstation initialisieren
						movem.l	(sp)+,a0-a1
						addq.w	#1,driver_use(a3) ;Semaphore inkrementieren
v_opnvwk_io:		bsr		opnwk_io
;						bsr		set_dispatcher ;Dispatcher eintragen
v_opnvwk_exit: 	movem.l	(sp)+,d1-d7/a2-a5
						rts
v_opnvwk_err:		move.w	d4,d0 			;Handle
						bsr		free_wk			;Workstation freigeben
						movem.l	(sp)+,d1-d7/a2-a5
						rts

;Eingaben:
;d1.l pb
;d4.w Handle
;a1.l contrl
;a2.l intin
;a3.l ptsin
;a6.l Workstation
;Ausgaben:
;...
v_opnbm:	 			move.l	a2,-(sp)			;intout
						move.l	s_addr(a1),-(sp)	;MFDB *
						movea.l	a6,a1
						movea.l	device_drvr(a6),a0
						jsr		create_bitmap	;WK	*create_bitmap( DEVICE_DRIVER *device_driver, WK *dev_wk, MFDB *m, WORD *intin )
						addq.l	#8,sp				;Stack korrigieren
						move.l	a0,d0
						beq.s		v_opnbm_err
						movea.l	a0,a6
						movea.l	(sp),a0			;pb
						move.l	a0,d1
						movem.l	(a0),a1-a5
						move.w	wk_handle(a6),handle(a1)	;Handle ausgeben
						bsr 		v_opnwk_in		;intin ber�cksichtigen
						movea.l	bitmap_drvr(a6),a2
						movea.l	DRIVER_code(a2),a2
						movea.l	DRVR_opnwkinfo(a2),a2
						movea.l	a4,a0
						movea.l	a5,a1
						jsr		(a2)
						movem.l	(sp)+,d1-d7/a2-a5
						rts

v_opnbm_err:		move.l	(sp),a0			;pb
						move.l	(a0),a1			;contrl
						clr.w 	handle(a1)
						movem.l	(sp)+,d1-d7/a2-a5
						rts

;void	clear_bitmap( WK *wk );
clear_bitmap:		move.l	a6,-(sp)
						movea.l	a0,a6
						bsr		v_clrwk
						movea.l	(sp)+,a6
						rts
						
;void	transform_bitmap( MFDB *src, MFDB *des, WK *wk );
transform_bitmap:	movem.l	a2/a6,-(sp)
						movea.l	12(sp),a6
						movea.l	p_transform(a6),a2
						jsr		(a2)
						movem.l	(sp)+,a2/a6
						rts

;Fehler bei v_clswk
;Eingaben
;d0.w handle
v_clswk_err:		movem.l	(sp)+,d1-d2/a2
						bra		v_clsvwk 		;dann v_clsvwk

; CLOSE WORKSTATION (VDI 2)
v_clswk: 			movem.l	d1-d3/a2,-(sp)
						movea.l	(a0),a1			;contrl
						move.w	handle(a1),d0	;contrl[6] = Handle
						beq		v_clswk_exit	;Handle = 0 ?
						movea.l	device_drvr(a6),a2	;Zeiger auf die Treiberstruktur
						move.l	a2,d2				;kein Ger�tetreiber?
						beq		v_clswk_exit	
						cmp.w		driver_open_hdl(a2),d0	;erstes Handle des Ger�tes?
						bne		v_clswk_err
						move.w	driver_id(a6),d2 ;Ger�tenummer - 1
						moveq 	#MAX_HANDLE-1,d3
						lea		wk_tab,a1
v_clswk_all:		movea.l	(a1)+,a2
						cmp.w 	driver_id(a2),d2 ;zu schlie�enden Workstation?
						bne.s 	v_clswk_next
						cmpa.l	aes_wk_ptr,a2		;statische Workstation?
						beq.s 	v_clswk_phys
						cmpa.l	a6,a2 			;physikalische Workstation?
						beq.s 	v_clswk_phys
						bsr		call_clsvwk
						bra.s 	v_clswk_next
v_clswk_phys:		move.l	#closed,-4(a1) ;schlie�en
v_clswk_next:		dbra		d3,v_clswk_all
						movem.l	d0/a0-a1/a6,-(sp)
						movea.l	(a0),a1			;contrl
						move.w	#VST_UNLOAD_FONTS,(a1) ;neue Funktionsnummer
						bsr		vst_unload_fonts ;Fonts der phys. WK entfernen
						movem.l	(sp)+,d0/a0-a1/a6
						movea.l	(a0),a1			;contrl
						move.w	#V_CLSWK,(a1)	;
						movea.l	device_drvr(a6),a2	;Zeiger auf die Treiberstruktur
						clr.w 	driver_use(a2) ;Treiber nicht in Gebrauch !
						movea.l	driver_addr(a2),a1
						movea.l	DRVR_wk_reset(a1),a1
						lea		nvdi_struct,a0		;NVDI-Struktur �bergeben
						jsr		(a1)				;Workstation zur�cksetzen
						bsr		reset_interrupts	;Interrupts ausklinken
						move.l	#'EdDI',d0			;Offscreen-Funktionen sind nicht mehr vorhanden
						bsr 		reset_cookie
v_clswk_exit:		movem.l	(sp)+,d1-d3/a2
						rts
						
;v_clsvwk() oder v_clsbm() aufrufen
;kein Register wird ver�ndert
;Eingaben:
;d1.l pb
;a0.l pb
;a2.l Workstation
;Ausgaben:
;...
call_clsvwk:		rts

; CLOSE VIRTUAL SCREEN WORKSTATION (VDI 101)
v_clsvwk:			movem.l	d1-d2/a2,-(sp)
						movea.l	(a0),a1			;contrl
						move.w	handle(a1),d0	;contrl[6] = Handle
						beq.s 	v_clsvwk_exit	;Handle = 0 ?
						cmp.w 	#1,d0 			;AES-Workstation?
						beq.s 	v_clsvwk_err
						tst.l		bitmap_addr(a6)	;Offscreen?
						bne.s 	v_clsbm
						movea.l	device_drvr(a6),a2
v_clsvwk_nvdi:		movea.l	driver_addr(a2),a1
						movea.l	DRVR_wk_reset(a1),a1
						lea		nvdi_struct,a0
						jsr		(a1)				;Workstation zur�cksetzen
						subq.w	#1,driver_use(a2) ;Semaphore dekrementieren
						bsr		free_wk			;Workstation schlie�en
v_clsvwk_exit:		movem.l	(sp)+,d1-d2/a2
						rts
						
v_clsbm:				movea.l	bitmap_drvr(a6),a1
						movea.l	DRIVER_code(a1),a1
						movea.l	DRVR_wk_reset(a1),a1
						lea		nvdi_struct,a0
						jsr		(a1)				;Workstation zur�cksetzen
						movea.l	a6,a0
						jsr		delete_bitmap	;WORD	delete_bitmap( WK *wk );
						movem.l	(sp)+,d1-d2/a2
						rts

;Fehler bei v_clsvwk
;Eingaben
;d0.w handle
v_clsvwk_err:		movem.l	(sp)+,d1-d2/a2
						cmp.w 	#1,d0 			;statische Workstation ?
						beq.s 	v_clsvwk_err_exit
						bra		v_clswk			;dann v_clswk
v_clsvwk_err_exit:rts

;Verschiedene Interrupts f�rs NVDI deinstallieren
reset_interrupts: movem.l	d0-d2/a0-a2,-(sp)
						move		sr,-(sp)
						ori		#$0700,sr
;Interrupt-Vektoren setzen
						move.l	old_etv_timer,etv_timer.w
						lea		USER_TIM.w,a0	;Line-A-Vektoren l�schen
						REPT 5
						clr.l 	(a0)+
						ENDM
						clr.l 	-(sp)
						clr.l 	-(sp)
						clr.l 	-(sp) 			;Maus ausschalten
						trap		#XBIOS
						lea		12(sp),sp
						movea.l	vbl_queue.w,a0
						clr.l 	(a0)				;VBL-Routine l�schen
						move		(sp)+,sr
						movem.l	(sp)+,d0-d2/a0-a2
						rts

; CLEAR WORKSTATION (VDI 3)
v_clrwk: 			movem.l	d1-d7/a2-a5,-(sp)
						move.w	wr_mode(a6),-(sp)
						move.w	f_interior(a6),-(sp)
						move.l	f_pointer(a6),-(sp)
						move.w	f_planes(a6),-(sp)
						clr.w		wr_mode(a6)						;Replace
						move.l	f_fill0(a6),f_pointer(a6)	;leeres F�llmuster
						clr.w		f_planes(a6)					;monochrom
						clr.w		f_interior(a6)					;wei�
						moveq		#0,d0
						moveq		#0,d1
						move.w	res_x(a6),d2					;Breite - 1
						move.w	res_y(a6),d3					;H�he - 1
						move.l	a6,-(sp)
						bsr		fbox_noreg
						movea.l	(sp)+,a6
						move.w	(sp)+,f_planes(a6)
						move.l	(sp)+,f_pointer(a6)
						move.w	(sp)+,f_interior(a6)
						move.w	(sp)+,wr_mode(a6)

;F�r Bildschirmtreiber sollte noch die Initialisierung des vt52 eingebaut werden.

						movem.l	(sp)+,d1-d7/a2-a5
						rts

; UPDATE WORKSTATION (VDI 4)
v_updwk: 			rts							;Funktion ist beim Bildschirm unn�tig

; LOAD FONTS (VDI 119)
vst_load_fonts:	movem.l	d1-d3/a2-a5,-(sp)
						movea.l	pb_contrl(a0),a1 ;contrl
						movea.l	pb_intout(a0),a4 ;intout

						tst.l 	t_bitmap_fonts(a6) ;bereits Zeichens�tze geladen ?
						bne		vst_lfg_err2
						
						move.l	f_addr(a1),d0	;keine Adresse ?
						beq		vst_lfg_err2
						btst		#0,d0 			;ungerade Adresse ?
						bne		vst_lfg_err2
						clr.w 	t_bitmap_gdos(a6) ;Fonts nicht per GDOS geladen
vst_lf_nvdi:		movea.l	d0,a0
						move.l	a0,t_bitmap_fonts(a6)
vst_lf_in:			moveq 	#-1,d0
						moveq 	#0,d1
vst_lf_loop:		cmp.w 	(a0),d0			;gleiche Nummer ?
						beq.s 	vst_lf_format
						move.w	(a0),d0
						addq.w	#1,d1 			;Anzahl inkrementieren
vst_lf_format: 	tst.b 	flags+1(a0) 	;Motorola- oder Intel- Format ?
						bne.s 	vst_lf_mot
						movea.l	dat_table(a0),a1 ;Zeiger aufs Fontimage
						move.w	form_width(a0),d2
						mulu		form_height(a0),d2
						lsr.w 	#1,d2
						subq.w	#1,d2 			;Z�hler
vst_lf_swap:		move.w	(a1),d3
						ror.w 	#8,d3 			;Byte-Reihenfolge umkehren
						move.w	d3,(a1)+
						dbra		d2,vst_lf_swap
vst_lf_mot: 		bset		#2,flags+1(a0) ;Motorola-Format
						movea.l	next_font(a0),a0
						move.l	a0,d2 			;weitere Fonts vorhanden
						bne.s 	vst_lf_loop
						move.w	d1,(a4)			;intout[0] = zus�tzliche Fontanzahl
						move.l	t_bitmap_fonts(a6),FONT_RING2.w ;Kompatibilit�t
						movem.l	(sp)+,d1-d3/a2-a5
						rts

vst_lfg_err2:		clr.w		(a4)	
						movem.l	(sp)+,d1-d3/a2-a5
						rts

; UNLOAD FONTS (VDI 120)
vst_unload_fonts: movem.l	d1-d2/a2,-(sp)
						movea.l	(a0),a1			;contrl
						tst.l 	t_bitmap_fonts(a6) ;Zeichens�tze geladen ?
						beq.s 	vst_unload_exit
						clr.l 	t_bitmap_fonts(a6) ;keine Zeichens�tze �ber GDOS verf.

vst_ulf_nvdi:		movem.l	(sp)+,d1-d2/a2
						movea.l	d1,a0 			;pblock
						movem.l	d1-d7/a2,-(sp)
						moveq 	#1,d0 			;Systemfont einstellen
						lea		font_hdr1,a0
						bra		vst_font_found

vst_unload_exit:	movem.l	(sp)+,d1-d2/a2
						rts
						
; SET CLIPPING RECTANGLE (VDI 129)
vs_clip: 			movem.l	pb_intin(a0),a0-a1 ;intin/ptsin
						tst.w 	bitmap_width(a6) ;Off-Screen-Bitmap?
						bne 		vs_clip_bitmap
						movem.l	d1-d5,-(sp)
						movem.w	DEV_TAB0.w,d4/d5	;Breite -1/ H�he -1
						move.w	(a0),d0			;Clipping-Flag
						move.w	d0,CLIP.w		;wegen der Kompatibilit�t
						beq.s 	vs_clip_off 	;Clipping ausgeschaltet ?
						move.w	(a1)+,d0
						bpl.s 	vs_clip_x1max
						moveq 	#0,d0
vs_clip_x1max: 	cmp.w 	d4,d0
						ble.s 	vs_clip_y1min
						move.w	d4,d0
vs_clip_y1min: 	move.w	(a1)+,d1
						bpl.s 	vs_clip_y1max
						moveq 	#0,d1
vs_clip_y1max: 	cmp.w 	d5,d1
						ble.s 	vs_clip_x2min
						move.w	d5,d1
vs_clip_x2min: 	move.w	(a1)+,d2
						bpl.s 	vs_clip_x2max
						moveq 	#0,d2
vs_clip_x2max: 	cmp.w 	d4,d2
						ble.s 	vs_clip_y2min
						move.w	d4,d2
vs_clip_y2min: 	move.w	(a1)+,d3
						bpl.s 	vs_clip_y2max
						moveq 	#0,d3
vs_clip_y2max: 	cmp.w 	d5,d3
						ble.s 	vs_clip_exgx
						move.w	d5,d3
vs_clip_exgx:		cmp.w 	d0,d2
						bge.s 	vs_clip_exgy
						exg		d0,d2
vs_clip_exgy:		cmp.w 	d1,d3
						bge.s 	vs_clip_save
						exg		d1,d3
vs_clip_save:		movem.w	d0-d3,clip_xmin(a6)
						movem.w	d0-d3,XMINCL.w ;Kompatibilit�t (NEODESK etc.)
vs_clip_exit:		movem.l	(sp)+,d1-d5
						rts

vs_clip_off:		moveq		#0,d0
						moveq		#0,d1
						move.w	d4,d2
						move.w	d5,d3
						bra.s 	vs_clip_save

vs_clip_bitmap:	movem.l	d1-d7,-(sp)
						movem.w	(a1),d0-d3
						movem.w	bitmap_off_x(a6),d4-d7	;die Bitmap eingrenzendes Rechteck, bitmap_off_x, bitmap_off_y, bitmap_dx, bitmap_dy
						add.w		d4,d6
						add.w		d5,d7	
						tst.w		(a0)				;Clipping ein?
						bne.s		vs_clip_bx1min
						move.w	d4,d0
						move.w	d5,d1
						move.w	d6,d2
						move.w	d7,d3
vs_clip_bx1min:	cmp.w		d4,d0
						bge.s 	vs_clip_bx1max
						move.w	d4,d0
vs_clip_bx1max: 	cmp.w 	d6,d0
						ble.s 	vs_clip_by1min
						move.w	d6,d0
vs_clip_by1min: 	cmp.w		d5,d1
						bge.s 	vs_clip_by1max
						move.w	d5,d1
vs_clip_by1max: 	cmp.w 	d7,d1
						ble.s 	vs_clip_bx2min
						move.w	d7,d1
vs_clip_bx2min: 	cmp.w		d4,d2
						bge.s 	vs_clip_bx2max
						move.w	d4,d2
vs_clip_bx2max: 	cmp.w 	d6,d2
						ble.s 	vs_clip_by2min
						move.w	d6,d2
vs_clip_by2min: 	cmp.w		d5,d3
						bge.s 	vs_clip_by2max
						move.w	d5,d3
vs_clip_by2max: 	cmp.w 	d7,d3
						ble.s 	vs_clip_bexgx
						move.w	d7,d3
vs_clip_bexgx:		cmp.w 	d0,d2
						bge.s 	vs_clip_bexgy
						exg		d0,d2
vs_clip_bexgy:		cmp.w 	d1,d3
						bge.s 	vs_clip_bsave
						exg		d1,d3
vs_clip_bsave:		movem.w	d0-d3,clip_xmin(a6)
						movem.l	(sp)+,d1-d7
						rts


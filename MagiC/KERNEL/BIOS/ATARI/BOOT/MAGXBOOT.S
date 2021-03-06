**********************************************************************
*
* BOOTLADER FÜR Mag!X                             21.09.90
* ===================
*
*                             erstellt            17.10.91
*                             letzte Änderung     22.06.96
*
* Liest die Datei "*.RAM", stellt das Ende des Mag!X- Datenbereiches
*  fest und reloziert sie. Bei Vorhandensein von TT-RAM wird das
*  System an dessen Anfang geladen.
* Startet das Betriebssystem.
* Alle Meldungen erfolgen je nach System in Deutsch oder Englisch.
* Achtung: Die Flags "FLA" der PRG- Datei müssen gesetzt sein!!!
*
**********************************************************************

OUTSIDE   EQU  0              ; Programmlänge auf 32k-Pages
RESIDENT  EQU  1              ; resetfest
MODIFY    EQU  0              ; Modifikation nicht notwendig!

fstrm_beg EQU  $49e           ; ___md
os_chksum EQU  $486           ; trp14ret


     INCLUDE "OSBIND.INC"

     TEXT
     SUPER

 movea.l  4(sp),a1
 lea      stack(pc),sp
 movea.w  #$100,a0                 ; Programmlänge + $100
 adda.l   $c(a1),a0
 adda.l   $14(a1),a0
 adda.l   $1c(a1),a0
 move.l   a0,-(sp)
 move.l   a1,-(sp)
 clr.w    -(sp)
 gemdos   Mshrink
 adda.w   #$c,sp
 tst.l    d0                       ; KAOS liefert Fehlermeldung bei Mshrink()
 bmi      err

* Nationalität bestimmen und Titelzeile ausgeben

 clr.l    -(sp)
 gemdos   Super
 addq.l   #6,sp

 move.l   _p_cookies,d0
 beq.b    is_st
 move.l   d0,a0
cookie_loop:
 move.l   (a0),d0                  ; Kennung
 beq.b    is_st                    ; Ende-Kennung
 addq.l   #8,a0
 cmpi.l   #'_MCH',d0
 beq.b    cookie_mch
 cmpi.l   #'MagX',d0
 beq      err                      ; MagiX schon aktiv
 bra.b    cookie_loop
cookie_mch:
 move.l   -4(a0),machine
 bra.b    cookie_loop
is_st:

 move.l   _sysbase,a0
 move.l   os_base(a0),a0           ; RAM- Kopie enthält kein os_palmode
 move.w   os_palmode(a0),d0
 lsr.w    #1,d0
 move.w   d0,d4                    ; nationality

 lea      titel(pc),a0
 bsr      cconws_country

* auf Shift-Shift prüfen

 move.w   #-1,-(sp)
 bios     Kbshift
 addq.l   #4,sp
 andi.b   #3,d0
 subq.b   #3,d0
 bne.b    do_install
 lea      dont_install(pc),a0
err2:
 bsr      cconws_country
 lea      press_key(pc),a0
 bsr      cconws_country
 gemdos   Cconin
 gemdos   Pterm0

* Tatsächlich installieren
* Ermitteln der Dateidaten

do_install:
 clr.w    -(sp)
 pea      name(pc)
 gemdos   Fsfirst
 addq.l   #8,sp
 tst.l    d0
 bmi      err

 gemdos   Fgetdta
 addq.l   #2,sp
 move.l   d0,a0
 move.l   $1a(a0),d6               ; d6 = Dateilänge

* Öffnen der Datei: Handle d7

 clr.w    -(sp)
 pea      name(pc)
 gemdos   Fopen
 addq.l   #8,sp
 move.w   d0,d7
 bmi      err

* Einlesen der gesamten Datei

 move.l   d6,-(sp)
 gemdos   Malloc
 addq.l   #6,sp
 tst.l    d0
 ble      err
 move.l   d0,a6
 pea      (a6)
 move.l   d6,-(sp)
 move.w   d7,-(sp)
 gemdos   Fread
 adda.w   #12,sp
 move.l   d0,-(sp)
 move.w   d7,-(sp)
 gemdos   Fclose
 addq.w   #4,sp
 cmp.l    (sp)+,d6
 bne      err
 tst.l    d0
 bmi      err
 cmpi.w   #$601a,(a6)
 bne      err

* prüfen, ob MagiX, und a5 auf Ladeadresse

 move.l   $1c+os_magic(a6),a0
 lea      $1c(a6,a0.l),a0
 cmpi.l   #$87654321,(a0)+
 bne      err
 move.l   (a0)+,a5                 ; Ende der Variablen
 addq.l   #4,a0                    ; aes_start überspringen
 cmpi.l   #'MAGX',(a0)
 bne      err
 move.l   #$1000000,fstrm_beg
 cmpi.l   #$1357bd13,fstrm_valid
 bne.b    no_ttram
 cmpi.l   #$1080000,fstrm_top      ; mind. 512k TT-RAM ?
 bcs.b    no_ttram
 move.l   #$1000000,a5             ; Startadresse = Beginn TT-RAM

* MagiX modifizieren, verschieben und starten

no_ttram:
     IFNE MODIFY
 lea      $1c(a6),a1               ; a1 = Anfang des TOS
 lea      32000(a1),a2             ; max. 32000 Bytes durchsuchen
 move.b   1(a1),d0
 ext.w    d0                       ; Branch- Offset
 lea      6(a1,d0.w),a1
 cmpi.w   #$4e70,(a1)              ; "reset" ?
 bne.b    res_nores
 move.w   #$4e71,(a1)+             ; Befehl "reset" durch "nop" ersetzen
res_nores:
 sf       d1
res_loop:
 move.l   a1,a0                    ; Test auf $31415926,$0426
 cmpi.l   #$31415926,(a0)+
 bne.b    res_endloop
 cmpi.w   #$0426,(a0)+
 bne.b    res_endloop
 move.b   #$60,(a0)                ; "bra" statt "bne"
 bra.b    do_modify
res_endloop:
 addq.l   #2,a1
 cmpa.l   a2,a1
 bcs.b    res_loop
;clr      0                        ; fataler Fehler
     ENDIF

* MagiX modifizieren (TOS-Version und Bootlaufwerk)

do_modify:
 cmpi.l   #$00020000,machine
 bcs.b    ver_st
 move.w   #$0300,d0
 cmpi.l   #$00030000,machine
 bcs.b    ver_tt
 move.w   #$0400,d0
ver_tt:
 move.w   d0,os_version+$1c(a6)
ver_st:
 gemdos   Dgetdrv
 addq.l   #2,sp
;buf+1c ist das Programm ohne den Programmheader
;bei Offset 0x14 steht der Zeiger auf die AES-Variablen
 move.l   ($14+$1c)(a6),a0
 lea      $1c(a6,a0.l),a0
 lea      $7a(a0),a0
 cmpi.l   #'____',(a0)             ; Sicherheitsfrage für alten Kernel
 bne.b    do_reloc
 addi.b   #'A',d0
 move.b   d0,(a0)+
 move.b   #':',(a0)+
 lea      name(pc),a1
namecpy_loop:
 move.b   (a1)+,(a0)+
 bne.b    namecpy_loop

* MagiX relozieren

do_reloc:
 move.l   2(a6),d0                 ; Länge von TEXT
 add.l    6(a6),d0                 ; Länge von DATA
 move.l   d0,d5                    ; tatsächliche Länge von MagiX
 add.l    $e(a6),d0                ; Länge von SYM

 lea      $1c(a6,d0.l),a3          ; Beginn der Relocation- Daten
 lea      0(a6,d6.l),a2            ; Dateiende
 cmpa.l   a2,a3
 bcc.b    end_reloc
 lea      $1c(a6),a0
 move.l   (a3)+,d0                 ; erstes Relocation- Langwort
reloc_loop:
 add.l    d0,a0
 move.l   a5,d0
 add.l    d0,(a0)                  ; relozieren!
reloc_loop2:
 cmpa.l   a2,a3
 bhi.b    end_reloc                ; Dateiende!
 moveq    #0,d0
 move.b   (a3)+,d0
 beq.b    end_reloc                ; Ende der Tabelle
 cmpi.b   #1,d0
 bne.b    reloc_loop
 lea      254(a0),a0
 bra.b    reloc_loop2

end_reloc:
* Checksumme ermitteln
 lea      $1c(a6),a0
 lea      0(a0,d5.l),a1
 moveq    #0,d0
os_chkloop:
 add.l    (a0)+,d0
 cmpa.l   a0,a1
 bcs.b    os_chkloop
 move.l   d0,os_chksum

 ori.w    #$700,sr
;move.l   d3,$88                   ; Zeichensatzadresse für MAGIXVDI
 lea      toscopy(pc),a1           ; aktuelle Adresse der Startroutine
 lea      $600,a0                  ; neue Adresse der Startroutine
 move.w   #(err-toscopy)/4,d0
startcopy:
 move.l   (a1)+,(a0)+
 dbra     d0,startcopy
 jmp      $600                     ; Startroutine anspringen

toscopy:
 move.l   a5,a0
 lea      $1c(a6),a1
 move.l   d5,d0                    ; Länge
 lsr.l    #3,d0                    ; /8
 cmpa.l   a0,a1
 bhi      cpy_uloop
 beq      cpy_end
 adda.l   d5,a1
 adda.l   d5,a0
cpy_dloop:
 move.l   -(a1),-(a0)
 move.l   -(a1),-(a0)
 dbra     d0,cpy_dloop             ; sicherheitshalber einen mehr kopieren
 bra      cpy_end
cpy_uloop:
 move.l   (a1)+,(a0)+
 move.l   (a1)+,(a0)+
 dbra     d0,cpy_uloop

cpy_end:
 move.l   #$5555aaaa,$51a
     IFNE RESIDENT
 move.l   #$31415926,resvalid
 move.l   a5,resvector
     ENDIF
 cmpa.l   #$1000000,a5
 bne.b    cpy_st
 add.l    d5,fstrm_beg
     IFNE OUTSIDE
* Beginn des FastRAM hinter Mag!X auf 32k-Grenze
 move.l   fstrm_beg,d0
 add.l    #$00007fff,d0            ; 32k-1 addieren
 andi.w   #$8000,d0                ; auf volle 32k gehen
 move.l   d0,fstrm_beg
     ENDIF
 bra.b    startit
cpy_st:
 add.l    d5,os_membot(a5)         ; OS- Länge auf TPA- Beginn addieren
     IFNE OUTSIDE
* Beginn des ST-RAM hinter Mag!X auf 32k-Grenze
 move.l   os_membot(a5),d0
 add.l    #$00007fff,d0            ; 32k-1 addieren
 andi.w   #$8000,d0                ; auf volle 32k gehen
 move.l   d0,os_membot(a5)
     ENDIF
 move.l   os_magic(a5),a0
 cmpi.l   #$87654321,(a0)+
 bne.b    startit
 add.l    d5,(a0)
     IFNE OUTSIDE
* Beginn des ST-RAM hinter Mag!X-AES auf 32k-Grenze
 move.l   (a0),d0
 add.l    #$00007fff,d0            ; 32k-1 addieren
 andi.w   #$8000,d0                ; auf volle 32k gehen
 move.l   d0,(a0)
     ENDIF
startit:
 clr.l    _hz_200                  ; Zeitpunkt des Kaltstarts festlegen
 jmp      (a5)                     ; MagiX starten


err:
 gemdos   Pterm0


**********************************************************************
*
* void cconws_country(a0 = char *s)
*
* in d4 steht die Nationalität
* Aufbau der Zeichenkette, auf die a0 zeigt:
* char n1,n2,...,-1      Nationalitäten für erste Zeichenkette
* char s1[]              erste Zeichenkette
* char n3,n4,...,-1      Nationalitäten für zweite Zeichenkette
* char s2[]              zweite Zeichenkette
* char -1                Abschluß
* char defs[]            Defaultstring (i.a. englisch)
*
**********************************************************************

cconws_country:
 bsr      _chk_nat
 bne.b    cconws_country
cconws:
 move.l   a0,-(sp)
 gemdos   Cconws
 addq.l   #6,sp
 rts

_chk_nat:
 move.b   (a0)+,d0
 bmi.b    _chk_ende                ; Abschlußbyte, Default verwenden
_chk_nxt:
 cmp.b    d0,d4                    ; unsere Nationalität ?
 beq.b    _chk_found
 move.b   (a0)+,d0                 ; nächste Nationalität
 bge.b    _chk_nxt                 ; weiter vergleichen
_chk_nxtstr:
 tst.b    (a0)+                    ; Zeichenkette überspringen
 bne.b    _chk_nxtstr
 moveq    #1,d0                    ; nicht gefunden
 rts
_chk_found:
 tst.b    (a0)+
 bge.b    _chk_found
_chk_ende:
 moveq    #0,d0                    ; gefunden, a0 ausdrucken
 rts

machine:
 DC.L     0
titel:
 DC.B     -1
     IFNE OUTSIDE
 DC.B     CR,LF,'MagiC- BOOTER, © 1990-96 Andreas Kromke'
 DC.B     CR,LF,'Virtual Memory Version',CR,LF,0
     ELSE
 DC.B     CR,LF,'MagiC- BOOTER, © 1990-96 Andreas Kromke',CR,LF,0
     ENDIF

dont_install:
 DC.B     FRG,SWG,-1
 DC.B     'Shift-Shift: MagiC nicht installiert',CR,LF,0
 DC.B     FRA,-1
 DC.B     'Shift-Shift: MagiC pas installé',CR,LF,0
 DC.B     -1
 DC.B     'Shift-Shift: MagiC not installed',CR,LF,0

press_key:
 DC.B     FRG,SWG,-1
 DC.B     LF,'Taste drücken!',CR,LF,0
 DC.B     FRA,-1
 DC.B     LF,'Appuyez sur une touche!',CR,LF,0
 DC.B     -1
 DC.B     LF,'Press any key!',CR,LF,0

name:
 DC.B     '\magic.ram',0
 DCB.B    10,0

     EVEN

stack     EQU  *+800

     BSS

 DS.B     800

     END

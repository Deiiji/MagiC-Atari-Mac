					.IMPORT	cpu020
					
					.EXPORT	_lmul
					.EXPORT	_ldiv
					.EXPORT	_uldiv
					.EXPORT	_ulmod
					.EXPORT	_ulmul
;
; unsigned long ullmul(d0 = unsigned long fak1, d1 = unsigned long fak2)
;
; zerst”rt d0/d1/d2
_ulmul:
 move.l   d0,d2
 swap     d2
 tst.w    d2
 bne.b    lbl100
 move.l   d1,d2
 swap     d2
 tst.w    d2
 bne.b    lblF6
 mulu     d1,d0
 rts
lblF6:
 mulu     d0,d2
 swap     d2
 mulu     d1,d0
 add.l    d2,d0
 rts
lbl100:
 mulu     d1,d2
 swap     d2
 mulu     d1,d0
 add.l    d2,d0
 rts

;Langwortmultiplikation
;Eingaben:
;d0.l Faktor 1
;d1.l Faktor 2
;Ausgaben:
;d0.l Produkt
_lmul:			tst.w		cpu020				;mindestens 68020?
					beq.b		_lmul_68k
					MC68020
					muls.l	d1,d0
					MC68000
					rts

;Langwortmultiplikation fr 68000er, šberlauf wird nicht beachtet!
;Eingaben:
;d0.l Faktor 1
;d1.l Faktor 2
;Ausgaben:
;d0.l Produkt
_lmul_68k:		move.l	d3,-(sp)				;sichern

					move.l	d0,d3					;erstes Langwort positiv?
					bpl.b		_lmul_l1_pos
					neg.l		d0

_lmul_l1_pos:	eor.l		d1,d3					;d3 => 0: Produkt positiv, < 0: Produkt negativ
					tst.l		d1						;zweites Langwort positiv?
					bpl.b		_lmul_l2_pos
					neg.l		d1

_lmul_l2_pos:	move.l	d0,d2
					swap		d2
					tst.w		d2						;high_1: Bit 31..16 des ersten Langworts Null?
					beq.b		_lmul_high_1z
					mulu		d1,d2					;high_1 * low_2 (Bit 47..16)
					bra.b		_lmul_low			;wir gehen davon aus, daž auch high_2 Null ist

_lmul_high_1z:	move.l	d1,d2
					swap		d2						
					tst.w		d2						;high_2: Bit 31..16 des zweiten Langworts Null?
					beq.b		_lmul_high_2z
					mulu		d0,d2					;low_1 * high_2 (Bit 47..16)

_lmul_low:		mulu		d1,d0					;low_1 * low_2
					swap		d2						;Annahme: Bit 47..32 sind Null
					add.l		d2,d0
					bra.b		_lmul_sign

_lmul_high_2z:	mulu		d1,d0					;low_1 * low_2

_lmul_sign:		tst.l		d3						;Produkt negativ?
					bpl.b		_lmul_exit
					neg.l		d0						;Produkt negativieren

_lmul_exit:		move.l	(sp)+,d3
					rts


;Langwortdivision
;Eingaben:
;d0.l Dividend
;d1.l Divisor
;Ausgaben:
;d0.l	Quotient
_ldiv:			tst.w		cpu020				;mindestens 68020?
					beq.b		_ldiv_68k
					MC68020
					divsl.l	d1,d1:d0
					MC68000
					rts

_ldiv_68k:		
					move.l	d3,-(sp)				;sichern

					move.l	d0,d3					;erstes Langwort positiv?
					bpl.b		_ldiv_l1_pos
					neg.l		d0

_ldiv_l1_pos:	eor.l		d1,d3					;d3 => 0: Produkt positiv, < 0: Produkt negativ
					tst.l		d1						;zweites Langwort positiv?
					bpl.b		_ldiv_l2_pos
					neg.l		d1

_ldiv_l2_pos:	bsr.b		uldiv

					tst.l		d3						;Quotient negativ?
					bpl.b		_ldiv_exit
					neg.l		d0						;Quotient negativieren

_ldiv_exit:		move.l	(sp)+,d3
					rts


;Vorzeichenlosen 32-Bit-Dividendt durch 32-Bit-Divisor teilen
;Vorgaben:
;Register d0-d2/a0 werden ver„ndert
;Eingaben:
;d0.l Dividend
;d1.l Divisor
;Ausgaben:
;d0.l Quotient
;d1.l Rest

uldiv:				moveq		#1,d2
						swap		d2
						cmp.l		d2,d1	;32-Bit-Divisor?
						bhs.b		uldiv3232
						swap		d0
						cmp.w		d1,d0	;erweiterte 32/16-Bit Division?
						bge.b		uldiv3216
						swap		d0
						divu     d1,d0
						move.l   d0,d1
						eor.w		d0,d1	;unteres Wort des Rests l”schen
						eor.l		d1,d0	;oberes Wort des Quotienten l”schen
						swap		d1		;Rest
						rts

uldiv3216:			move.l	d0,d2
						clr.w		d2
						eor.l		d2,d0	;oberes Wort des Vorkommateils l”schen
						swap		d2		;Nachkommateil
						divu		d1,d0	;Vorkommateil teilen
						movea.w	d0,a0	;Vorkommateil des Quotienten retten
						move.w	d2,d0	;Rest + Nachkommateil
						divu		d1,d0	;Nachkommateil teilen
						swap		d0
						moveq		#0,d1
						move.w	d0,d1	;Rest
						move.w	a0,d0	;Vorkommateil des Quotienten
						swap		d0		;Quotient
						rts

uldiv3232:			movea.l  d1,a0
						swap     d0
						moveq    #0,d1
						move.w   d0,d1	;High-Word des zu teilenden Worts
						clr.w    d0
						moveq    #15,d2
						add.l    d0,d0
						addx.l   d1,d1	;Rest
uldiv3232_loop:	sub.l    a0,d1
						bcc.b    uldiv3232_addx
						add.l    a0,d1	
uldiv3232_addx:	addx.l   d0,d0	;Bit setzen, wenn d0 kleiner als der Divisor ist
						addx.l   d1,d1	;Bit bei šberlauf von d0 setzen (Rest)
						dbf      d2,uldiv3232_loop
						not.w    d0
						roxr.l   #1,d1
						rts

;Vorzeichenlose Langwortdivision
;Eingaben:
;d0.l Dividend
;d1.l Divisor
;Ausgaben:
;d0.l	Quotient
_uldiv:			tst.w		cpu020				;mindestens 68020?
					beq.b		uldiv
					MC68020
					divul.l	d1,d1:d0
					MC68000
					rts


_ulmod:			tst.w		cpu020				;mindestens 68020?
					beq.b		ulmod_68k
					MC68020
					divul.l	d1,d1:d0
					move.l	d1,d0					;Rest zurckliefern
					MC68000
					rts
ulmod_68k:
 move.l   d1,d2
 swap     d2
 tst.w    d2
 bne.s    lbl2BEA
 move.l   d0,d2
 swap     d2
 tst.w    d2
 bne.s    lbl2BD8
 divu     d1,d0
 clr.w    d0
 swap     d0
 rts

lbl2BD8:
 clr.w    d0
 swap     d0
 swap     d2
 divu     d1,d0
 move.w   d2,d0
 divu     d1,d0
 clr.w    d0
 swap     d0
 rts

lbl2BEA:
 movea.l  d1,a0
 move.l   d0,d1
 clr.w    d0
 swap     d0
 swap     d1
 clr.w    d1
 moveq    #$f,d2
 add.l    d1,d1
 addx.l   d0,d0
lbl2BFC:
 sub.l    a0,d0
 bcc.s    lbl2C02
 add.l    a0,d0
lbl2C02:
 addx.l   d1,d1
 addx.l   d0,d0
 dbf      d2,lbl2BFC
 roxr.l   #1,d0
 rts




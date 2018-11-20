;Tabulatorgr”že:	3
;Kommentare:																;ab Spalte 60


						EXPORT	MSys										;Zeiger auf die Austausch-Variablen zum Mac
						
						TEXT

						nop


						DATA

						BSS

MSys:					


						DS.l	1024

						END

;.C [-B -P]			;Absolute Adressierung zwischen Modulen benutzen, DRI-Objektformat erzeugen

;.S [-B]				;DRI Objektformat erzeugen

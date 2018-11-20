/* Ausgaben k”nnen in English oder Deutsch erfolgen */
/* falls nichts defniert wird, ist Deutsch Voreinstellung */
#define	GERMAN

#ifndef ENGLISH
	#ifndef GERMAN
		#define GERMAN
	#endif
#endif

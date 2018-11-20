
typedef struct
{

	void		*disp_addr1;		/* Zeiger auf NVDI-Dispatcher	*/
	void		*disp_addr2;		/*	Zeiger auf Treiber-Dispatcher */
	WORD		wk_handle;		/*	Handle des Treibers */

/* Koordinatensystem	*/
	WORD		driver_id;		/*	10 GerÑte-ID */
	WORD		pixel_width; 	/*	12 Breite eines Pixels in Mikrometern */
	WORD		pixel_height;	/*	14 Hîhe eines Pixels in Mikrometern */
	WORD		res_x; 			/*	16 Rasterbreite -1 */
	WORD		res_y; 			/*	18 Rasterhîhe -1 */
	WORD		colors;			/*	20 Anzahl der Farbstifte -1 */
	WORD		res_ratio;		/*	22 SeitenverhÑltnis <0: vertikal stauchen ; >0 vertikal dehnen */

	BYTE		driver_type;	/* 24 */
	BYTE		free25;
	WORD		driver_device;	/* 26 */
	WORD		free28;
	
	BYTE		input_mode;		/* 30 */
	BYTE		free31;
	
	LONG		free32;			/* free32-48 werden z.Z. benutzt */
	LONG		free36;
	LONG		free40;
	LONG		free44;
	LONG		free48;
	
/* Begrenzung der Grafikkommandos */
	WORD		clip_xmin;		/*	52 Minimum - x */
	WORD		clip_ymin;		/*	54 Minimum - y	*/
	WORD		clip_xmax;		/* 56	Maximum - x	*/
	WORD		clip_ymax;		/*	58	Maximum - y */

/* Logische VerknÅpfung der Grafikkommandos */
	WORD		wr_mode;			/*	60 Grafikmodus */

	WORD		free62;			/* 62 */
	WORD		free64;			/* 64 */
	WORD		free66;			/* 66 */
	WORD		free68;			/* 68 */
	
/* Liniendarstellung */
	WORD		l_color;			/*	70	Linienfarbe */
	WORD		l_width;			/*	72	Linienbreite */
	WORD		l_start;			/*	74	Linienanfang */
	WORD		l_end;			/*	76 Linienende */
	WORD		l_lastpix;		/*	78 1 = letzten Punkt nicht setzen */
	WORD		l_style;			/*	80 Linienstil */
	WORD		l_styles[6];	/* 82	Linienmuster */
	WORD		l_sdstyle;		/* 94 selbstdefinierter Linienstil */

	WORD		bez_on; 			/*	96 Beziers an? */
	WORD		bez_qual; 		/*	98 BezierqualitÑt von 0-5 */

/* Textdarstellung */
	WORD		t_color;			/*	100 Textfarbe */

	WORD		free102;
	BYTE		free105;
	
	BYTE		t_mapping;		/*	105 */
	WORD		t_first_ade; 	/*	106 Nummer des ersten Zeichens */
	WORD		t_ades;			/*	108 Anzahl der Zeichen -1 */
	WORD		t_space_index;	/* 110 Index des Leerzeichens (Trennzeichen bei v_justified) */
	WORD		t_unknown_index;	/* 112 Index fÅr ein nicht bekanntes Zeichen (wird bei falschem Index ausgegeben) */
	BYTE		t_prop;			/* 114 1: Font ist proportional */
	BYTE		t_grow;			/* 115 -1: vergrîûern +1: verkleinern (nur Bitmap-Fonts)  */
	WORD		t_no_kern;		/* 116 Anzahl der Kerning-Paare (0: keine Kerning-Paare vorhanden; < 0: Kerning ausgeschaltet) */
	WORD		t_no_track;		/* 118 Anzahl der Track-Kerning-Paare */

	WORD		t_hor; 			/*	120 horizontale Ausrichtung */
	WORD		t_ver; 			/*	122 vertikale Ausrichtung */

	WORD		t_base;			/*	124 Oberkante<->Basislinie */
	WORD		t_half;			/*	126 Oberkante<->Halblinie */
	WORD		t_descent;		/*	128 Oberkante<->Buchstabenoberkante */
	WORD		t_bottom;		/*	130 Oberkante<->Unterkante */
	WORD		t_ascent; 		/*	132 Oberkante<->Buchstabenunterkante */
	WORD		t_top; 			/*	134 Oberkante<->Oberkante */

	WORD		free136;			/* 136 */
	WORD		free138;			/* 138 */


	WORD		t_left_off;		/*	140 linker Offset bei Kursivschrift */
	WORD		t_whole_off; 	/*	142 Verbreiterung bei Kursivschrift */
	WORD		t_thicken;		/*	144 Verbreiterung bei Fettschrift */
	WORD		t_uline;			/*	146 Dicke der Unterstreichung */
	WORD		t_ulpos;			/*	148 Abstand der Unterstreichung von der Zeichenzellenoberkante */

	WORD		t_width;			/*	150 Textbreite */
	WORD		t_height; 		/*	152 Texthîhe */
	WORD		t_cwidth;		/*	154 Zellenbreite */
	WORD		t_cheight;		/*	156 Zellenhîhe */
	WORD		t_point_last;	/* 158 letzte eingestellte Punkthîhe */

	LONG		t_scale_width;	/* 160 */
	LONG		t_scale_height;	/* 164 */
	WORD		t_rotation;		/*	168 Textrotation */
	WORD		t_skew;			/*	170 Neigung gegen den Uhrzeigersinn in 1/10 Grad */
	WORD		t_effects;		/*	172 Texteffekte */
	WORD		t_light_pct;	/* 174 Grauwert */
	WORD		*t_light_fill;	/* 176 Zeiger auf Grauraster */

	WORD		free180;			/* 180 */
	WORD		free182;			/* 182 */
	WORD		free184;			/* 184 */
	WORD		free186;			/* 186 */
	WORD		free188;			/* 188 */

/* Musterdarstellung */
	WORD		f_color;			/*	190 FÅllfarbe */
	WORD		f_interior;		/*	192 FÅlltyp */
	WORD		f_style;			/*	194 Musterindex */
	WORD		f_perimeter; 	/*	196 Flag fÅr Umrahmung */
	WORD		*f_pointer;		/*	198 Zeiger aufs aktuelle FÅllmuster */
	WORD		f_planes; 		/*	202 Planeanzahl des Musters */
	WORD		*f_fill0;		/* 204 */
	WORD		*f_fill1;		/* 208 */
	WORD		*f_fill2;		/* 212 */
	WORD		*f_fill3;		/* 216 */
	WORD		*f_spointer;		/*	220 Zeiger aufs selbstdefinierte FÅllmuster */
	WORD		f_splanes; 		/*	224 Planeanzahl des selbstdefinierten Musters */

	WORD		free226;			/* 226 */
	WORD		free228;			/* 228 */

/* Markerdarstellung */
	WORD		m_color;			/*	230 Markerfarbe */
	WORD		m_type;			/* 232 Markertyp */
	WORD		m_width;			/* 234 Markerbreite */
	WORD		m_height;		/* 236 Markerhîhe */
	WORD		*m_data;			/* 238 Zeiger auf die Markerdaten */

	WORD		free242;			/* 242 */
	WORD		free244;			/* 244 */
	WORD		free246;			/* 246 */
	WORD		free248;			/* 248 */

	WORD		t_number; 		/*	250 Zeichensatznummer */
	BYTE		t_font_type;	/*	252 Art des Fonts */
	BYTE		free253;
	WORD		t_bitmap_gdos;	/* 254 */
	void		*t_bitmap_fonts;	/* 256 */
	void		*t_res_ptr1;	/* 260 */
	void		*t_res_ptr2;	/* 264 */
	WORD		t_res_xyz1;		/* 268 */

/* Zeiger fÅr Vektorschrift */
	void		*t_FONT_ptr;		/*	270 Zeiger auf die aktuelle FONT-Struktur */
	UWORD		*t_asc_map;			/*	274 Zeiger auf die Tabelle ASCII zu Index */
	void		*t_BAT_ptr;			/*	278 Zeiger auf die Attribute-Tabelle (muû nicht gÅltig sein) */
	void		*t_bin_table;		/* 282 Zeiger auf eine gÅltige Schnellzugriffstabelle oder 0 */

	WORD		free286;			/* 286 */
	WORD		free288;			/* 288 */

	WORD		free290;			/* 290 */
	WORD		free292;			/* 292 */
	WORD		free294;			/* 294 */
	WORD		free296;			/* 296 */
	WORD		free298;			/* 298 */

/* Maûe fÅr Vektorschriften */
	LONG		t_width32;			/*	300 Breite in 1/65536 Pixeln (relativer Wert) */
	LONG		t_height32;			/*	304 Hîhe in 1/65536 Pixeln */
	LONG		t_point_width;		/*	308 Breite in 1/65536 Punkten */
	LONG		t_point_height;	/*	312 Hîhe in 1/65536 Punkten */

	WORD		t_track_index;		/* 316 Nummer des Track-Index */
	LONG		t_track_offset;	/* 318 Offset zwischen mehreren Zeichen in 1/65536 Pixel	*/

	LONG		t_left_off32;		/* 322 linker Offset bei Kursivschrift */
	LONG		t_whole_off32;		/* 326 Verbreiterung bei Kursivschrift */
	LONG		t_thicken32;		/* 330 x-Anteil der String-Breite */

	WORD		free334;				/* 334 */
	WORD		free336;				/* 336 */
	WORD		free338;				/* 338 */
/* temporÑre Daten fÅr Vektorschrift */
	LONG		t_thicken_x;		/* 340 x-Anteil der String-Breite */
	LONG		t_thicken_y;		/* 344 y-Anteil der String-Breite */
	LONG		t_char_x;			/* 348 x-Anteil der String-Breite */
	LONG		t_char_y;			/* 352 y-Anteil der String-Breite */
	LONG		t_word_x;			/* 356 x-Anteil der String-Breite */
	LONG		t_word_y;			/* 360 y-Anteil der String-Breite */
	LONG		t_string_x;			/* 364 x-Anteil der String-Breite */
	LONG		t_string_y;			/* 368 y-Anteil der String-Breite */
	LONG		t_last_x;			/* 372 x-Anteil der Breite des letzten Zeichens */
	LONG		t_last_y;			/* 376 y-Anteil der Breite des letzten Zeichens */

	WORD		t_gtext_spacing;	/*	380 Gibt an, ob Zeichenweiten wie bei v_gtext benutzt werden sollen */

	WORD		t_xadd;				/* 382 */
	WORD		t_yadd;				/* 384 */

	WORD		free386;			/* 386 */
	WORD		free388;			/* 388 */

	WORD		free390;			/* 390 */
	WORD		free392;			/* 392 */
	WORD		free394;			/* 394 */
	WORD		free396;			/* 396 */
	WORD		free398;			/* 398 */

/* Bitmap-Beschreibung */
	DEVICE_DRIVER	*device_drvr;	/* 400 */
	DRIVER	*bitmap_drvr;		/*	404 Zeiger auf den Offscreen-Treiber-Struktur */
	WORD		free408;				/* 408 */

	ORGANISATION	bitmap_info;	/* 410 */
/*
	LONG		bitmap_colors;		/*	410 gleichzeitig darstellbare Farben */
	WORD		bitmap_planes;		/*	414 Anzahl der Planes */
	WORD		bitmap_format;		/*	416 Pixelformat */
	WORD		bitmap_flags;		/*	418 Bitreihenfolge (wenn das oberste Bit gesetzt ist, wurde fÅr die Bitmap Speicher angefordert) */
	WORD		bitmap_res1;		/*	420 reserviert */
	WORD		bitmap_res2;		/*	422 reserviert */
	WORD		bitmap_res3;		/*	424 reserviert */
*/
	WORD		free426;				/* 426 */
	WORD		free428;				/* 428 */

	WORD		*bitmap_addr; 		/*	430 Zeiger auf die Bitmap */
	WORD		bitmap_width;		/*	434 Bytes pro Zeile */
	WORD		planes;				/*	436 Anzahl der Bildebenen -1 */
	WORD		bitmap_off_x;		/*	438 x-Offset fÅr Koordinaten */
	WORD		bitmap_off_y;		/*	440 y-Offset fÅr Koordinaten */
	WORD		bitmap_dx;			/*	442 Breite der Bitmap - 1 */
	WORD		bitmap_dy;			/*	444 Hîhe der Bitmap - 1 */
	LONG		bitmap_len;			/*	446 LÑnge der Bitmap in Bytes */
	

}WK;

#if offsetof( WK, t_gtext_spacing ) != 380
	Fehler!!
#endif
#if offsetof( WK, planes ) != 436
	Fehler!!
#endif

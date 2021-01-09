;Podprogramy przerwan sprzetowych z licznika i klawiatury
; Struktura do opisu deskryptorów segmentów
;Wykorzystano nastêpujace Ÿród³a:
;P.I.Rudakov, K.G.Finogenov „Jazyk Assemblera uroki programirowania” Dialog MIFI (w jêzyku rosyjskim)
;http://win32assembly.online.fr/tutorials.html
;http://wasm.ru

struc descr lim,base_l,base_m,attr_1,attr_2,base_h
{
	.lim	dw	lim	; (1) 
	.base_l dw	base_l	; (2) 
	.base_m db	base_m	; (3) 
	.attr_1 db	attr_1	; (4) 
	.attr_2 db	attr_2	; (5) 
	.base_h db	base_h	; (6) 
}

;Struktura do opisu furtek pulapek
struc trap offs_l,sel,cntr,dtype,offs_h
{
	.offs_l	dw	offs_l	; (7) Offset proced. obs³ugi przerwania (bity 0..15)
	.sel	dw	sel		; (8) Selektor segmentu rozkazów 
	.cntr	db	cntr	; (9) Niewykorzystany
	.dtype	db	dtype	; (10) Typ furtki - pu³apka
	.offs_h	dw	offs_h	; (11) Offset proced. obs³ugi przerwania (bity 16..31) 
}

format	MZ              ; (12)format pliku wyjœciowego 
stack	stk:256         ; (13)ustawienie wielkoœci stosu
entry	text:main       ; (14)punkt wejœcia do programu

;Segment danych
segment data_16 use16

; Tablica globalnych deskryptorów GDT

gdt_null descr		0,		0,	0,	0,	0,	0; (15)Deskryptor zerowy (null, dummy)
gdt_data descr		data_size-1,	0,	0,	92h,	0,	0; (16)Deskryptor segmentu danych
gdt_code descr		code_size-1,	0,	0,	98h,	0,	0     ; (17)Deskryptor segmentu kodu
gdt_stack descr 	0,		0,	0,	96h,	0,	0	; (18)Deskryptor segmentu stosu
gdt_screen descr	3999,		8000h,	0Bh,	92h,	0,	0  ; (19)Deskryptor segmentu Video
gdt_size=$-gdt_null

;Tablica IDT
exception0	trap	exc0,	16,	0,	8Fh,	0	;(21)Deskryptor wyj¹tku  	0
exception1	trap	dummy,	16,	0,	8Fh,	0	;(22)Deskryptor wyj¹tku  	1
exception2	trap	dummy,	16,	0,	8Fh,	0	;(23)Deskryptor wyj¹tku  	2
exception3	trap	exc3,	16,	0,	8Fh,	0	;(24)Deskryptor wyj¹tku  	3
exception4	trap	dummy,	16,	0,	8Fh,	0	;(25)Deskryptor wyj¹tku  	4
exception5	trap	dummy,	16,	0,	8Fh,	0	;(26)Deskryptor wyj¹tku  	5
exception6	trap	dummy,	16,	0,	8Fh,	0	;(27)Deskryptor wyj¹tku  	6
exception7	trap	dummy,	16,	0,	8Fh,	0	;(28)Deskryptor wyj¹tku  	7
exception8	trap	dummy,	16,	0,	8Fh,	0	;(29)Deskryptor wyj¹tku  	8
exception9	trap	dummy,	16,	0,	8Fh,	0	;(30)Deskryptor wyj¹tku  	9
exception10	trap	exc10,	16,	0,	8Fh,	0	;(31)Deskryptor wyj¹tku  	10
exception11	trap	exc11,	16,	0,	8Fh,	0	;(32)Deskryptor wyj¹tku  	11
exception12	trap	exc12,	16,	0,	8Fh,	0	;(33)Deskryptor wyj¹tku  	12
exception13	trap	exc13,	16,	0,	8Fh,	0	;(34)Deskryptor wyj¹tku  	13
exception14	trap	dummy,	16,	0,	8Fh,	0	;(35)Deskryptor wyj¹tku  	14
exception15	trap	dummy,	16,	0,	8Fh,	0	;(36)Deskryptor wyj¹tku  	15(którego brak)
exception16	trap	dummy,	16,	0,	8Fh,	0	;(37)Deskryptor wyj¹tku  	16
exception17	trap	dummy,	16,	0,	8Fh,	0	;(38)Deskryptor wyj¹tku  	17
	rept 62 {
		dw	dummy
		dw	16
		db	0
		db	8Fh
		dw	0
		}
interrupt32	trap	new_08,	16,	0,	8Eh,	0	;(38)Deskryptor przerwania 32
interrupt33	trap	new_09,	16,	0,	8Eh,	0	;(39)Deskryptor przerwania 33
idt_size=$-exception0                           ;(40) Rozmiar tablicy IDT

;Rozne dane programu
pdescr 	df 0                                    ;(41) Pseudodeskryptor dla rozkazow lgdt i lidt
msg	db 27, '[31;42m Powrocilismy do trybu rzeczywistego',27, '[0m$' ;(42)
string	db  '**** ****:******** **** ****'      ;(43) Szablon linii diagnostyki
;            0    5   10   15   20   25   Pozycja w szablonie
len=$-string 			                        ;(44) D^ugosc linii
mark_08	dw 1600 		                        ;(45) Pozycja dla wyprowadzenia z new_08
time_08	db 0 	                                ;(46) Licznik przerwan
mark_09 dw 1760
master	db 0                                    ;(47) Maska przerwan dla kontrolera Master
slave	db 0                                    ;(48) Maska przerwan dla kontrolera Slave
maleduze db 0
znaki db 'cvbnmCVBNM'
data_size=$-gdt_null                            ;(49) Rozmiar segmentu danych



;Segment rozkazów
segment text use16                              ;(50)segment o adresacji 16 bitowej
  
exc0:               ;(51)obs³uga wyj¹tku 0
	mov	AX, 0		; (49)wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (50)wyjœcie

exc3:               ;(54) obs³uga wyj¹tku 3
	mov	AX, 3		; (52) wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (53) wyjœcie

exc10:              ;(57) obs³uga wyj¹tku 10
	mov	AX,0Ah		; (55) wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (56) wyjœcie

exc11:              ;(60) obs³uga wyj¹tku 11
	mov	AX,0Bh		; (58) wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (59) wyjœcie

exc12:              ;(63) obs³uga wyj¹tku 12
	mov	AX,0Ch		; (61) wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (62) wyjœcie

exc13:              ;(66) obs³uga wyj¹tku 13
	pop	EAX         ; (64)zdjêcie ze stosu kodu b³êdu
	mov	SI,string+19; (65)przekszta³cenie i wyœwietlenie
	call	wrd_asc ; (66)
	pop	EAX         ; (67)zdjêcie ze stosu EIP 
	mov	SI,string+14; (68)przekszta³cenie i wyœwietlenie
	call	wrd_asc ; (69)
	shr	EAX,16      ; (70)
	mov	SI,string+10; (71)
	call	wrd_asc ; (72)
	pop	EAX         ; (73)zdjêcie ze stosu CS
	mov	SI,string+5 ; (74)przekszta³cenie i wyœwietlenie
	call	wrd_asc ; (75)

	mov	AX,0Dh		; (76) wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (77) wyjœcie
	
dummy:              ;(81) obs³uga pozosta³ych wyj¹tków 
	mov 	AX,5555h; (79)symboliczny kod pozosta³ych wyj¹tków
	jmp 	home	; (80) wyjœcie


;Procedura obs^ugi przerwania od zegara 
new_08: 
	           ;(84)
	push	AX      ;(85)Zachowamy wartosci wykorzystywanych rejestrow
	push	BX      ;(86)
	test	[time_08],03    ;(87)Zmniejszenie 4-krotne czestotliwosci 
	jnz	skip        ;(88) wyprowadzania symbolu na ekran
	mov	AL,21h      ;(89)Symbol "!"
	mov	AH,71h      ;(90) Kolor
	mov	BX,[mark_08];(91) Pozycja na ekranie
;	mov	[ES:BX],AX  ;(92) Wys^ac symbol do pamieci Wideo
;	add	[mark_08],2 ;(93) Przesuniecie na ekranie
skip:	inc	[time_08];(94) Zliczanie  przerwan 
	mov	AL,20h       ;(95) EOI kontrolera
	out	20h,AL       ;(96) Master
	pop	BX           ;(97) Przywracamy wartosci 
	pop	AX           ;(98) przechowanych zawartosci rejestrow
	db	66h          ;(99) Powrot
	iret             ;(100) do programu


;Procedura obs^ugi przerwania od klawiatury
new_09:
	push	AX       ;(101) Zachowamy AX
	in	AL,60h       ;(102) Uzyskamy wprowadzony symbol
	cmp	AL, 1dh		;Lewy ctrl - tu zmienic
	je	sss
	cmp	AL, 09dh	;Lewy ctrl puszczony
	je	nnn
	cmp	AL, 03Ah
	je	sss
	cmp	AL, 0BAh
	je	nnn 
	jmp	fff
sss:	inc	[ds:maleduze]
	jmp	dalej
nnn:	dec 	[ds:maleduze]
	jmp	dalej
fff:	cmp	AL,	80h
	ja	dalej 
	cmp	AL,	2dh
	jna	dalej
	sub	AL, 2eh
	cmp     AL, 4
	ja	dalej
	mov 	bx, znaki
	xor 	ah,	ah
	add	bx,	ax
	test	byte[ds:maleduze],	2
	jz	x1
	add	bx,5
x1:	mov	AL, [ds:bx]
	mov	AH, 71h
	mov	BX, [mark_09]
	mov	[ES:BX], AX
	add	[mark_09], 2
dalej:	in	AL,61h       ;(103) Uzyskamy zawartosc portu B
	or	AL,80h       ;(104) Ustawieniem bardziej znaczacego bitu
	out	61h,AL       ;(105) a nastepnie poprzez jego reset 
	and	AL,7Fh       ;(106) poinformujemy kontroler o 
	out	61h,AL       ;(107) uzyskaniu skan-kodu symbolu
	mov	AL,20h       ;(108) Rozkaz EOI konca 
	out	20h,AL       ;(109) przerwania
	pop	AX           ;(110) Przywracamy AX
	db	66h          ;(111) Powrot do programu
	iret             ;(112)


main:
	xor	EAX,EAX      ;(113)oczyœciæ EAX
	mov	AX,stk       ;(114)£adowanie adresu segmentu stosu
	mov	SS,AX        ;(115)do rejestru segmentowego
	mov	SP,256       ;(116)Wartoœæ pocz¹tkowa wskaŸnika stosu
	mov	AX,data_16   ;(117)£adowanie do DS adresu  
	mov	DS,AX        ;(118)segmentu danych

;Obliczenie i za^adowanie do GDT liniowego adresu segmentu danych
	shl	EAX,4			    ; (28) 
	mov	EBP,EAX 		; (29) 
	mov	[gdt_data.base_l],AX	; (30) 
	shr	EAX, 16 		    ; (31) 
	mov	[gdt_data.base_m],AL	; (32)	

;Obliczenie i za³adowanie do GDT liniowego adresu segmentu rozkazow
	xor	EAX,EAX 		; (33) 
	mov	AX,CS			    ; (34) 
	shl	EAX,4			    ; (35) 
	mov	[gdt_code.base_l],AX	; (36)
	shr	EAX,16			    ; (37)
	mov	[gdt_code.base_m],AL	; (38)

;Obliczenie i za^adowanie do GDT liniowego adresu segmentu stosu
	xor	EAX,EAX 		; (39)
	mov	AX, SS			; (40)
	shl	EAX,4			    ; (41)
	mov	[gdt_stack.base_l],AX	; (42)
	shr	EAX,16			    ; (43)
	mov	[gdt_stack.base_m],AL	; (44)

;Przygotujemy pseudodeskryptor pdescr z za^adujemy rejestr GDTR
	mov	dword [pdescr+2],EBP	 ; (45)
	mov	word [pdescr],gdt_size-1 ; (46)
	lgdt	fword [pdescr]		 ; (47)

;Blokada obs³ugi przerwañ sprzêtowych
	cli                            ;(139) Blokada obs³ugi przerwañ

;Zachowamy maski przerwan kontrolerow
	in	AL,21h          ;(140)
	mov	[master],AL     ;(141) Maska Master'a
	in	AL,0A1h         ;(142)
	mov	[slave],AL      ;(143) Maska Slave'a

; Inicjalizacja kontrolera Master (bazowy wektor 32)
	mov	AL,11h          ;(144) ICW1: bedzie ICW4
	out	20h,AL          ;(145)
	mov	AL, 50h           ;(146) ICW2 : bazowy wektor
	out	21h,AL          ;(147)
	mov	AL,4            ;(148) ICW3: Slave pod^aczony do poziomu 2
	out	21h,AL          ;(149)
	mov	AL,1            ;(150) ICW4: 80x86, wymagany EOI
	out	21h,AL          ;(151)
	mov	AL,0FCh         ;(152) Maska przerwan
	out	21h,AL          ;(153)

;Zabronienie wszystkich przerwan w Slave'ie
	mov	AL,0FFh         ;(154) Maska przerwan 
	out	0A1h,AL         ;(155) do portu

;Ladujemy IDTR 
	mov 	word [pdescr],idt_size-1 	; (109)granica
	xor 	EAX,EAX			            ; (110)
	mov 	AX,exception0		        ; (111)
	add 	EAX,EBP			            ; (112)liniowy adres IDT
	mov 	dword [pdescr+2],EAX 	    ; (113)
	lidt	fword [pdescr]	

;Przejscie do trybu chronionego
	mov	EAX,CR0 		 ; (49)
	or	EAX, 1			 ; (50)
	mov	CR0,EAX 		 ; (51) 

;-------------------------------------------------------------------------
;              Teraz procesor pracuje w trybie chronionym
;-------------------------------------------------------------------------

;Ladowanie do CS:IP selektor: przesuniecie punktu continue
	db	0EAh				 ; (52) 
	dw	continue		     ; (53) 
	dw	16	

continue:           ;(168) 

;Przywracamy mozliwosc adresacji danych
	mov	AX,8			     ; (55) 
	mov	DS,AX			     ; (56)


;Przywracamy mozliwosc adresacji stosu
	mov	AX,24			 ; (57) 
	mov	SS,AX			     ; (58)


;Inicjalizacja ES,FS i GS
	mov	AX,32			     ; (59) 
	mov	ES,AX			     ; (60) 
	mov	FS,AX			 ; (61) 
	mov	GS,AX

;Zezwolenie na przerwania sprzêtowe
	sti                     ;(177) 

;Wyprowadzamy na ekran testowa linie symboli
	mov	DI,1920             ;(178) Poczatkowa pozycja na ekranie
	mov	CX,4000              ;(179) 8 linii symboli    
	mov	AX,1E01h            ;(180) Symbol+ atrybut
scrn: ;stosw                 ;(181) Zawartosc AX na ekran
;	inc	AL                  ;(182) Inkrement symbolu
	push	CX              ;(183) Zachowamy CX zewnetrznej petli
	mov	ECX,0F00000h          ;(184) Wprowadzimy niewielkie opoznienie,
delay: db	67h             ;(185) aby wykorzystac ECX
	loop	delay           ;(186) Petla opoznien
	pop	CX                  ;(187) Przywrocenie CX
	loop	scrn			;(188) Petla wyprowadzenia symboli

;Wyprowadzimy do linii diagnostycznej kod normalnego zakonczenia
	mov	AX,0FFFFh           ;(189) Warunkowy kod normalnego zakonczenia
home:	mov	SI,string       ;(190)  Przejecie z procedury obs^ugi wyjatku
	call	wrd_asc         ;(191) Przekszta^cenie AX do linii symboli

;Wyprowadzimy na ekran linie diagnostyczna
	mov	SI,string           ;(192) 
	mov	CX,len              ;(193)
	mov	AH,74h              ;(194)
	mov	DI,1280             ;(195)
scrn1: lodsb                ;(196)
	stosw                   ;(197)
	loop	scrn1           ;(198)

;Powrot do trybu rzeczywistego
	cli                     ;(199) Blokada przerwan

;Przygotujemy i za^adujemy deskryptory dla trybu rzeczywistego
	mov	word [gdt_data.lim], 0FFFFh	; (69) 
	mov	word [gdt_code.lim], 0FFFFh	; (70) 
	mov	word [gdt_stack.lim], 0h	; (71) Granica segmentu stosu
	mov	word [gdt_screen.lim], 0FFFFh	; (72) 
	push	DS				; (73) 
	pop	DS				    ; (74) 
	push	SS				; (75) 
	pop	SS				    ; (76) 
	push	ES				; (77) 
	pop	ES				    ; (78) 
	push	FS		; (79)
	pop	FS		    ; (80)
	push	FS		; (81)
	pop	GS		    ; (82)


;Wykonamy daleki stos w celu uaktualnienia selektora CS 
;i jego ukrytego rejestru
	db	0EAh			; (83) 
	dw	go			; (84) 
	dw	16			    ; (85)

			
;Prze³¹czymy tryb pracy procesora
go:
	mov	EAX,CR0 	    ; (86) 
	and	EAX, 0FFFFFFFEh ; (87) 
	mov	CR0,EAX 	    ; (88) 
	db	0EAh			; (89) 
	dw	return		; (90) 
	dw	text			; (91) 

; ------------------------------------------------------------------------------
;Teraz procesor pracuje w trybie rzeczywistym
; ------------------------------------------------------------------------------

return:                             ;(223) 

;Przywrócenie œrodowiska dla trybu rzeczywistego
	mov	AX, data_16		; (92) 
	mov	DS,AX			; (93)
	mov	AX,stk		    ; (94) 
	mov	SS,AX			; (95) 
	mov	SP,256		    ; (96)

;Przywrocimy stan rejestru IDTR trybu rzeczywistego
	mov	AX,3FFh                     ;(229)Granica tablicy wektorów przerwañ (1 Kbajt)
	mov	word [pdescr],AX            ;(230)
	mov	EAX, 0                      ;(231)Przesuniàcie tablicy wektorów 
	mov	dword [pdescr+2],EAX        ;(232)
	lidt	fword [pdescr]          ;(233)Za³adowanie deskryptora do IDTR

;Ponowna inicjalizacja kontrolera przerwan Master
;i ustawienie jego na bazowy wektor 8
	mov	AL,11h                      ;(234) ICW1: bedzie ICW4
	out	20h,AL                      ;(235)
	mov	AL,8                        ;(236) ICW2 : bazowy wektor
	out	21h,AL                      ;(237)
	mov	AL,4                        ;(238) ICW3: Slave pod^aczony do poziomu 2
	out	21h,AL                      ;(239)
	mov	AL,1                        ;(240) ICW4: 80x86, wymagany EOI
	out	21h,AL                      ;(241)

;Przywracamy poczatkowe maski przerwan obydwu kontrolerow
	mov	AL,[master]                 ;(242)Maska przerwan Master'a
	out	21h,AL                      ;(243)
	mov	AL,[slave]                  ;(244)Maska przerwan Slave'a
	out	0A1h,AL                     ;(245)

	sti                             ;(246)Zezwolimy obs³ugê przerwañ sprzêtowych

;Pracujemy w DOS'ie
	mov	AH,09h	; (98) 
	mov	DX, msg ; (99) 
	int	21h		; (100)
	mov	AX,4C00h; (101)
	int	21h		; (102)
	ret 

; Wykorzystywane procedury - podprogramy wrd_asc i bin_asc
; przekszta³cenia liczby binarnej w symboliczne przedstawienie hex;
;Podprogram wrd_asc przekszta³cenia s³owa 
;Przy wywo³aniu przekszta³cana liczba znajduje siê AX, 
;DS:SI -> miejsce dla rezultatu
wrd_asc: 
	pusha 			    ; (156) 
	mov 	BX, 0F000h	; (157) 
	mov 	DL, 12		; (158) 
	mov 	CX, 4		; (159) 
cccc: push	CX		    ; (160) 
	push 	AX		    ; (161) 
	and 	AX, BX		; (162) 
	mov 	CL, DL		; (163) 
	shr 	AX, CL		; (164) 
	call 	bin_asc		; (165) 
	mov 	[SI], AL	; (166) 
	inc 	SI		    ; (167) 
	pop	AX		        ; (168) 
	shr	BX,4		    ; (169) 
	sub	DL,4		    ; (170) 
	pop	CX		        ; (171) 
	loop	cccc		; (172) 
	popa			    ; (173) 
	ret			        ; (174) 

;Podprogram przekszta³cenia cyfry hex 
; Argument - czwórka bitów w m³odszej czêœci AL., rezultat w AL
bin_asc:
	cmp 	AL, 9		; (175) 
	ja	lettr		    ; (176) 
	add	AL,30h		    ; (177) 
	jmp	ok		        ; (178) 
lettr: 	add	AL,37h		; (179) 
ok:	ret			        ; (180) 

code_size=$-exc0    ;(277) Rozmiar segmentu rozkazow

; segment stosu
segment stk use16	; (104)
	    DB	256 DUP (?) ; (105)
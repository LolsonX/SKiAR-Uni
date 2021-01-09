;Obs³uga wyj¹tków
;Wykorzystano nastêpujace ród³a:
;P.I.Rudakov, K.G.Finogenov Jazyk Assemblera uroki programirowania Dialog MIFI (w jêzyku rosyjskim)
;http://win32assembly.online.fr/tutorials.html
;http://wasm.ru

; Struktura do opisu deskryptorów segmentów
struc descr lim,base_l,base_m,attr_1,attr_2,base_h
{
	.lim	dw	lim	    ; (1) 
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
macro except_without_code
{
	mov	bx, ax
	pop	EAX         ; (67)zdjêcie ze stosu EIP 
	push 	ebx
	mov	SI,string+14; (68)przekszta³cenie i wywietlenie
	call	wrd_asc ; (69)
	shr	EAX,16      ; (70)
	mov	SI,string+10; (71)
	call	wrd_asc ;
	pop	EBX ; (72)
	pop	EAX         ; (73)zdjêcie ze stosu CS
	mov	SI,string+5 ; (74)przekszta³cenie i wywietlenie
	call	wrd_asc ; (75)
	pop	EAX
}
macro except_with_code 
{
	pop	EAX         ; (64)zdjêcie ze stosu kodu b³êdu
	mov	SI,string+19; (65)przekszta³cenie i wywietlenie
	call	wrd_asc ; (66)
	except_without_code
}

format	MZ              ; (12)format pliku wyjciowego 
stack	stk:256         ; (13)ustawienie wielkoci stosu
entry	text:main       ; (14)punkt wejcia do programu

; Segment danych

segment data_16 use16   ; (15)segment o adresacji 16 bitowej

; Tablica globalnych deskryptorów GDT

gdt_null descr		0,		0,	0,	0,	0,	0		   ; (11) 
gdt_data descr		data_size-1,	0,	0,	92h,	0,	0      ; (12) 
gdt_code descr		code_size-1,	0,	0,	98h,	0,	0      ; (13) 
gdt_stack descr 	0,		0,	0,	96h,	0,	0	       ; (14) 
gdt_screen descr	3999,		8000h,	0Bh,	92h,	0,	0  ; (15) 
;Change gdt_my_seg to raise exc 0Bh
;gdt_my_seg descr	mine_seg_size-1,	0,	0,      72h,	0,	0
;gdt_my_seg descr	mine_seg_size-1,	0,	0,	92h,	0,	0
gdt_size=$-gdt_null                                            ; (17)

; Tablica deskryptorów wyj¹tków i przerwañ IDT
exception0	trap	exc0,	16,	0,	8Fh,	0	;(21)Deskryptor wyj¹tku  	0
exception1	trap	exc1,	16,	0,	8Fh,	0	;(22)Deskryptor wyj¹tku  	1
exception2	trap	dummy,	16,	0,	8Fh,	0	;(23)Deskryptor wyj¹tku  	2
exception3	trap	exc3,	16,	0,	8Fh,	0	;(24)Deskryptor wyj¹tku  	3
exception4	trap	exc4,	16,	0,	8Fh,	0	;(25)Deskryptor wyj¹tku  	4
exception5	trap	exc5,	16,	0,	8Fh,	0	;(26)Deskryptor wyj¹tku  	5
exception6	trap	exc6,	16,	0,	8Fh,	0	;(27)Deskryptor wyj¹tku  	6
exception7	trap	exc7,	16,	0,	8Fh,	0	;(28)Deskryptor wyj¹tku  	7
exception8	trap	exc8,	16,	0,	8Fh,	0	;(29)Deskryptor wyj¹tku  	8
exception9	trap	exc9,	16,	0,	8Fh,	0	;(30)Deskryptor wyj¹tku  	9
exception10	trap	exc10,	16,	0,	8Fh,	0	;(31)Deskryptor wyj¹tku  	10
exception11	trap	exc11,	16,	0,	8Fh,	0	;(32)Deskryptor wyj¹tku  	11
exception12	trap	exc12,	16,	0,	8Fh,	0	;(33)Deskryptor wyj¹tku  	12
exception13	trap	exc13,	16,	0,	8Fh,	0	;(34)Deskryptor wyj¹tku  	13
exception14	trap	exc14,	16,	0,	8Fh,	0	;(35)Deskryptor wyj¹tku  	14
exception15	trap	dummy,	16,	0,	8Fh,	0	;(36)Deskryptor wyj¹tku  	15(którego brak)
exception16	trap	exc16,	16,	0,	8Fh,	0	;(37)Deskryptor wyj¹tku  	16
exception17	trap	exc17,	16,	0,	8Fh,	0	;(38)Deskryptor wyj¹tku  	17

idt_size=$-exception0		; (39) Rozmiar tablicy IDT
;bla	db 1
;bla2	db 2
;mine_seg_size=$-bla

;Ró¿ne dane programu
pdescr		df 0			; (40) pseudodeskryptor dla rozkazów lgdt i lidt
sym		db 1			    ; (41)Symbol dla wyprowadzenia na ekran 
attr		db 1Eh			; (42)jego atrybut
msg		db	27,'[31;42m  Powrocilismy do trybu rzeczywistego '    , 27, '[0m$ ' ;(43)Wywietlany komunikat
string  	db '**** ****:******** **** ****'	; (44)Szablon linii diagnostycznej 
;               0    5    10     15     20     25
len=$-string			    ; (45)D³ugoæ linii
data_size=$-gdt_null 		; (46)Rozmiar segmentu danych



;Segment rozkazów
segment text use16	; (47)segment o adresacji 16 bitowej
  
exc0:	
	except_without_code			; (48)obs³uga wyj¹tku 0
	mov	AX, 0		; (49)wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (50)wyjcie
exc1:	
	except_without_code			; (48)obs³uga wyj¹tku 0
	mov	AX, 1		; (49)wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (50)wyjcie
exc3:	
	except_without_code			; (48)obs³uga wyj¹tku 0
	mov	AX, 3		; (49)wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (50)wyjcie

exc4:	
	except_without_code			; (48)obs³uga wyj¹tku 0
	mov	AX, 4		; (49)wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (50)wyjcie

exc5:	
	except_without_code			; (48)obs³uga wyj¹tku 0
	mov	AX, 5		; (49)wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (50)wyjcie
	
exc6:	
	except_without_code			; (48)obs³uga wyj¹tku 0
	mov	AX, 6		; (49)wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (50)wyjcie
	
exc7:	
	except_without_code			; (48)obs³uga wyj¹tku 0
	mov	AX, 7		; (49)wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (50)wyjcie

exc8:	
	except_with_code			; (48)obs³uga wyj¹tku 0
	mov	AX, 8		; (49)wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (50)wyjcie
	
exc9:	
	except_without_code			; (48)obs³uga wyj¹tku 0
	mov	AX, 9		; (49)wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (50)wyjcie

exc10:	
	except_with_code			; (48)obs³uga wyj¹tku 0
	mov	AX, 10		; (49)wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (50)wyjcie

exc11:	
	except_with_code			; (48)obs³uga wyj¹tku 0
	mov	AX, 11		; (49)wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (50)wyjcie

exc12:	
	except_with_code			; (48)obs³uga wyj¹tku 0
	mov	AX, 12		; (49)wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (50)wyjcie

exc13:	
	except_with_code			; (48)obs³uga wyj¹tku 0
	mov	AX, 13		; (49)wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (50)wyjcie
	
exc14:	
	except_with_code			; (48)obs³uga wyj¹tku 0
	mov	AX, 14		; (49)wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (50)wyjcie
	
exc16:	
	except_without_code			; (48)obs³uga wyj¹tku 0
	mov	AX, 16		; (49)wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (50)wyjcie
	
exc17:	
	except_with_code			; (48)obs³uga wyj¹tku 0
	mov	AX, 17		; (49)wyprowadzenie na ekran numeru wyj¹tku
	jmp	home		; (50)wyjcie
	
dummy:				; (78) obs³uga pozosta³ych wyj¹tków 
	mov 	AX,5555h; (79)symboliczny kod pozosta³ych wyj¹tków
	jmp 	home	; (80) wyjcie

main:				; (81)punkt wejcia do programu
	xor	EAX,EAX	    ; (82)oczyciæ EAX
	mov	AX,stk      ; (83)£adowanie adresu segmentu stosu
	mov	SS,AX       ; (84)do rejestru segmentowego
	mov	SP,256      ; (85)Wartoæ pocz¹tkowa wskanika stosu
	mov	AX,data_16	; (86)£adowanie do DS adresu  
	mov	DS,AX		; (87)segmentu danych

; Obliczymy i za³adujemy do GDT liniowy adres segmentu danych
	shl	EAX,4			    ; (28) 
	mov	EBP,EAX 		; (29) 
	mov	[gdt_data.base_l],AX	; (30) 
	shr	EAX, 16 		    ; (31) 
	mov	[gdt_data.base_m],AL	; (32) 

; Obliczymy i za³adujemy do GDT liniowy adres segmentu rozkazów
	xor	EAX,EAX 		; (33) 
	mov	AX,CS			    ; (34) 
	shl	EAX,4			    ; (35) 
	mov	[gdt_code.base_l],AX	; (36)
	shr	EAX,16			    ; (37)
	mov	[gdt_code.base_m],AL	; (38)
	
; Obliczymy i za³adujemy do GDT liniowy adres segmentu stosu
	xor	EAX,EAX 		; (39)
	mov	AX, SS			; (40)
	shl	EAX,4			    ; (41)
	mov	[gdt_stack.base_l],AX	; (42)
	shr	EAX,16			    ; (43)
	mov	[gdt_stack.base_m],AL	; (44)
; Przygotujemy pseudodeskryptor pdescr do zapisu rejestru GDTR
	mov	dword [pdescr+2],EBP	 ; (45)
	mov	word [pdescr],gdt_size-1 ; (46)
	lgdt	fword [pdescr]		 ; (47)
	cli 				                ; (108)Zakaz obs³ugi przerwañ

;Za³adujemy IDTR 
	mov 	word [pdescr],idt_size-1 	; (109)granica
	xor 	EAX,EAX			            ; (110)
	mov 	AX,exception0		        ; (111)
	add 	EAX,EBP			            ; (112)liniowy adres IDT
	mov 	dword [pdescr+2],EAX 	    ; (113)
	lidt	fword [pdescr]			    ; (114) Za³adowaæ IDTR

; Przejcie do trybu chronionego
;Przejcie w tryb chroniony
	mov	EAX,CR0 		 ; (49)
	or	EAX, 1			 ; (50)
	mov	CR0,EAX 		 ; (51) 

;------------------------------------------------------------------------------------------------------------------------------------
; Procesor funkcjonuje w trybie chronionym;
;------------------------------------------------------------------------------------------------------------------------------------

; Zapiszemy do CS:IP selektor : przesuniêcie etykietki continue 
	db	0EAh				 ; (52) 
	dw	continue		     ; (53) 
	dw	16				     ; (54) 
continue:			
;Mo¿liwa adresacja danych
	mov	AX,8			     ; (55) 
	mov	DS,AX	

;Mo¿liwa adresacja stosu
	mov	AX,24			 ; (57) 
	mov	SS,AX	

;Inicjalizacja ES,FS,GS
	mov	AX,32			     ; (59) 
	mov	ES,AX			     ; (60) 
	mov	FS,AX			     ; (60)
	mov	GS,AX			     ; (60)

;	mov	AX, 40
;	mov	FS, AX
;	mov AX, CS:[0]	
            

; Wyjtek 0
;	mov 	AX, 1h
;	mov     BX, 0
;	div	BL
; Wyjatek 1
;	int 1
; Wyjatek 3
;	int3
; Wyjatek 4
;	mov AL, -127
;	sub AL, 3
;	into
; Wyjatek 5
;	mov AX, 1h
;	bound AX, [0]
; Wyjatek 6
;	mov	CR6,EAX
;Wyjatek 7
;	mov     EAX, CR0
;	or	EAX, 10b
;	mov	CR0, EAX
;       fldcw   word [attr]
; Wyjatek 11
; Aby wywolac wyjatek 11 wystarczy GDT odkomentowac zakomentowany gdt_my_seg i zakomentowac obecny 
; Wyjatek 13
	iret
; Wyjatek 16 - ale tutaj ni wiem dlaczego ale jest
;        jmp	0202h
;Wywietlanie na ekranie linii symboli
	mov 	DI,1600	                    ; (130) Pocz¹tkowa pozycja na ekranie
	mov 	CX,80		                ; (131)Iloæ wyprowadzanych symboli
	mov 	AX,word [sym]	            ; (132)Symbol + atrybut
scrn:	stosw			                ; (133)Zawartoæ AX na ekran
	inc 	AL		                    ; (134)Inkrementacja symbolu 
	loop 	scrn		                ; (135)Pêtla
	mov 	AX,0FFFFh	                ; (136)Kod warunkowy normalnego zakoñczenia
home:	mov 	SI, string	            ; (137)Punkt przejcia z procedur obs³ugi wyj¹tków
	call 	wrd_asc		                ; (138)Przekszta³cenie AX liniê symboli

;Wyprowadzenie na ekran linii diagnostycznej 
	mov 	SI, string		; (139)
	mov 	CX,len			; (140)
	mov 	AH,74h			; (141)
	mov 	DI,1440			; (142)
scrn1:	lodsb				; (143)
	stosw					; (144)
loop 	scrn1				; (145)

; Powrót do trybu rzeczywistego 
; Przygotowanie i ³adowanie deskryptorów dla trybu rzeczywistego
	mov	word [gdt_data.lim], 0FFFFh	; (69) 
	mov	word [gdt_code.lim], 0FFFFh	; (70) 
	mov	word [gdt_stack.lim], 0h	; (71) Granica segmentu stosu
	mov	word [gdt_screen.lim], 0FFFFh	; (72) 
;	mov	word [gdt_my_seg.lim], 0FFFFh
	push	DS				; (73) 
	pop	DS				    ; (74) 
	push	SS				; (75) 
	pop	SS				    ; (76) 
	push	ES				; (77) 
	pop	ES				    ; (78) 
	push	FS		; (79)
	pop	FS		    ; (80)
	push	GS		; (81)
	pop	GS		    ; (82)

; Wykonamy dalekie przejcie po to, aby na nowo za³adowaæ selektor
; w rejestrze CS i modyfikowaæ jego ukryty rejestr
	db	0EAh			; (83) 
	dw	go			; (84) 
	dw	16			    ; (85) 

; Prze³¹czymy tryb procesora
go:	mov	EAX,CR0 	    ; (86) 
	and	EAX, 0FFFFFFFEh ; (87) 
	mov	CR0,EAX 	    ; (88) 
	db	0EAh			; (89) 
	dw	return		; (90) 
	dw	text			; (91) 

; ------------------------------------------------------------------------------; Teraz procesor znowu pracuje w trybie rzeczywistym
; ------------------------------------------------------------------------------
return:				
;Przywrócimy rodowisko pracy w trybie rzeczywistym
	mov	AX, data_16		; (92) 
	mov	DS,AX			; (93)
	mov	AX,stk		    ; (94) 
	mov	SS,AX			; (95) 
	mov	SP,256		    ; (96)


;Przywrócenie stanu rejestru IDTR w trybie rzeczywistym
	mov 	AX,3FFh             ; (175)Granica tablicy wektorów przerwañ (1 Kbajt)
	mov 	word [pdescr],AX 	; (176)
	mov 	EAX, 0		        ; (177)Przesuniêcie tablicy wektorów 
	mov 	dword [pdescr+2],EAX ; (178)
	lidt 	fword [pdescr]		; (179)Za³adowanie deskryptora do IDTR
	sti			                ; (180)Zezwolenie na obs³ugê przerwañ sprzêtowych 

;Pracujemy w DOS'ie 		; (100)
	mov	AX,4C00h; (101)
	int	21h		; (102)


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
; Argument - czwórka bitów w m³odszej czêci AL, rezultat w AL
bin_asc:
	cmp 	AL, 9		; (175) 
	ja	lettr		    ; (176) 
	add	AL,30h		    ; (177) 
	jmp	ok		        ; (178) 
lettr: 	add	AL,37h		; (179) 
ok:	ret			        ; (180) 

code_size=$-exc0	; (213)Rozmiar segmentu rozkazów
					
segment stk use16	; (104)
	    DB	256 DUP (?) ; (105)

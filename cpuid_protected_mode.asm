;Wejœcie i wyjœcie z trybu chronionego 
;Wykorzystano nastêpujace Ÿród³a:
;P.I.Rudakov, K.G.Finogenov „Jazyk Assemblera uroki programirowania” Dialog MIFI (w jêzyku rosyjskim)
;http://win32assembly.online.fr/tutorials.html
;http://wasm.ru


;Struktura opisu deskryptorów segmentów

struc descr lim,base_l,base_m,attr_1,attr_2,base_h
{
	.lim	dw	lim	    ; (1) 
	.base_l dw	base_l	; (2) 
	.base_m db	base_m	; (3) 
	.attr_1 db	attr_1	; (4) 
	.attr_2 db	attr_2	; (5) 
	.base_h db	base_h	; (6) 
}

format	MZ		; (7)
stack	stk:256 	; (8)
entry	text:main	; (9)

;Segment o adresacji16-bitowej
segment data_16 use16	; (10)

; Tablica globalnych deskryptorów GDT

gdt_null descr		0,		0,	0,	0,	0,	0		   ; (11) 
gdt_data descr		data_size-1,	0,	0,	92h,	0,	0      ; (12) 
gdt_code descr		code_size-1,	0,	0,	98h,	0,	0      ; (13) 
gdt_stack descr 	0,		0,	0,	96h,	0,	0	       ; (14) 
gdt_screen descr	3999,		8000h,	0Bh,	92h,	0,	0  ; (15) 
gdt_strings	descr	strings_size-1, 0,	0,	92h,	0,	0
gdt_size=$-gdt_null

; Ró¿ne dane programu
pdescr		df 0		; (16) 
sym		    db 16		; (17) 
attr		db 1Eh		; (18) 
msg		    db 27, '[31;42m  Powrocilismy do trybu rzeczywistego   ',27, '[0m$' ; (19) 
data_size=$-gdt_null		; (20) 

segment my_strings use16
cores_string	db	19, 'Number of cores: 00      '
apic_string	db	6,'APIC: '
htt_string	db	5, 'HTT: '
fpu_string	db	5, 'FPU: '
sep_string	db	5, 'SEP: '
manufacturer_string	db	26, 'Manufacturer: xxxxyyyyzzzz'
basic_inst_string	db 23, 'Basic instructions: 000'
dum_string	db	'Dummy'
extended_string		db 26, 'Extended instructions: 000     '
yes_string	db	3, 'Yes'
no_string	db	2, 'No'
cpu_name_string db	58, 'Name:                                                      '
strings_size=$-cores_string

; Segment rozkazów
; segment o adresacji16-bitowej

segment text use16   ; (21) 
	
main:xor	EAX,EAX     ; (22) 
	mov	AX,stk		; (23) 
	mov	SS,AX		; (24) 
	mov	SP,256		; (25)
	mov	AX, my_strings
	mov	FS, AX
	mov	AX, data_16		; (26)
	mov	DS,AX			; (27)
	; Obliczymy 32-bitowy liniowy adres segmentu danych i za³adujemy go
; do deskryptora segmentu danych w tablicy globalnych deskryptorów GDT
	shl	EAX,4			    ; (28) 
	mov	EBP,EAX 		; (29) 
	mov	[gdt_data.base_l],AX	; (30) 
	shr	EAX, 16 		    ; (31) 
	mov	[gdt_data.base_m],AL	; (32) 

; Wyliczymy i za³adujemy do GDT liniowy adres segmentu rozkazów
	xor	EAX,EAX 		; (33) 
	mov	AX,CS			    ; (34) 
	shl	EAX,4			    ; (35) 
	mov	[gdt_code.base_l],AX	; (36)
	shr	EAX,16			    ; (37)
	mov	[gdt_code.base_m],AL	; (38)

; Wyliczymy i za³adujemy do GDT liniowy adres segmentu stosu
	xor	EAX,EAX 		; (39)
	mov	AX, SS			; (40)
	shl	EAX,4			    ; (41)
	mov	[gdt_stack.base_l],AX	; (42)
	shr	EAX,16			    ; (43)
	mov	[gdt_stack.base_m],AL	; (44)

; Wyliczymy i zaladujemy do GDT liniowy adres segmentu FS
	xor	EAX,EAX
	mov	AX,FS 
	shl	EAX,4
	mov	[gdt_strings.base_l],AX
	shr	EAX,16
	mov	[gdt_strings.base_m],AL

; Przygotujemy pseudodeskryptor pdescr i za³adujemy rejestr GDTR
	mov	dword [pdescr+2],EBP	 ; (45)
	mov	word [pdescr],gdt_size-1 ; (46)
	lgdt	fword [pdescr]		 ; (47)


	cli					     ; (48)

; Przejœcie w tryb chroniony
	mov	EAX,CR0 		 ; (49)
	or	EAX, 1			 ; (50)
	mov	CR0,EAX 		 ; (51) 

; ------------------------------------------------------------------------------------------
;               Teraz bêdziemy pracowaæ w trybie chronionym
; ------------------------------------------------------------------------------------------

; Zapisujemy do CS:IP selektor: przesuniêcie etykietki continue
	db	0EAh				 ; (52) 
	dw	Continue		     ; (53) 
	dw	16				     ; (54) 
Continue:
; przywracamy mo¿liwoœæ adresacji danych (DS) w trybie chronionym
	mov	AX,8			     ; (55) 
	mov	DS,AX			     ; (56)

; przywracamy mo¿liwoœæ adresacji stosu w trybie chronionym
	mov	AX,24			 ; (57) 
	mov	SS,AX			     ; (58)

; przywracamy mo¿liwoœæ adresacji danych (ES,FS,GS) w trybie chronionym
	mov	AX,32			     ; (59) 
	mov	ES,AX			     ; (60) 
	mov	GS,AX			 ; (62) 

	mov	AX,40
	mov	FS, AX
; Wypisujemy na ekranie bie¿¹c¹ liniê znaków
	mov	DI,1600 		 ; (63) 
run_cpuid:
	push	eax
	push	ebx
	push	ecx
	push	edx
manufacturer:
	mov	eax, 0h
	cpuid
	mov	dword [fs:manufacturer_string+15], ebx
	mov	dword [fs:manufacturer_string+19], edx
	mov	dword [fs:manufacturer_string+23], ecx
	mov	BX, manufacturer_string
	call 	print
	call	new_line 
basic_functions:
	add	AL,	01h
	call	bin_asc
	mov	dword [FS:basic_inst_string+22], EAX
	mov	BX,	basic_inst_string
	call	print
	call 	new_line
extended_f:
	mov	EAX,	80000000h
	cpuid
	and	EAX,	0FFFFFFFh
	add	AL, 01h
	mov	AH,	AL
	and	AH,	0F0h
	and	AL,	0Fh
	call	bin_asc
	mov	byte	[FS:extended_string+26], AL
	mov	AL,	AH
	shr	AL, 4
	and	AL, 0Fh
	call	bin_asc
	mov	byte	[FS:extended_string+25], AL
	mov	BX,	extended_string
	call	print
	call	new_line
num_cores:
	mov	EAX, 80000008h
	cpuid
	mov	EAX,	ECX
	add	AL,	1
	call	bin_asc
	mov	dword	[FS:cores_string+18], EAX
	mov	BX,	cores_string
	call	print
	call	new_line
test_apic:
	mov	BX, apic_string
	call	print 	
	mov	eax,	01h
	cpuid
	test	edx,	00000200h
	jz	no_apic
	mov	BX,	yes_string
	call	print
	jmp	end_apic
no_apic:
	mov	BX, no_string
	call	print
end_apic:
	call	new_line
test_htt:
	mov	BX, htt_string
	call	print
	mov	EAX,	01h
	cpuid
	test	EDX,	00800000h
	jz	no_htt
	mov	BX,	yes_string
	jmp	end_htt
no_htt:
	mov	BX,	no_string
end_htt:
	call	print
	call	new_line

test_fpu:
	mov	BX, fpu_string
	call	print
	mov	EAX,	01h
	cpuid
	test	EDX,	00000001h
	jz	no_fpu
	mov	BX,	yes_string
	jmp	end_fpu
no_fpu:
	mov	BX, no_string
end_fpu:
	call	print
	call	new_line
test_sep:
	mov	BX, sep_string
	call	print
	mov	EAX,	01h
	cpuid
	test	EDX,	00000400h
	jz	no_sep
	mov	BX,	yes_string
	jmp	end_sep
no_sep:
	mov	BX,	no_string
end_sep:
	call	print
	call	new_line
proc_name:
	mov	eax,	80000002h
	cpuid
	mov	dword 	[FS:cpu_name_string+7],	eax
	mov	dword	[FS:cpu_name_string+11], ebx
	mov	dword	[FS:cpu_name_string+15], ecx
	mov	dword	[FS:cpu_name_string+19], edx
	mov	eax,	80000003h
	cpuid
	mov	dword	[FS:cpu_name_string+23], eax
	mov	dword	[FS:cpu_name_string+27], ebx
	mov	dword	[FS:cpu_name_string+31], ecx
	mov	dword	[FS:cpu_name_string+35], edx
	mov	eax, 	80000004h
	cpuid
	mov	dword	[FS:cpu_name_string+39], eax
	mov	dword	[FS:cpu_name_string+43], ebx
	mov	dword	[FS:cpu_name_string+47], ecx
	mov	dword	[FS:cpu_name_string+51], edx
	mov	BX,	cpu_name_string
	call	print
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax

; Powrót do trybu rzeczywistego
; utworzymy i za³adujemy deskryptory dla trybu rzeczywistego
	mov	word [gdt_data.lim], 0FFFFh	; (69) 
	mov	word [gdt_code.lim], 0FFFFh	; (70) 
	mov	word [gdt_stack.lim], 0h	; (71) Granica segmentu stosu
	mov	word [gdt_screen.lim], 0FFFFh	; (72) 
	mov	word [gdt_strings.lim], 0FFFFh
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

; Wykonamy daleki skok po to, aby ponownie za³adowaæ selektor
; do rejestru CS i zmodyfikowaæ jego rejestr ukryty
	db	0EAh			; (83) 
	dw	go			; (84) 
	dw	16			    ; (85) 

;  Prze³¹czymy tryb procesora
go:	mov	EAX,CR0 	    ; (86) 
	and	EAX, 0FFFFFFFEh ; (87) 
	mov	CR0,EAX 	    ; (88) 
	db	0EAh			; (89) 
	dw	return		; (90) 
	dw	text			; (91) 
; --------------------------------------------------------------------------------------------------------------------
; Teraz procesor znów pracuje w trybie rzeczywistym
; --------------------------------------------------------------------------------------------------------------------

return:
; Przywrócimy prawid³owe œrodowisko pracy dla trybu rzeczywistego DOS
	mov	AX, data_16		; (92) 
	mov	DS,AX			; (93)
	mov	AX,stk		    ; (94) 
	mov	SS,AX			; (95) 
	mov	SP,256		    ; (96)
	sti				    ; (97) 

; Pracujemy w DOS
	mov	AH,09h	; (98) 
	mov	DX, msg ; (99) 
	int	21h		; (100)
	mov	AX,4C00h; (101)
	int	21h		; (102)
;BX - offset, FS-lancuchy znakow, [FS:BX] - dlugosc lancucha; DI komorka ekranu
print:
	push	eax
	push	ecx
	xor EAX, EAX
	xor ECX, ECX
	mov CL, byte [FS:BX]
	mov AH, 0Fh
next_char:
	inc BX
	mov AL, byte [FS:BX]
	stosw
	loop next_char
	pop ecx
	pop eax
	ret

new_line:
	push ebx
	push edx
	push ecx
	push eax
	xor	ebx, ebx
	xor	edx, edx
	xor	eax, eax
	xor	ecx, ecx
	mov	bx, 160
	mov	ax, di
	mov	edx, 0
	div	bx
	mov	cx, 160
	sub	cx, dx
	add	di, cx	
	pop eax
	pop ecx
	pop edx
	pop ebx
	ret
wrd_asc:
	pusha
	mov	BX,	0F000h
	mov	DL,	12
	mov	CX,	4
cccc:
	push	CX
	and	AX, 	BX
	mov	CL,	DL
	shr	AX,	CL
	call	bin_asc
	mov	[FS:SI], AL
	inc	SI
	pop	AX
	shr	BX,	4
	sub	DL,	4
	loop	cccc
	popa
	ret

bin_asc:
	cmp	AL,	9
	ja	lettr
	add	AL,	30h
	jmp	ok
lettr:
	add	AL,	37h
ok:
	ret
code_size=$-main	; (103)
 

; segment stosu
segment stk use16	; (104)
	    DB	256 DUP (?) ; (105)

format MZ
stack stk:256
entry text:main

segment data_16 use16
_stare06 dw ?
         dw ?
number   db '???? ????'  ; (22) Pole do dynamicznej kontroli 
kom_jest_ponizej_286 db 'Procesor klasy ponizej 286',0Ah,0Dh,24h
kom_jest_286      db 'Procesor klasy 286',0Ah,0Dh,24h
kom_jest_386      db 'Procesor klasy 386',0Ah,0Dh,24h
kom_jest_486      db 'Procesor klasy 486 bez obs³ugi instrukcji CPUID',0Ah,0Dh,24h
kom_jest_obsluga_cpuid_      db 'Procesor klasy 486 lub wyzej z obsluga CPUID', 0Ah, 0Dh, 24h
rdzenie	  db 'Liczba rdzeni: 00',0Ah,0Dh,24h
m_apic	  db 'APIC: ',24h
m_htt	  db 'HTT: ',24h
m_fpu     db 'FPU: ',24h
m_sep	  db 'SEP: ',24h
producent db 'xxxxyyyyzzzz',0Ah, 0Dh,24h
liczba_podst	db 'Liczba instrukcji podstawowych:   ',0Ah,0Dh,24h
liczba_rozsz	db 'Liczba instrukcji rozszerzonych:   ', 0Ah, 0Dh, 24h
yes	  db 'Yes',0Ah,0Dh,24h
no        db 'No', 0Ah,0Dh,24h
nazwa     db '                                                                  ', 0Ah, 0Dh,24h
segment text use16

moje06:
   pop ax
   add ax,3
   push ax
   mov ax,1
   iret

main:
procek_mniej_niz_286:
   xor     ax, ax
   mov     es, ax
   les   bx, [es:(6 shl 2)]
   mov     [_stare06+2], es
   mov     [_stare06], bx
   mov     es, ax
   mov word [es:(6 shl 2)], moje06
   mov word [es:(6 shl 2)+2], text

;sprawdzenie czy wykonuje rozkaz smsw dx
   xor   ax,ax
   db      0fh, 1, 0e2h            ; smsw dx
   or      ax, ax
   jz      jest_286_lub_wiecej

;przywracanie starych procedur obslugi przerwania
   xor     ax, ax
   les     cx, dword [ds:_stare06]
   mov     ds, ax
   mov [ds:(6 shl 2)], cx
   mov [ds:(6 shl 2) + 2], es
   mov ax,data_16
   mov ds,ax
   jmp ponizej_286
   
jest_286_lub_wiecej:
   xor ax,ax
   les cx,dword [ds:_stare06]
   mov ds,ax
   mov [ds:(6 shl 2)],cx
   mov [ds:(6 shl 2)+2],es
   mov ax,data_16
   mov ds,ax
;flagi 12-15 maja wartosc 0
procek286:
   pushf                           ; flagi na stos
   pop     ax                      ; AX = flagi
   or      ax, 0f000h              ; ustawiamy bity 12-15
   push    ax                      ; AX na stos
   popf                            ; flagi = AX
   pushf                           ; flagi na stos
   pop     ax                      ; AX = flagi
   and     ax, 0f000h      ; jesli wyczyszczone, to 286
   jz     jest_286
;flaga 18 nie zmnienia siê

procek386:
   mov     dx, sp
   and sp, not 3     ; aby uniknac AC fault
   pushfd                  ; flagi na stos
   pop     eax             ; EAX = E-flagi
   mov     ecx, eax        ; zachowanie EAX
   xor     eax, 40000h     ; zmiana bitu 18
   push    eax             ; EAX na stos
   popfd                   ; E-flagi = EAX
   pushfd                  ; flagi na stos
   pop     eax             ; EAX = flagi
   xor     eax, ecx  ; czy takie same? jeœli tak, to 386
   mov     sp, dx          ; przywrócenie SP
   jz      jest_386


;nie obsluguje CPUID nie zmienia siê flaga 21
procek486:
   pushfd                  ; flagi na stos
   pop     eax             ; EAX = E-flagi
   mov     ecx, eax        ; zachowanie EAX
   xor     eax, 200000h    ; zmiana bitu 21
   push    eax             ; EAX na stos
   popfd                   ; E-flagi = EAX
   pushfd                  ; flagi na stos
   pop     eax             ; EAX = flagi
   xor     eax, ecx  ; czy takie same? jeœli tak, to 486
   jz      jest_486
   
   jmp     jest_obsluga_cpuid  ;obsluguje CPUid

ponizej_286:
         mov dx, kom_jest_ponizej_286
  jmp dalej

jest_286:
         mov dx, kom_jest_286
   jmp dalej

jest_386:
         mov dx, kom_jest_386 
   jmp dalej

jest_486:
         mov dx, kom_jest_486
   jmp dalej

jest_obsluga_cpuid:
   push  eax
   push  ebx
   push  ecx
   push  edx
   mov   eax, 0000000h
   cpuid
   mov dword [ds:producent], ebx
   mov dword [ds:producent+4], edx
   mov dword [ds:producent+8], ecx
podst_funk:
   add al, 01h 
   call bin_asc
   mov word [liczba_podst+31], ax
   mov dx, liczba_podst
   call print
extended_func:
   mov eax, 80000000h
   cpuid
   add al, 1
   and ax, 0Fh
   call bin_asc
   mov word [liczba_rozsz+32], ax
   mov dx, liczba_rozsz
   call print
cores:
   mov eax, 80000008h
   cpuid
   mov eax, ecx
   add al, 1h
   call bin_asc
   mov word [rdzenie+15], ax
   mov dx, rdzenie
   call print
proc_name:
   mov eax, 80000002h
   cpuid
   mov dword [nazwa], eax
   mov dword [nazwa+4], ebx
   mov dword [nazwa+8], ecx
   mov dword [nazwa+12], edx
   mov eax, 80000003h
   cpuid
   mov dword [nazwa+16], eax
   mov dword [nazwa+20], ebx
   mov dword [nazwa+24], ecx
   mov dword [nazwa+28], edx
   mov eax, 80000004h
   cpuid
   mov dword [nazwa+32], eax
   mov dword [nazwa+36], ebx
   mov dword [nazwa+40], ecx
   mov dword [nazwa+48], edx
   mov dx, nazwa
   call print
flag_presense:
   mov   eax, 1h
   cpuid
test_apic:
   mov dx, m_apic
   call print
   mov eax, 01h
   cpuid
   test  edx, 00000200h
   jz no_apic
   mov dx, yes
   call print
   jmp test_htt
no_apic:
   mov dx, no
   call print 
test_htt:
   mov dx, m_htt
   call print
   mov eax, 01h
   cpuid
   test edx, 00800000h
   jz no_htt
   mov dx,yes
   call print
   jmp test_fpu
no_htt:
   mov dx,no
   call print
test_fpu:
   mov dx, m_fpu
   call print
   mov eax, 01h
   cpuid
   test edx, 00000001h
   jz no_fpu
   mov dx, yes
   call print
   jmp test_sep
no_fpu:
   mov dx, no
   call print
;na Virtualboxie sep jest off nawet jesli jest wspierany
test_sep:
   mov dx, m_sep
   call print
   mov eax, 01h
   cpuid
   test edx, 00000400h
   jz no_sep
   mov dx, yes
   call print
   jmp end_cpuid
no_sep:
   mov dx, no
   call print
end_cpuid:
   pop   edx
   pop   ecx
   pop   ebx
   pop   eax 
   mov dx, producent
   jmp dalej

print:
   mov ah,9
   int 21h
   ret
dalej:   
   mov ax,data_16
   mov ds,ax
   mov ah,9
   int 21h  
   
   mov ax,4C00h
   int 21h
   ret

; Wykorzystywane procedury - podprogramy wrd_asc i bin_asc
; przekszta³cenia liczby binarnej w symboliczne przedstawienie hex;
;Podprogram wrd_asc przekszta³cenia s³owa 
;Przy wywo³aniu przekszta³cana liczba znajduje siê AX, 
;DS:SI -> miejsce dla rezultatu  
   wrd_asc: 
   pusha              ; (156) Przechowujemy wszystkie rejestry
   mov   BX, 0F000h  ; (157) W BX bêdzie maska bitów
   mov   DL, 12      ; (158) W DL bêdzie iloœæ przesuniêæ AX
   mov   CX, 4    ; (159) Licznik pêtli
cccc: push  CX        ; (160) Zapamiêtaæ go
   push  AX        ; (161) Zachowaæ pierwotn¹ wartoœæ AX na stosie
   and   AX, BX      ; (162) Wydzielimy czwórkê bitów
   mov   CL, DL      ; (163) W CL iloœæ przesuniêæ
   shr   AX, CL      ; (164) Przesun¹æ AH na CL bitów w prawo
   call  bin_asc     ; (165) Przekszta³cimy w znak ASCII
   mov   [SI], AL ; (166) Przeœlemy do linii rezultatu
   inc   SI        ; (167) Przesuniemy siê w prawo w linii
   pop   AX            ; (168) Przywrócimy w AX pocz¹tkow¹ wartoœæ 
   shr   BX,4         ; (169) Modyfikujemy maskê bitów
   sub   DL,4         ; (170) Modyfikujemy liczbê przesuniêæ
   pop   CX            ; (171) Ustawiamy licznik pêtli
   loop  cccc     ; (172) pêtla
   popa            ; (173) Przywracamy wartoœci wszystkich rejestrów
   ret                 ; (174) powrót z podprogramu


;Podprogram przekszta³cenia cyfry hex 
; Argument - czwórka bitów w m³odszej czêœci AL, rezultat w AL
bin_asc:
   cmp   AL, 9    ; (175) Cyfra > 9?
   ja lettr        ; (176) Tak, przekszta³ciæ w literê
   add   AL,30h          ; (177) Nie, przekszta³ciæ w symbol 0...9
   jmp   ok            ; (178) I wyjœæ z podprogramu 
lettr:   add   AL,37h      ; (179) Przekszta³ciæ w symbol A...F
ok:   ret                 ; (180) Powrót  do procedury wywo³uj¹cej

segment stk use16
   db 256 dup(?)

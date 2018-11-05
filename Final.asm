include macros2.asm
include number.asm
.MODEL LARGE
.386
.STACK 200h

.DATA
	MAXTEXTSIZE equ 50
 	__flags dw ? 
	__descar dd ? 
	oldcw dw ? 
	__auxConc db MAXTEXTSIZE dup (?), '$'
	__resultConc db MAXTEXTSIZE dup (?), '$'
	msgPRESIONE db 0DH, 0AH,'Presione una tecla para continuar...','$'
	_newLine db 0Dh, 0Ah,'$'
vtext db 100 dup('$')
 
;Declaracion de variables de usuario
	@a2	dd	?
	@a3	dd	?
	@d1	dd	?
	@pri	db	MAXTEXTSIZE dup (?),'$'
	@seg	db	MAXTEXTSIZE dup (?),'$'
	@sec	db	MAXTEXTSIZE dup (?),'$'
	_12.1	dd	12.100000
	_-12.1	dd	-12.100000
	_escribir_output_en_pantalla	db	'Escribir output en pantalla','$',22 dup (?)
	_hola	db	'Hola','$',45 dup (?)
	_32.3	dd	32.299999

.CODE
START:

	MOV AX, @DATA

	MOV DS, AX

	MOV ES, AX


;Comienzo codigo de usuario

	fstp @0
	fstp @2
	fstp @1
	fstp @12.1
	fld @d1
	fstp @
	fstp @-12.1
	fld @d1
	fstp @
	fstp @false
	fstp @1
	fadd St(0),St(1)

	LEA DX, _escribir_output_en_pantalla 
	MOV AH, 9
	INT 21H
	newline
	fstp @
@@etiq1:
	fstsw AX
	sahf
	JNA @@etiq2
	fstsw AX
	sahf
	JNB @@etiq3

	LEA DX, ! 
	MOV AH, 9
	INT 21H
	newline
@@etiq3:
	fstp @a1
	fadd St(0),St(1)
	jmp @@etiq1
@@etiq2:
	fstp @a1
	fstp @0
	fadd St(0),St(1)
	fadd St(0),St(1)
	fadd St(0),St(1)
	fadd St(0),St(1)
	fmul St(0),St(1)
	fld _-12.1
	fadd St(0),St(1)
	fadd St(0),St(1)
	fdiv St(0),St(1)
	fadd St(0),St(1)
	fstp @0
	fdiv St(0),St(1)
	fadd St(0),St(1)
	fstp @b
	fstp @0
	fadd St(0),St(1)
	fadd St(0),St(1)
	fstp @
	fadd St(0),St(1)
	fstp @
	fdiv St(0),St(1)
	fmul St(0),St(1)
	fstp @0
	fadd St(0),St(1)
	fstsw AX
	sahf
	JNZ @@etiq4
	fstp @1
@@etiq4:
	fadd St(0),St(1)
	fmul St(0),St(1)
	fstsw AX
	sahf
	JNZ @@etiq5
	fstp @1
@@etiq5:
	fstsw AX
	sahf
	JNZ @@etiq6
	fstp @1
@@etiq6:
	fdiv St(0),St(1)
	fstsw AX
	sahf
	JNZ @@etiq7
	fstp @1
@@etiq7:
	fld _32.3
	fstsw AX
	sahf
	JNZ @@etiq8
	fstp @1
@@etiq8:
	fstsw AX
	sahf
	JNZ @@etiq9

	LEA DX, _a1 
	MOV AH, 9
	INT 21H
	newline
@@etiq9:
@@etiq10:
	fstp @0
	fstsw AX
	sahf
	JNZ @@etiq11
	fstp @1
@@etiq11:
	fdiv St(0),St(1)
	fstsw AX
	sahf
	JNZ @@etiq12
	fstp @1
@@etiq12:
	fstsw AX
	sahf
	JNZ @@etiq13
	fstp @1
@@etiq13:
	fstsw AX
	sahf
	JNZ @@etiq14
	fstsw AX
	sahf
	JNB @@etiq15
	fstp @99
	jmp @@etiq16
@@etiq15:
	fstp @77
@@etiq16:
	jmp @@etiq10
@@etiq14:

;finaliza el asm
 	mov ah,4ch
	mov al,0
	int 21h

STRLEN PROC NEAR
	mov BX,0

STRL01:
	cmp BYTE PTR [SI+BX],'$'
	je STREND
	inc BX
	jmp STRL01

STREND:
	ret

STRLEN ENDP

COPIAR PROC NEAR
	call STRLEN
	cmp BX,MAXTEXTSIZE
	jle COPIARSIZEOK
	mov BX,MAXTEXTSIZE

COPIARSIZEOK:
	mov CX,BX
	cld
	rep movsb
	mov al,'$'
	mov BYTE PTR [DI],al
	ret

COPIAR ENDP

CONCAT PROC NEAR
	push ds
	push si
	call STRLEN
	mov dx,bx
	mov si,di
	push es
	pop ds
	call STRLEN
	add di,bx
	add bx,dx
	cmp bx,MAXTEXTSIZE
	jg CONCATSIZEMAL

CONCATSIZEOK:
	mov cx,dx
	jmp CONCATSIGO

CONCATSIZEMAL:
	sub bx,MAXTEXTSIZE
	sub dx,bx
	mov cx,dx

CONCATSIGO:
	push ds
	pop es
	pop si
	pop ds
	cld
	rep movsb
	mov al,'$'
	mov BYTE PTR [DI],al
	ret

CONCAT ENDP
END START; final del archivo. 

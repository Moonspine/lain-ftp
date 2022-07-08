; DOS String I/O library
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Calls printString with the given string variable's address
callPrintString MACRO p_stringAddress
	mov dx, SEG p_stringAddress
	mov ds, dx
	mov dx, OFFSET p_stringAddress
	call printString
ENDM

; Calls readString with the given stringBuffer address
; The first byte of the buffer must be the maximum string length
; The next byte of the buffer will be overwritten with the read string length
; The rest of the buffer will contain a null-terminated string
callReadString MACRO p_stringBuffer
	mov dx, SEG p_stringBuffer
	mov ds, dx
	mov dx, OFFSET p_stringBuffer
	call readString
ENDM


; Reads user input as a null-terminated string in the buffer in ds:dx
readString PROC
	; Read the string
	mov ah, 0ah
	int 21h
	
	; Add the null terminator
	mov bx, dx
	add bx, 1
	mov cl, [bx]
	clc
	add bl, cl
	adc bh, 0
	add bx, 1
	mov cl, 0
	mov [bx], cl
	
	ret
readString ENDP

; Prints the string in ds:dx
printString PROC
	mov ah, 9
	int 21h
	ret
printString ENDP

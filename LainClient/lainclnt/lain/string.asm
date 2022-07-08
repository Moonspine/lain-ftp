; LainFTP String Manipulation Library
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Compares stringA to stringB (to a maximum of maxLength characters)
; After the call, ax will be 0 if they are equal, nonzero if they are not equal
callCompareStrings MACRO stringA, stringB, maxLength
	mov di, SEG stringA
	mov ds, di
	mov di, OFFSET stringA
	
	mov bx, SEG stringB
	mov es, bx
	mov bx, OFFSET stringB
	
	mov cx, maxLength
	call compareStrings
ENDM

; Compares up to cx bytes from ds:di to es:bx
; After the call, ax will be 0 if they are equal, nonzero if they are not equal
compareStrings PROC
	mov ax, 0
compareStrings_LOOP:
	; If we've compared our last byte, they're equal
	cmp cx, 0
	je compareStrings_RETURN
	
	; Compare the characters
	mov dl, [ds:di]
	cmp dl, [es:bx]
	jne compareStrings_DIFFERENT
	
	; Next character
	inc di
	inc bx
	dec cx
	jmp compareStrings_LOOP
	
compareStrings_DIFFERENT:
	mov ax, 1
	
compareStrings_RETURN:
	ret
compareStrings ENDP

; Renders the number in ax as a human-readable ASCII string in ds:di
; The number will be right-justified in the buffer, padded with spaces on the left
; After the call, the actual number of rendered digits will be in cx
wordToASCII PROC
	; Setup
	mov cx, 1
	add di, 4
	
	; First pass is special, as it always renders a zero
	mov dx, 0
	mov bx, 10
	div bx
	add dl, "0"
	mov [ds:di], dl
	dec di
	
	mov bx, 0
wordToASCII_LOOP:
	; Bail if we're at the end
	cmp bx, 4
	je wordToASCII_RETURN
	inc bx
	
	; Print a space?
	cmp ax, 0
	je wordToASCII_RenderSpace
	
	; Print the next character
	mov dx, 0
	push bx
	mov bx, 10
	div bx
	pop bx
	add dl, "0"
	mov [ds:di], dl
	dec di
	inc cx
	
	jmp wordToASCII_LOOP
	
wordToASCII_RenderSpace:
	; Render a space
	mov dl, " "
	mov [ds:di], dl
	dec di
	
	jmp wordToASCII_LOOP
	
wordToASCII_RETURN:
	ret
wordToASCII ENDP

; Copies only the filename (the part after the last ':' or '\') from null-terminated [ds:di] to [es:bx]
copyFilenameOnly PROC
	; Save a copy of the write position
	mov ax, bx
	
copyFilenameOnly_LOOP:
	; Load the next character
	mov cl, [ds:di]
	inc di
	
	; If "\" or ":", reset write position
	cmp cl, "\"
	je copyFilenameOnly_RESETPOS
	cmp cl, ":"
	je copyFilenameOnly_RESETPOS
	
	jmp copyFilenameOnly_CONTINUE
	
copyFilenameOnly_RESETPOS:
	; Reset the write position
	mov bx, ax
	jmp copyFilenameOnly_LOOP
	
copyFilenameOnly_CONTINUE:
	; Copy the character
	mov [es:bx], cl
	inc bx

	; If null, we're done
	cmp cl, 0
	jne copyFilenameOnly_LOOP
	
	ret
copyFilenameOnly ENDP

; Copies only the filename (the part after the last ':' or '\') from null-terminated bufferA to bufferB
callCopyFilenameOnly MACRO bufferA, bufferB
	mov di, SEG bufferA
	mov ds, di
	mov di, OFFSET bufferA
	mov bx, SEG bufferB
	mov es, bx
	mov bx, OFFSET bufferB
	call copyFilenameOnly
ENDM

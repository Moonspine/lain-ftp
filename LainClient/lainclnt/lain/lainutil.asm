; LainFTP Client Utility Library
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Sets the current lain directory to the given buffer
; After the call, ax will be zero if no error occurred
callSetCurrentLainDirectory MACRO buffer
	mov di, SEG buffer
	mov ds, di
	mov di, OFFSET buffer
	call setCurrentLainDirectory
ENDM

; Gets the current lain directory as a null-terminated string into the serial buffer
getCurrentLainDirectory PROC
	; Read the string
	copyAndSendDataNullTerminated commandStr_DIR_NoParam
	call readSerialPortUntilLF
	
	; Terminate it and strip CR/LF
	mov di, SEG serialBuffer
	mov ds, di
	mov di, OFFSET serialBuffer
getCurrentLainDirectory_TERM_LOOP:
	mov cl, [ds:di]
	
	cmp cl, 10
	je getCurrentLainDirectory_TERMINATE
	
	cmp cl, 13
	je getCurrentLainDirectory_TERMINATE
	
	cmp cl, 0
	je getCurrentLainDirectory_RETURN
	
	inc di
	jmp getCurrentLainDirectory_TERM_LOOP
	
getCurrentLainDirectory_TERMINATE:
	mov cl, 0
	mov [ds:di], cl
	
getCurrentLainDirectory_RETURN:
	ret
getCurrentLainDirectory ENDP

; Sets the current lain directory to the buffer stored in ds:di
; After the call, ax will be zero if no error occurred
setCurrentLainDirectory PROC
	; We need to put these registers on ice for a minute
	push ds
	push di
	
	; First, copy the command
	mov bx, SEG serialBuffer
	mov es, bx
	mov bx, OFFSET serialBuffer
	
	mov di, SEG commandStr_DIR_Param
	mov ds, di
	mov di, OFFSET commandStr_DIR_Param
	
	call memcopyUntilNull

	; Copy the user-specified directory string
	pop di
	pop ds
	call memcopyUntilNull
	
	; Append a newline
	mov di, SEG commandStr_Newline
	mov ds, di
	mov di, OFFSET commandStr_Newline
	call memcopyUntilNull
	
	; Send the command
	mov cx, bx
	sub cx, OFFSET serialBuffer
	callWriteSerialPortBytes
	
	; Receive the response
	call readSerialPortUntilLF
	push ax
	
	; If not OK, we have an error
	callCompareStrings serialBuffer, responseStr_OK, 2
	cmp ax, 0
	pop ax
	je setCurrentLainDirectory_OK
	
	; Print the error message
	terminateAndPrintSerialBuffer serialBuffer, 0
	callPrintString str_NewLine
	
	; Set ax to indicate an error
	mov ax, 1
	jmp setCurrentLainDirectory_RETURN

setCurrentLainDirectory_OK:
	mov ax, 0

setCurrentLainDirectory_RETURN:
	ret
setCurrentLainDirectory ENDP

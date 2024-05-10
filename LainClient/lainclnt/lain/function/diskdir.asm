; LainFTP Change Disk/Directory Function Implementation
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Sends a simple Lain command which takes 1 user-specified parameter (I.e. DISK, DIR)
sendSimpleCommand MACRO prompt, commandString, commandStringLength
	LOCAL sendSimpleCommand_RETURN
	LOCAL sendSimpleCommand_NOTEMPTY

	; Prompt for user-specified parameter
	callPrintString prompt
	callPrintString str_Prompt
	callReadString inputBufferInfo
	callPrintString str_NewLine
	
	; Get the number of input bytes
	mov bx, SEG inputBufferLength
	mov ds, bx
	mov bx, OFFSET inputBufferLength
	mov ah, 0
	mov al, [bx]
	push ax
	
	; If empty, return
	cmp al, 0
	jne sendSimpleCommand_NOTEMPTY
	jmp sendSimpleCommand_RETURN
	
sendSimpleCommand_NOTEMPTY:
	; Build the serial buffer data
	
	; From address
	mov di, SEG commandString
	mov ds, di
	mov di, OFFSET commandString
	
	; To address
	mov bx, SEG serialBuffer
	mov es, bx
	mov bx, OFFSET serialBuffer
	
	; Copy command string
	mov cx, commandStringLength
	call memcopy
	
	; Add a space
	mov cl, " "
	mov [bx], cl
	inc bx
	
	; Copy the user-specified parameter into the serial buffer
	mov di, SEG inputBuffer
	mov ds, di
	mov di, OFFSET inputBuffer
	
	pop cx
	call memcopy
	
	; Append a newline
	mov cl, 10
	mov [bx], cl
	inc bx
	
	; Send the command
	mov cx, bx
	sub cx, OFFSET serialBuffer
	call writeSerialPortImpl
	
	; Receive the response
	call readSerialPortUntilLF
	push ax
	
	; Compare the response to "OK"
	callCompareStrings serialBuffer, responseStr_OK, 2
	cmp ax, 0
	pop ax
	je sendSimpleCommand_RETURN
	
	; Print the error message
	terminateAndPrintSerialBuffer serialBuffer, 0
	callPrintString str_NewLine
	
sendSimpleCommand_RETURN:
ENDM

; Changes the current disk
changeDiskProc PROC
	sendSimpleCommand diskStr_Prompt, commandStr_DISK_NoParam, 4
	ret
changeDiskProc ENDP

; Changes the current directory
changeDirProc PROC
	sendSimpleCommand dirStr_Prompt, commandStr_DIR_NoParam, 3
	ret
changeDirProc ENDP

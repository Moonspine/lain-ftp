; LainFTP Change File List Function Implementation
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Lists files in the current directory
listFilesProc PROC
	; Send the LIST command
	copyAndSendDataNullTerminated commandStr_LIST_NoParam

	mov tempVar, 0
listFilesProc_LOOP:
	; Receive results
	call readSerialPortUntilLF
	
	; Test to see if we've read the last file entry
	push ax
	callCompareStrings serialBuffer, responseStr_EOF, 5
	cmp ax, 0
	pop ax
	je listFilesProc_END
	
	; Print the file to the screen
	terminateAndPrintSerialBuffer serialBufferTab, 1
	
	; Increment file count
	inc tempVar
	
	; If file count is a multiple of 20, pause for a second
	mov dx, 0
	mov ax, tempVar
	mov bx, 20
	div bx
	cmp dx, 0
	jne listFilesProc_Continue
	
	callPrintString str_enterToContinue
	callReadString inputBufferInfo
	
listFilesProc_Continue:
	; Acknowledge
	copyAndSendDataNullTerminated responseStr_OK
	
	jmp listFilesProc_LOOP
	
listFilesProc_END:
	callPrintString str_NewLine
	
	; Print file count to serial buffer
	mov di, SEG serialBuffer
	mov ds, di
	mov es, di
	mov di, OFFSET serialBuffer
	mov ax, tempVar
	call wordToASCII
	
	; Append files message
	mov bx, OFFSET serialBuffer
	add bx, 5
	mov di, OFFSET listStr_Files
	call memcopyUntilNull
	
	; Print files message
	callPrintString serialBuffer
	callPrintString str_NewLine
	
	; Wait for the user to press a key before continuing
	callPrintString str_enterToContinue
	callReadString inputBufferInfo

	ret
listFilesProc ENDP

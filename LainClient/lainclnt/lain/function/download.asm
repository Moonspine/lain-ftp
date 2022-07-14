; LainFTP Download File Function Implementation
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Downloads the file whose filename is contained in inputBuffer from the Lain server the the local filename specified in inputBuffer2
; After the call, ax will be 0 if no errors occurred
downloadFile PROC
	; Default state is error (gets set to zero on success)
	mov tempVar3, 1

	; Initial confirmation message
	copyDataNullTerminated downloadStr_downloading, serialBuffer
	copyDataNullTerminatedContinue inputBuffer
	copyDataNullTerminatedContinue downloadStr_to
	copyDataNullTerminatedContinue inputBuffer2
	copyDataNullTerminatedContinue str_NewLine
	callPrintString serialBuffer
	
	; Open the file for write
	callCreateFile inputBuffer2, fileHandle, fileErrorCode
	cmp fileErrorCode, 0
	je downloadFile_FILEOPENED
	
	; Failed to open the file
	callPrintString fileErrorStr_OpenWriteFailed
	jmp downloadFile_RETURN
	
downloadFile_FILEOPENED:
	; Send the DOWNLOADB command
	copyDataNullTerminated commandStr_DOWNLOAD_1, serialBuffer
	copyDataNullTerminatedContinue inputBuffer
	copyDataNullTerminatedContinue commandStr_DOWNLOAD_2
	push bx
	mov di, bx
	mov ax, config_downloadPacketSize
	call wordToASCII
	pop bx
	add bx, 5
	copyDataNullTerminatedContinue commandStr_DOWNLOAD_3
	mov cx, bx
	sub cx, OFFSET serialBuffer
	callWriteSerialPortBytes
	
	; Receive packets
	mov tempVar, 1
downloadFile_NEXTPACKET:
	; Read the packet size
	mov cx, 2
	call readSerialPortBytes
	
	; Read the packet size
	mov bx, OFFSET serialBuffer
	mov cx, [bx]
	
	; If the packet size is zero, and we're on the first packet, there was an error
	cmp cx, 0
	jne downloadFile_CONTINUE_PACKET
	cmp tempVar, 1
	jne downloadFile_CONTINUE_PACKET
	
	; Display the error message and exit
	call readSerialPortUntilLF
	terminateAndPrintSerialBuffer serialBuffer, 0
	callPrintString str_NewLine
	jmp downloadFile_FINISHED
	
downloadFile_CONTINUE_PACKET:
	; If the packet size is zero, the transfer is over
	cmp cx, 0
	jne downloadFile_PRINT_PROGRESS
	jmp downloadFile_SUCCESS
	
downloadFile_PRINT_PROGRESS:
	; Write the progress message
	push cx
	copyDataNullTerminated downloadStr_progressMessage_1, serialBuffer
	push bx
	mov di, bx
	mov ax, tempVar
	call wordToASCII
	pop bx
	add bx, 5
	copyDataNullTerminatedContinue downloadStr_progressMessage_2
	pop ax
	push ax
	push bx
	mov di, bx
	call wordToASCII
	pop bx
	add bx, 5
	copyDataNullTerminatedContinue downloadStr_progressMessage_3
	callPrintString serialBuffer
	
	; Grab the next packet
	pop cx
	push cx
	call readSerialPortBytes
	
	; Write it to the file
	pop cx
	mov dx, SEG serialBuffer
	mov ds, dx
	mov dx, OFFSET serialBuffer
	mov bx, fileHandle
	call writeFile
	
	; On error, abort
	cmp bx, 0
	jne downloadFile_ABORT
	
	; On success, send OK
	copyDataNullTerminated responseStr_OK, serialBuffer
	mov cx, bx
	sub cx, OFFSET serialBuffer
	callWriteSerialPortBytes
	
	; Update next packet
	inc tempVar
	
	jmp downloadFile_NEXTPACKET


downloadFile_SUCCESS:
	; Print success message
	callPrintString downloadStr_finished
	
downloadFile_FINISHED:
	; Close the file
	callCloseFile fileHandle
	
	jmp downloadFile_RETURN
	
downloadFile_ABORT:
	; Abort the transfer and close the file
	copyDataNullTerminated responseStr_ABORT, serialBuffer
	mov cx, bx
	sub cx, OFFSET serialBuffer
	callWriteSerialPortBytes
	callCloseFile fileHandle
	
downloadFile_RETURN:
	mov ax, tempVar3
	ret
downloadFile ENDP

; Downloads a file from the server
downloadFileProc PROC
	; Prompt the user for the server filename to download
	callPrintString downloadStr_serverFilenamePrompt
	callReadString inputBufferInfo
	cmp inputBufferLength, 0
	je downloadFileProc_RETURN
	
	; Prompt the user for the local filename to download to
	callPrintString downloadStr_localFilenamePrompt
	callReadString inputBuffer2Info
	cmp inputBuffer2Length, 0
	je downloadFileProc_RETURN
	
	; Download the file specified in inputBuffer from the server to the file specified in inputBuffer2
	call downloadFile
downloadFileProc_RETURN:
	ret
downloadFileProc ENDP
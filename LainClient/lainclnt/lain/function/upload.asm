; LainFTP Upload File Function Implementation
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Upload the file whose local filename is contained in inputBuffer to the server as the filename contained in inputBuffer2
; After the call, ax will be 0 if no errors occurred
uploadFile PROC
	; Default state is error (gets set to zero on success)
	mov tempVar3, 1

	; Initial confirmation message
	copyDataNullTerminated uploadStr_uploading, serialBuffer
	copyDataNullTerminatedContinue inputBuffer
	copyDataNullTerminatedContinue uploadStr_as
	copyDataNullTerminatedContinue inputBuffer2
	copyDataNullTerminatedContinue str_NewLine
	callPrintString serialBuffer
	
	; Open the file for read
	callOpenFile inputBuffer, fileHandle, fileErrorCode
	cmp fileErrorCode, 0
	je uploadFile_FILEOPENED
	
	; Failed to open the file
	callPrintString fileErrorStr_OpenReadFailed
	jmp uploadFile_RETURN
	
uploadFile_FILEOPENED:
	; Send the UPLOADB command
	copyDataNullTerminated commandStr_UPLOADB_1, serialBuffer
	copyDataNullTerminatedContinue inputBuffer2
	copyDataNullTerminatedContinue commandStr_UPLOADB_2
	push bx
	mov di, bx
	mov ax, config_uploadPacketSize
	call wordToASCII
	pop bx
	add bx, 5
	copyDataNullTerminatedContinue commandStr_UPLOADB_3
	mov cx, bx
	sub cx, OFFSET serialBuffer
	callWriteSerialPortBytes

	; Listen for the "OK"
	call readSerialPortUntilLF
	callCompareStrings serialBuffer, responseStr_OK, 2
	cmp ax, 0
	je uploadFile_BEGIN
	
	; If we didn't get an okay, print the error message
	terminateAndPrintSerialBuffer serialBuffer, 0
	callPrintString str_NewLine
	jmp uploadFile_FINISHED
	
	; Begin sending packets
uploadFile_BEGIN:
	mov tempVar, 0

uploadFile_LOOP:
	; Read data packet from file
	callReadFile fileHandle, config_uploadPacketSize, serialBufferCont, fileErrorCode, tempVar2
	inc tempVar
	
	; Abort if an error occurred
	cmp fileErrorCode, 0
	je uploadFile_LOOP_SEND
	
	; Print read error message
	callPrintString fileErrorStr_ReadFailed
	jmp uploadFile_FINISHED
	
uploadFile_LOOP_SEND:
	; Load the number of bytes to send
	mov cx, tempVar2
	mov bx, OFFSET serialBuffer
	mov [bx], cx
	
	; Finished?
	cmp cx, 0
	jne uploadFile_SEND_NOT_FINISHED
	jmp uploadFile_SEND_FINISHED

uploadFile_SEND_NOT_FINISHED:
	; Write the progress message
	push cx
	copyDataNullTerminated uploadStr_progressMessage_1, scratchBuffer
	push bx
	mov di, bx
	mov ax, tempVar
	call wordToASCII
	pop bx
	add bx, 5
	copyDataNullTerminatedContinue uploadStr_progressMessage_2
	mov ax, tempVar2
	push bx
	mov di, bx
	call wordToASCII
	pop bx
	add bx, 5
	copyDataNullTerminatedContinue uploadStr_progressMessage_3
	callPrintString scratchBuffer
	pop cx
	
	; Send the packet
	add cx, 2
	callWriteSerialPortBytes
	
	; Await a response
	call readSerialPortUntilLF
	
	; Did the server receive the packet? If so, continue.
	callCompareStrings serialBuffer, responseStr_OK, 2
	cmp ax, 0
	jne uploadFile_CHECK_RETRY
	jmp uploadFile_LOOP
	
uploadFile_CHECK_RETRY:
	; Do we need to retry?
	callCompareStrings serialBuffer, responseStr_RETRY, 2
	cmp ax, 0
	jne uploadFile_CHECK_ERROR
	jmp uploadFile_LOOP_SEND
	
uploadFile_CHECK_ERROR:
	; Or was there an error?
	callPrintString uploadStr_Error
	jmp uploadFile_FINISHED
	
	
uploadFile_SEND_FINISHED:
	; Send a null packet
	mov cx, 0
	mov bx, OFFSET serialBuffer
	mov [bx], cx
	mov cx, 2
	callWriteSerialPortBytes
	
	; Print success message
	callPrintString uploadStr_Finished
	
	; Success
	mov tempVar3, 0
	
uploadFile_FINISHED:
	; Close the file
	callCloseFile fileHandle
	
	jmp uploadFile_RETURN

uploadFile_RETURN:
	mov ax, tempVar3

	ret
uploadFile ENDP

; Uploads a file to the server
uploadFileProc PROC
	; Prompt the user for the local filename to upload
	callPrintString uploadStr_localFilenamePrompt
	callReadString inputBufferInfo
	cmp inputBufferLength, 0
	je uploadFileProc_RETURN
	
	; Copy the filename into the server filename buffer
	callCopyFilenameOnly inputBuffer, scratchBuffer
	
	; Prompt the user for the server filename to upload as
	copyDataNullTerminated uploadStr_serverFilenamePrompt1, serialBuffer
	copyDataNullTerminatedContinue scratchBuffer
	copyDataNullTerminatedContinue uploadStr_serverFilenamePrompt2
	callPrintString serialBuffer
	callReadString inputBuffer2Info
	
	; If the user entered an empty line, copy the automatic filename to the server filename input buffer
	cmp inputBuffer2Length, 0
	jne uploadFileProc_UPLOAD
	copyDataNullTerminated scratchBuffer, inputBuffer2
	
uploadFileProc_UPLOAD:
	; Upload the file specified in inputBuffer to the server as the file specified in inputBuffer2
	call uploadFile

uploadFileProc_RETURN:
	mov ax, tempVar3
	ret
uploadFileProc ENDP

; LainFTP Upload Directory Function Implementation
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Recursively uploads the directory stored in localFileBuffer to the Lain server
uploadDirRecursively PROC
	; Get the current Lain directory
	call getCurrentLainDirectory
	copyDataNullTerminated serialBuffer, lainFileBuffer
	
	; Append a backslash if necessary
	callAppendCharacterIfAbsent lainFileBuffer, "\"

	; Update Lain directory string length
	mov ax, di
	sub ax, OFFSET lainFileBuffer
	mov lainFileBufferLength, al
	
	; Push the local directory to the stack
	callPushStringToStack localFileBuffer

uploadDirRecursively_LOOP:
	; If the stack is empty, we're done
	mov ax, strStackIndex
	cmp ax, 0
	jne uploadDirRecursively_NOTEMPTY
	jmp uploadDirRecursively_RETURN
	

uploadDirRecursively_NOTEMPTY:
	; Pop local directory
	callPopStringFromStack localFileBuffer
	
	; Build the new Lain directory by appending the current subdirectory
	copyDataNullTerminated lainFileBuffer, scratchBuffer
	mov di, OFFSET localFileBuffer
	mov ch, 0
	mov cl, localFileBufferLength
	add di, cx
	call memcopyUntilNull
	
	; Set the Lain directory, checking for errors
	callSetCurrentLainDirectory scratchBuffer
	cmp ax, 0
	je uploadDirRecursively_DIRSET
	jmp uploadDirRecursively_RETURN
	
uploadDirRecursively_DIRSET:
	; Build the search string
	copyDataNullTerminated localFileBuffer, scratchBuffer2
	copyDataNullTerminatedContinue fileSearch_AllFiles

	; Find the first file
	callFindFirstFile scratchBuffer2
	
	; If no files are in the directory, continue the loop
	cmp ax, 18
	je uploadDirRecursively_LOOP
	
	; If another error occurred, we have a problem
	cmp ax, 0
	je uploadDirRecursively_CONTINUEDIRLIST
	
	; Print an error message and abort
	callPrintString fileErrorStr_FileListFailed
	jmp uploadDirRecursively_RETURN
	
uploadDirRecursively_CONTINUEDIRLIST:
	; Is it a directory?
	mov cl, dtaFileAttribute
	and cl, 10h
	cmp cl, 0
	jne uploadDirRecursively_PUSHDIR
	
uploadDirRecursively_UPLOADFILE:
	; Copy the local filename
	copyDataNullTerminated localFileBuffer, inputBuffer
	copyDataNullTerminatedContinue dtaFilename
	
	; Copy the Lain filename
	copyDataNullTerminated dtaFilename, inputBuffer2
	
	; Upload the file
	call uploadFile
	
	; Error?
	cmp ax, 0
	je uploadDirRecursively_NEXTFILE
	
	; Print error message and bail
	callPrintString uploadDirStr_uploadFailed
	jmp uploadDirRecursively_RETURN

uploadDirRecursively_PUSHDIR:
	; Don't push if the directory starts with a "."
	mov cl, dtaFilename
	cmp cl, "."
	je uploadDirRecursively_NEXTFILE

	; Copy the local filename
	copyDataNullTerminated localFileBuffer, scratchBuffer
	copyDataNullTerminatedContinue dtaFilename
	callAppendCharacterIfAbsent scratchBuffer, "\"
	
	; Push the filename
	callPushStringToStack scratchBuffer

uploadDirRecursively_NEXTFILE:
	; Get the next file
	callFindNextFile scratchBuffer2
	
	; Done?
	cmp ax, 18
	je uploadDirRecursively_ENDDIRLIST
	
	; Error?
	cmp ax, 0
	jne uploadDirRecursively_DIRERROR
	jmp uploadDirRecursively_CONTINUEDIRLIST
	
uploadDirRecursively_DIRERROR:
	; Print an error message and abort
	callPrintString fileErrorStr_FileListFailed
	jmp uploadDirRecursively_RETURN
	
uploadDirRecursively_ENDDIRLIST:
	; Loop until stack is empty
	jmp uploadDirRecursively_LOOP

uploadDirRecursively_RETURN:
	ret
uploadDirRecursively ENDP

; Recursively uploads a local directory into the current Lain directory
uploadDirProc PROC
	; Prompt the user for the local directory to upload
	callPrintString uploadDirStr_localDirPrompt
	callReadString localFileBufferInfo
	cmp localFileBufferLength, 0
	je uploadDirProc_RETURN
	
	; Append a backslash if necessary
	callAppendCharacterIfAbsent localFileBuffer, "\"
	
	; Update local directory string length
	mov ax, di
	sub ax, OFFSET localFileBuffer
	mov localFileBufferLength, al
	
	; Prompt the user for the confirmation
	callPrintString uploadDirStr_confirmPrompt
	callReadString inputBufferInfo
	
	; Check for empty, y/Y
	cmp inputBufferLength, 0
	je uploadDirProc_RETURN
	mov cl, inputBuffer
	cmp cl, "y"
	je uploadDirProc_UPLOAD
	cmp cl, "Y"
	je uploadDirProc_UPLOAD
	jmp uploadDirProc_RETURN

	; Upload
uploadDirProc_UPLOAD:
	call uploadDirRecursively

uploadDirProc_RETURN:
	ret
uploadDirProc ENDP

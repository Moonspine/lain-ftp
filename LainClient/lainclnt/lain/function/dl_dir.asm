; LainFTP Download Directory Function Implementation
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Recursively downloads the current Lain directory into the directory stored in localFileBuffer
downloadDirRecursively PROC
	; Get the current Lain directory
	call getCurrentLainDirectory
	copyDataNullTerminated serialBuffer, lainFileBuffer
	
	; Append a backslash if necessary
	callAppendCharacterIfAbsent lainFileBuffer, "\"
	
	; Update Lain directory string length
	mov ax, di
	sub ax, OFFSET lainFileBuffer
	mov lainFileBufferLength, al

	; Push the Lain directory to the stack
	callPushStringToStack lainFileBuffer
	
	; TODO

	ret
downloadDirRecursively ENDP

; Recursively downloads the current Lain directory into a local directory
downloadDirProc PROC
	; Prompt the user for the local directory to download into
	callPrintString downloadDirStr_localDirPrompt
	callReadString localFileBufferInfo
	cmp localFileBufferLength, 0
	je downloadDirProc_RETURN
	
	; Append a backslash if necessary
	callAppendCharacterIfAbsent localFileBuffer, "\"
	
	; Update local directory string length
	mov ax, di
	sub ax, OFFSET localFileBuffer
	mov localFileBufferLength, al
	
	; Prompt the user for the confirmation
	callPrintString downloadDirStr_confirmPrompt
	callReadString inputBufferInfo
	
	; Check for empty, y/Y
	cmp inputBufferLength, 0
	je downloadDirProc_RETURN
	mov cl, inputBuffer
	cmp cl, "y"
	je downloadDirProc_DOWNLOAD
	cmp cl, "Y"
	je downloadDirProc_DOWNLOAD
	jmp downloadDirProc_RETURN

	; Download
downloadDirProc_DOWNLOAD:
	call downloadDirRecursively

downloadDirProc_RETURN:
	ret
downloadDirProc ENDP

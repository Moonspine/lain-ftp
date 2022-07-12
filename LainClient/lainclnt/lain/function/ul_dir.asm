; LainFTP Upload Directory Function Implementation
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Recursively uploads the directory stored in inputBuffer to the Lain server
uploadDirRecursively PROC
	; TODO

	ret
uploadDirRecursively ENDP

; Recursively uploads a local directory into the current Lain directory
uploadDirProc PROC
	; Prompt the user for the local directory to upload
	callPrintString uploadDirStr_localDirPrompt
	callReadString inputBufferInfo
	cmp inputBufferLength, 0
	je uploadDirProc_RETURN
	
	; Prompt the user for the confirmation
	callPrintString uploadDirStr_confirmPrompt
	callReadString inputBuffer2Info
	
	; Check for empty, y/Y
	cmp inputBuffer2Length, 0
	je uploadDirProc_RETURN
	mov cl, inputBuffer2
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

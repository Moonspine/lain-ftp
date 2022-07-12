; LainFTP Download Directory Function Implementation
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Recursively downloads the current Lain directory into the directory stored in inputBuffer
downloadDirRecursively PROC
	; TODO

	ret
downloadDirRecursively ENDP

; Recursively downloads the current Lain directory into a local directory
downloadDirProc PROC
	; Prompt the user for the local directory to download into
	callPrintString downloadDirStr_localDirPrompt
	callReadString inputBufferInfo
	cmp inputBufferLength, 0
	je downloadDirProc_RETURN
	
	; Prompt the user for the confirmation
	callPrintString downloadDirStr_confirmPrompt
	callReadString inputBuffer2Info
	
	; Check for empty, y/Y
	cmp inputBuffer2Length, 0
	je downloadDirProc_RETURN
	mov cl, inputBuffer2
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

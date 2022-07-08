; LainFTP Menu Implementation
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Displays the menu and asks the user for their choice
menuProc PROC
DISPLAY_MENU:
	; Version
	callPrintString menuStr_Version
	callPrintString str_NewLine
	
	; Current disk name
	copyAndSendDataNullTerminated commandStr_DISK_NoParam
	callPrintString menuStr_CurrentDisk
	call readSerialPortUntilLF
	terminateAndPrintSerialBuffer serialBuffer, 0
	
	; Current directory name
	copyAndSendDataNullTerminated commandStr_DIR_NoParam
	callPrintString menuStr_CurrentDir
	call readSerialPortUntilLF
	terminateAndPrintSerialBuffer serialBuffer, 0
	
	; Choice list
	callPrintString str_NewLine
	callPrintString menuStr_List_Start
	
	; Enter a choice
ENTER_CHOICE:
	callPrintString str_Prompt
	callReadString inputBufferInfo
	callPrintString str_NewLine
	
	; Validate input length
	mov bx, SEG inputBuffer
	mov ds, bx
	mov bx, OFFSET inputBufferLength
	mov al, [bx]
	cmp al, 1
	jne INVALID_CHOICE
	
	; Read input choice
	mov bx, OFFSET inputBuffer
	mov al, [bx]
	
	; Input parsing
CHECK_CHOICE_1:
	cmp al, "1"
	jne CHECK_CHOICE_2
	call changeDiskProc
	jmp DISPLAY_MENU
	
CHECK_CHOICE_2:
	cmp al, "2"
	jne CHECK_CHOICE_3
	call changeDirProc
	jmp DISPLAY_MENU
	
CHECK_CHOICE_3:
	cmp al, "3"
	jne CHECK_CHOICE_4
	call listFilesProc
	jmp DISPLAY_MENU

CHECK_CHOICE_4:
	cmp al, "4"
	jne CHECK_CHOICE_5
	call uploadFileProc
	jmp DISPLAY_MENU
	
CHECK_CHOICE_5:
	cmp al, "5"
	jne CHECK_CHOICE_6
	call downloadFileProc
	jmp DISPLAY_MENU
	
CHECK_CHOICE_6:
	cmp al, "6"
	jne INVALID_CHOICE
	call exitProc
	
INVALID_CHOICE:
	callPrintString menuStr_InvalidChoice
	jmp ENTER_CHOICE

	ret
menuProc ENDP

; Closes the serial port and exits the program
exitProc PROC
	callCloseFile serialPortHandle
	call exitToDOS
exitProc ENDP

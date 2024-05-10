; LainFTP Main Program
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

.8086

DATA segment
	; Application configuration
	; 128-byte packets seem to be the largest the HP-150 can handle successfully
	config_downloadPacketSize dw 128
	config_uploadPacketSize dw 128

	; Menu strings
	menuStr_Version db "LainFTP Client Version 2.1", 13, 10, "$"
	menuStr_CurrentDisk db "Current disk: ", "$"
	menuStr_CurrentDir db "Current directory: ", "$"
	menuStr_List_Start db "Enter a choice from the following menu:", 13, 10
	menuStr_List_1 db "1. Change disk", 13, 10
	menuStr_List_2 db "2. Change directory", 13, 10
	menuStr_List_3 db "3. List files", 13, 10
	menuStr_List_4 db "4. Upload file to server", 13, 10
	menuStr_List_5 db "5. Download file from server", 13, 10
	menuStr_List_6 db "6. Upload directory to server", 13, 10
	; Feature not yet implemented
	;menuStr_List_7 db "7. Download directory from server", 13, 10
	menuStr_List_8 db "8. Quit", 13, 10, "$"
	menuStr_InvalidChoice db "Invalid choice. Must be between 1 and 8, inclusive.", 13, 10, "$"
	
	; 1) Change disk strings
	diskStr_Prompt db "Enter name of disk to switch to (empty line to cancel)", 13, 10, "$"
	
	; 2) Change directory strings
	dirStr_Prompt db "Enter name of directory to switch to (empty line to cancel)", 13, 10, "$"
	
	; 3) List strings
	listStr_Files db " files", 13, 10, "$", 0
	
	; 4) Upload strings
	uploadStr_localFilenamePrompt db "Enter filename to upload to server (empty line to cancel)", 13, 10, "$"
	uploadStr_serverFilenamePrompt1 db 13, 10, "Enter filename to send as (empty line to send as ", 0
	uploadStr_serverFilenamePrompt2 db ")", 13, 10, "$", 0
	uploadStr_uploading db 13, 10, "Uploading ", 0
	uploadStr_as db " as ", 0
	uploadStr_Error db 13, 10, "Upload failed. Check the server and try again.", 13, 10, 13, 10, "$"
	uploadStr_progressMessage_1 db "Uploading packet #", 0
	uploadStr_progressMessage_2 db " (", 0
	uploadStr_progressMessage_3 db " bytes)", 13, 10, "$", 0
	uploadStr_Finished db "File uploaded successfully", 13, 10, 13, 10, "$"
	
	; 5) Download strings
	downloadStr_serverFilenamePrompt db "Enter filename to download from the server (empty line to cancel)", 13, 10, "$"
	downloadStr_localFilenamePrompt db 13, 10, "Enter filename to save to (empty line to cancel)", 13, 10, "$"
	downloadStr_downloading db 13, 10, "Downloading ", 0
	downloadStr_to db " to ", 0
	downloadStr_progressMessage_1 db "Downloading packet #", 0
	downloadStr_progressMessage_2 db " (", 0
	downloadStr_progressMessage_3 db " bytes)", 13, 10, "$", 0
	downloadStr_finished db "File downloaded successfully", 13, 10, 13, 10, "$"
	
	; 6) Upload directory strings
	uploadDirStr_localDirPrompt db "Enter the local directory to upload to the server (empty line to cancel)", 13, 10, "$"
	uploadDirStr_confirmPrompt db 13, 10, 13, 10, "Are you sure you have the right disk/directory set?", 13, 10, "Duplicate files on the server will be overwritten!", 13, 10, 13, 10, "Type 'Y' to start, anything else to cancel.", 13, 10, "$"
	uploadDirStr_uploadFailed db 13, 10, "Upload failed", 13, 10, 13, 10, "$"
	
	; 7) Download directory strings
	downloadDirStr_localDirPrompt db "Enter the local directory to download into (empty line to cancel)", 13, 10, "$"
	downloadDirStr_confirmPrompt db 13, 10, 13, 10, "Are you sure you have the right disk/directory set?", 13, 10, "Duplicate files on the local disk will be overwritten!", 13, 10, 13, 10, "Type 'Y' to start, anything else to cancel.", 13, 10, "$"
	
	; General strings
	str_NewLine db 13, 10, "$", 0
	str_Prompt db 13, 10, "? ", "$"
	str_returnToMenu db "Press enter to return to the menu", 13, 10, "$"
	str_enterToContinue db "Press enter to continue", 13, 10, "$"
	
	; File error strings
	fileErrorStr_OpenWriteFailed db 13, 10, "Failed to open the file for write", 13, 10, 13, 10, "$"
	fileErrorStr_OpenReadFailed db 13, 10, "Failed to open the file for read", 13, 10, 13, 10, "$"
	fileErrorStr_WriteFailed db 13, 10, "Failed to write to the file", 13, 10, 13, 10, "$"
	fileErrorStr_ReadFailed db 13, 10, "Failed to read from the file", 13, 10, 13, 10, "$"
	fileErrorStr_FileListFailed db 13, 10, "Failed to list files in the directory; aborting", 13, 10, 13, 10, "$"
	fileErrorStr_Generic db 13, 10, "File I/O failed", 13, 10, 13, 10, "$"
	
	
	; Command strings (null-terminated)
	commandStr_DISK_NoParam db "DISK", 10, 0
	commandStr_DIR_NoParam db "DIR", 10, 0
	commandStr_DIR_Param db "DIR ", 0
	commandStr_LIST_NoParam db "LIST", 10, 0
	commandStr_DOWNLOAD_1 db "DOWNLOADB ", 0
	commandStr_DOWNLOAD_2 db " ", 0
	commandStr_DOWNLOAD_3 db 13, 10, 0
	commandStr_UPLOADB_1 db "UPLOADB ", 0
	commandStr_UPLOADB_2 db " ", 0
	commandStr_UPLOADB_3 db 13, 10, 0
	commandStr_Newline db 10, 0
	
	; Response strings (null-terminated)
	responseStr_OK db "OK", 13, 10, 0
	responseStr_RETRY db "RETRY", 13, 10, 0
	responseStr_ABORT db "ABORT", 13, 10, 0
	responseStr_EOF db "EOF", 13, 10, 0
	
	; Device strings (null-terminated)
	serialPortName db "COM1", 0

	; Error messages
	serialPortError db 13, 10, "Error: Failed to open serial port. Exiting.", 13, 10, 13, 10, "$"
	
	; File search strings
	fileSearch_AllFiles db "*.*", 0
	
	; File variables
	fileHandle dw 0
	fileErrorCode dw 0
	
	fileBytesRead dw 0
	fileBufferLength dw 1024
	fileBuffer db 1024 dup(?)
	
	dta db 21 dup(0)
	dtaFileAttribute db 0
	dtaMisc db 8 dup(0)
	dtaFilename db 13 dup(0)
	dtaBuffer db 87 dup(0)

	; Input buffers
	inputBufferInfo db 255    ; Max length
	inputBufferLength db 0    ; Actual length read by DOS
	inputBuffer db 255 dup(?) ; Actual characters read by dos
	
	inputBuffer2Info db 255    ; Max length
	inputBuffer2Length db 0    ; Actual length read by DOS
	inputBuffer2 db 255 dup(?) ; Actual characters read by dos
	
	localFileBufferInfo db 255    ; Max length
	localFileBufferLength db 0    ; Actual length read by DOS
	localFileBuffer db 255 dup(?) ; Actual characters read by dos

	lainFileBufferInfo db 255    ; Max length
	lainFileBufferLength db 0    ; Actual length read by DOS
	lainFileBuffer db 255 dup(?) ; Actual characters read by dos
	
	; Serial port variables
	serialPortHandle dw 0
	
	serialBufferMaxLength dw 1024
	serialBufferTab db 9
	serialBuffer db 2 dup(?)
	serialBufferCont db 1024 dup(?), 10, 0, "$"
	
	; HP-150 I/O control subfunc data
	hp150SerialBinaryModeSubfunc dw 0802h
	
	hp150SerialTransparentModeSubfunc dw 0803h
	
	hp150SerialSendBufferSubfunc dw 0807h
	hp150SerialSendBufferOffset dw OFFSET serialBuffer
	hp150SerialSendBufferSegment dw SEG serialBuffer
	hp150SerialSendBufferLength dw 0
	
	; String stack
	strStackMaxOffset dw 511
	strStackIndex dw 0
	strStack db 512 dup(?), 13, 10, "$"
	
	; Misc. variables
	tempVar dw 0
	tempVar2 dw 0
	tempVar3 dw 0
	
	; Scratch buffer
	scratchBuffer db 255 dup(?)
	scratchBuffer2 db 255 dup(?)
	
	debugStrA db "A", 13, 10, "$"
	debugStrB db "B", 13, 10, "$"
	debugStrC db "C", 13, 10, "$"
	debugStrD db "D", 13, 10, "$"
	debugStrE db "E", 13, 10, "$"
	debugStrF db "F", 13, 10, "$"
	debugStrG db "G", 13, 10, "$"
DATA ends

CODE segment
	 assume cs:CODE, ds:DATA

; DOS includes
INCLUDE dos\string.asm
INCLUDE dos\file.asm
INCLUDE dos\misc.asm

; Platform-specific includes
ifdef isHP150
	INCLUDE hp150\serial.asm
else
	ifndef isEmu
		INCLUDE ibm\serial.asm
	else
		INCLUDE emu\serial.asm
	endif
endif

; Lain basic includes
INCLUDE lain\serial.asm
INCLUDE lain\memory.asm
INCLUDE lain\string.asm
INCLUDE lain\lainutil.asm
INCLUDE lain\strstack.asm
INCLUDE lain\menu.asm

; Lain function includes
INCLUDE lain\function\upload.asm
INCLUDE lain\function\download.asm
INCLUDE lain\function\ul_dir.asm
INCLUDE lain\function\dl_dir.asm
INCLUDE lain\function\diskdir.asm
INCLUDE lain\function\list.asm

; Main program
START:
	mov dx, SEG DATA
	mov ds, dx

	; Open and initialize serial port
	call setupSerialPort
	
	; Set the DTA so we can find it later
	callSetDTA dta
	
	; Display the menu
	call menuProc

	call exitProc
CODE ends

STACK segment stack
	 assume ss:STACK
	 dw 64 dup(?)
STACK ends

end START

; DOS File I/O library
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Calls openFile to open a read-only file with the given filename parameter
; After the call: p_outErrorCode will contain the error code (0 if no error)
;                 p_outFileHandle will contain the file handle (if no error occurred)
callOpenFile MACRO p_filename, p_outFileHandle, p_outErrorCode
	mov dx, SEG p_filename
	mov ds, dx
	mov dx, OFFSET p_filename
	call openFile
	mov p_outFileHandle, ax
	mov p_outErrorCode, bx
ENDM

; Calls createFile with the given filename parameter
; After the call: p_outErrorCode will contain the error code (0 if no error)
;                 p_outFileHandle will contain the file handle (if no error occurred)
callCreateFile MACRO p_filename, p_outFileHandle, p_outErrorCode
	mov dx, SEG p_filename
	mov ds, dx
	mov dx, OFFSET p_filename
	call createFile
	mov p_outFileHandle, ax
	mov p_outErrorCode, bx
ENDM

; Reads data from the file in p_fileHandle into p_fileBuffer
; The rest of the buffer should be sized to accept up to that many bytes
; After the call, p_errorCode will contain the error code (0 for no error)
; If there is no error code, p_bytesWritten will contain the number of bytes read
callReadFile MACRO p_fileHandle, p_bytesToRead, p_fileBuffer, p_errorCode, p_bytesRead
	mov dx, SEG p_fileBuffer
	mov ds, dx
	mov dx, OFFSET p_fileBuffer
	mov bx, p_fileHandle
	mov cx, p_bytesToRead
	call readFile
	mov p_errorCode, bx
	mov p_bytesRead, ax
ENDM

; Writes data in p_fileBuffer to the file in p_fileHandle
; After the call, p_errorCode will contain the error code (0 for no error)
; If there is no error code, p_bytesWritten will contain the number of bytes written
callWriteFile MACRO p_fileHandle, p_bytesToWrite, p_fileBuffer, p_errorCode, p_bytesWritten
	mov dx, SEG p_fileBuffer
	mov ds, dx
	mov dx, OFFSET p_fileBuffer
	mov bx, p_fileHandle
	mov cx, p_bytesToWrite
	call writeFile
	mov p_errorCode, bx
	mov p_bytesWritten, ax
ENDM

; Closes the file whose handle is stored in memory at the given variable location
callCloseFile MACRO p_fileHandle
	mov bx, SEG p_fileHandle
	mov ds, bx
	mov bx, p_fileHandle
	call closeFile
ENDM

; Sets the DTA (Disk Transfer Area) address to the given buffer
callSetDTA MACRO newDTA
	mov dx, seg newDTA
	mov ds, dx
	mov dx, offset newDTA
	call setDTA
ENDM

; Find the first file matching the null-terminated search string in searchBuffer
; If the call succeeds, ax will be zero and the DTA will contain file info
; If the call fails, the error code will be in ax
callFindFirstFile MACRO searchBuffer
	mov dx, seg searchBuffer
	mov ds, dx
	mov dx, offset searchBuffer
	call findFirstFile
ENDM

; Find the next file matching the null-terminated search string in searchBuffer
; If the call succeeds, ax will be zero and the DTA will contain file info
; If the call fails, the error code will be in ax
callFindNextFile MACRO searchBuffer
	mov dx, seg searchBuffer
	mov ds, dx
	mov dx, offset searchBuffer
	call findNextFile
ENDM


; Opens the file specified by the null-terminated string in ds:dx
; If successful, bx will be zero and the resulting file handle will be in ax
; If an error occurs, ax will be zero and bx will contain the error code
openFile PROC
	mov ah, 3dh
	mov al, 0
	int 21h
	jae openFileContinue
	mov bx, ax
	mov ax, 0
	ret
openFileContinue:
	mov bx, 0
	ret
openFile ENDP

; Creates/truncates the file specified by the null-terminated string in ds:dx
; If successful, bx will be zero and the resulting file handle will be in ax
; If an error occurs, ax will be zero and bx will contain the error code
createFile PROC
	mov ah, 3ch
	mov cx, 0
	int 21h
	
	jae createFile_CONTINUE
	mov bx, ax
	mov ax, 0
	ret
	
createFile_CONTINUE:
	mov bx, 0
	ret
createFile ENDP

; Reads up to cx bytes of the file handle in bx into the buffer at ds:dx
; If bx is zero, the number of bytes actually read will be in ax
; If bx is non-zero, bx contains an error code
readFile PROC
	mov ah, 3fh
	int 21h
	jae readFileContinue
	mov bx, ax
	mov ax, 0
	ret
readFileContinue:
	mov bx, 0
	ret
readFile ENDP

; Writes cx bytes to the file handle in bx from the buffer stored in ds:dx
; If bx is zero, the number of bytes actually written will be in ax
; If bx is non-zero, bx contains an error code
writeFile PROC
	mov ah, 40h
	int 21h
	jae writeFileContinue
	mov bx, ax
	mov ax, 0
	ret
writeFileContinue:
	mov bx, 0
	ret
writeFile ENDP

; Closes the file handle in bx
closeFile PROC
	mov ah, 3eh
	int 21h
	ret
closeFile ENDP

; Sets the DTA (Disk Transfer Area) address to ds:dx
setDTA PROC
	mov ah, 1ah
	int 21h
	ret
setDTA ENDP

; Find the first file matching the search string in ds:dx (details stored in the DTA)
; If the call succeeds, ax will be zero
; If the call fails, the error code will be in ax
findFirstFile PROC
	; Get the first file
	mov ah, 4eh
	mov cx, 37h ; Find any file/directory
	int 21h
	jae findFirstFile_Continue
	ret
	
findFirstFile_Continue:
	mov ax, 0
	ret
findFirstFile ENDP

; Find the next file matching the search string in ds:dx (details stored in the DTA)
; If the call succeeds, ax will be zero
; If the call fails, the error code will be in ax
findNextFile PROC
	; Get the next file
	mov ah, 4fh
	int 21h
	jae findNextFile_Continue
	ret
	
findNextFile_Continue:
	mov ax, 0
	ret
findNextFile ENDP

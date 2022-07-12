; LainFTP Serial Port Library
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Calls the correct readSerialPort* proc
; Reads up to cx bytes from the serial port whose handle is in bx into the buffer in ds:dx
callReadSerialPort MACRO
ifndef isEmu
ifdef isHP150
	call readSerialPortHP150
else
	call readSerialPortStandardDOS
endif
endif
ENDM

; Calls the appropriate writeSerialPortBytes* proc
; Writes cx bytes from serialBuffer to the serial port whose handle is in serialPortHandle
callWriteSerialPortBytes MACRO
ifndef isEmu
ifdef isHP150
	call writeSerialPortBytesHP150
else
	mov bx, serialPortHandle
	mov dx, SEG serialBuffer
	mov ds, dx
	mov dx, OFFSET serialBuffer
	call writeSerialPortBytesStandardDOS
endif
endif
ENDM

; Reads the serial port into serialBuffer until either:
; - LF is encountered
; - serialBufferMaxLength bytes have been read
; After read, the number of bytes read will be in ax
readSerialPortUntilLF PROC
	; Buffer offset
	mov dx, SEG serialBufferMaxLength
	mov ds, dx
	mov dx, OFFSET serialBufferMaxLength
	mov di, dx
	
	; Max bytes
	mov cx, [di]
	
	; Adjust dx to buffer offset
	; Skips 2 bytes of length
	; Skips 1 byte which is always tab (for some UI tricks later on)
	inc dx
	inc dx
	inc dx
	
	; Read until end of buffer or LF
LF_READ_LOOP:
	mov bx, serialPortHandle
	callReadSerialPort
	
	; Check for LF
	mov bx, ax
CHECK_LF_LOOP:
	; If we've checked all of the read bytes, continue reading
	cmp bx, 0
	je LF_READ_LOOP
	
	; Decrement remaining bytes and jump to RET_LF if the buffer is full
	dec cx
	cmp cx, 0
	je RET_LF
	
	; Load the next character
	dec bx
	mov di, dx
	mov al, [di]
	
	; Update the buffer offset
	inc dx
	
	; If the character isn't LF, continue checking
	cmp al, 10
	jne CHECK_LF_LOOP

RET_LF:
	; Compute the number of bytes read
	mov di, OFFSET serialBufferMaxLength
	mov ax, [di]
	sub ax, cx

	ret
readSerialPortUntilLF ENDP

; Reads the serial port into serialBuffer until cx bytes have been read
readSerialPortBytes PROC
	; Buffer offset
	mov dx, SEG serialBuffer
	mov ds, dx
	mov dx, OFFSET serialBuffer
	
	; Serial port handle
	mov bx, serialPortHandle

B_READ_LOOP:
	callReadSerialPort
	
	; If we've read all bytes, jump to B_READ_RET
	cmp cx, ax
	jbe B_READ_RET
	
	; Adjust remaining bytes and current buffer offset
	sub cx, ax
	add dx, ax
	
	; Continue reading
	jmp B_READ_LOOP
	
B_READ_RET:
	ret
readSerialPortBytes ENDP

; Opens and initializes the serial port (the file handle will be in serialPortHandle)
setupSerialPort PROC
	; Open and initialize the serial port
	callOpenFile serialPortName, serialPortHandle, fileErrorCode
	cmp fileErrorCode, 0
	je CONTINUE_AFTER_SERIAL
	callPrintString serialPortError
	call exitToDOS
CONTINUE_AFTER_SERIAL:
	mov bx, serialPortHandle
ifdef isHP150
	call initializeSerialPortHP150 ; DOSBOX can't handle this; It only works on real hardware (comment if emulating)
endif
	ret
setupSerialPort ENDP

; Terminates the serial buffer with a "$" and prints it to the screen
; NOTE: The length of the buffer must be in ax before calling this macro
terminateAndPrintSerialBuffer MACRO bufferStart, extraChars
	mov dx, SEG bufferStart
	mov ds, dx
	mov bx, OFFSET bufferStart
	add bx, ax
	add bx, extraChars
	mov cl, "$"
	mov [bx], cl
	callPrintString bufferStart
ENDM

; LainFTP Serial Port Library
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

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
	call readSerialPortImpl
	
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
	call readSerialPortImpl
	
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

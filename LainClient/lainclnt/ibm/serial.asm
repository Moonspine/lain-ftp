; IBM Compatible Serial Port Library
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; https://www.plantation-productions.com/Webster/www.artofasm.com/DOS/ch13/CH13-3.html#HEADING3-1

; Reads up to cx bytes from the serial port into ds:dx
; After the call, ax contains the number of bytes read
readSerialPortImpl PROC
	push bx
	push dx
	push di

	mov di, dx
	
	mov dx, 0 ; Select COM1
	mov bx, 0 ; # bytes read
	
readSerialPortImpl_Loop:
	; If no bytes are available to read, exit
	mov ah, 3 ; Command 3 = Serial port status
	int 14h
	test ax, 0100h ; Check if data is available
	jz readSerialPortImpl_Done
	
	; Read a byte
	mov ah, 2 ; Command 2 = Read serial port
	int 14h
	
	; Store the byte in the buffer
	mov [ds:di], al
	inc di
	inc bx
	
	; Try to read another byte?
	cmp bx, cx
	jne readSerialPortImpl_Loop

readSerialPortImpl_Done:
	; Bytes read
	mov ax, bx

	; Undo important register changes
	pop di
	pop dx
	pop bx

	ret
readSerialPortImpl ENDP

; Sends cx bytes from serialBuffer to the serial port
writeSerialPortImpl PROC
	push ds
	push di
	push dx
	push cx
	push ax
	
	mov dx, 0 ; Select COM1
	
	mov di, SEG serialBuffer
	mov ds, di
	mov di, OFFSET serialBuffer
	
writeSerialPortImpl_Loop:
	; Done sending?
	cmp cx, 0
	je writeSerialPortImpl_Done
	
	; Send the next byte
	mov ah, 1 ; Command 1 = Write serial port
	mov al, [ds:di]
	int 14h
	
	; Move to the next character
	dec cx
	inc di
	
	jmp writeSerialPortImpl_Loop
	
writeSerialPortImpl_Done:
	; Undo important register changes
	pop ax
	pop cx
	pop dx
	pop di
	pop ds
	
	ret
writeSerialPortImpl ENDP

; Initializes the serial port for IBM compatible machines
setupSerialPort PROC
	mov ah, 0         ; Command 0 = Initialize serial port
	mov al, 11100011b ; 9600 baud, no parity, 1 stop bit, 8 data bits
	mov dx, 0         ; 0 = COM1
	int 14h           ; Serial port handler
	ret
setupSerialPort ENDP

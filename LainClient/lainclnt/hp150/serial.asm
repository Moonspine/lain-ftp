; HP-150 Serial Port Library
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Initializes the serial port whose file handle is in bx
; This only works on the HP-150
; It does the following actions:
; - Set the port to binary mode (always use 8 bits)
; - Set the port to transparent mode (ignores control characters)
initializeSerialPortHP150 PROC
	; The following code is specific to the HP-150
	
	; Set binary mode
	mov dx, SEG hp150SerialBinaryModeSubfunc
	mov ds, dx
	mov dx, OFFSET hp150SerialBinaryModeSubfunc
	mov cx, 2
	mov ax, 4403h
	int 21h
	
	; Set transparent mode
	mov dx, OFFSET hp150SerialTransparentModeSubfunc
	mov ax, 4403h
	int 21h
	
	ret
initializeSerialPortHP150 ENDP

; Reads up to cx bytes from the serial port whose handle is in bx into ds:dx
; After the call, ax contains the number of bytes read
readSerialPortHP150 PROC
	mov ax, 4402h
	int 21h
	ret
readSerialPortHP150 ENDP

; Sends cx bytes from serialBuffer to the serial port
writeSerialPortBytesHP150 PROC
	; Subfunc address
	mov dx, SEG hp150SerialSendBufferSubfunc
	mov ds, dx
	mov dx, OFFSET hp150SerialSendBufferSubfunc
	
	; # bytes to send
	mov di, OFFSET hp150SerialSendBufferLength
	mov [di], cx
	
	; Serial port handle
	mov bx, serialPortHandle
	
	; Subfunc data length
	mov cx, 8
	
	; Execute send
	mov ax, 4403h
	int 21h

	ret
writeSerialPortBytesHP150 ENDP

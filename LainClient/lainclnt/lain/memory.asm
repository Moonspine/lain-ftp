; LainFTP Memory Utility Library
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Copies cx bytes from ds:di to es:bx
; After the call, di and bx will point one byte further than the last copied byte
memcopy PROC
MEM_COPY_LOOP:
	cmp cx, 0
	je MEM_COPY_RET
	
	; Copy byte
	mov al, [ds:di]
	mov [es:bx], al
	
	; Update the pointers and loop
	dec cx
	inc di
	inc bx
	jmp MEM_COPY_LOOP

MEM_COPY_RET:
	ret
memcopy ENDP

; Copies bytes from ds:di to es:bx until 0 is read from ds:di
; Note: Copies the null terminator
; After the call, the number of non-null bytes copied will be in cx
; After the call, es:bx will point to the next character in destinationBuffer (the null terminator), so calls can be chained
memcopyUntilNull PROC
	mov cx, 0
memcopyUntilNull_LOOP:
	mov al, [ds:di]
	mov [es:bx], al
	cmp al, 0
	je memcopyUntilNull_RETURN
	
	; Next character
	inc cx
	
	; Update the pointers and loop
	inc di
	inc bx
	jmp memcopyUntilNull_LOOP

memcopyUntilNull_RETURN:
	ret
memcopyUntilNull ENDP

; Copies null-terminated data from sourceBuffer into destinationBuffer
; After the call, es:bx will point to the next character in destinationBuffer, so calls can be chained with copyDataNullTerminatedContinue
copyDataNullTerminated MACRO sourceBuffer, destinationBuffer
	mov di, SEG sourceBuffer
	mov ds, di
	mov di, OFFSET sourceBuffer
	
	mov bx, SEG destinationBuffer
	mov es, bx
	mov bx, OFFSET destinationBuffer
	
	call memcopyUntilNull
ENDM

; Copies null-terminated data from sourceBuffer to es:bx
; After the call, es:bx will point to the next character in destinationBuffer, so calls can be chained
; Additionally, the number of bytes copied will be in cx
copyDataNullTerminatedContinue MACRO sourceBuffer
	mov di, SEG sourceBuffer
	mov ds, di
	mov di, OFFSET sourceBuffer
	
	call memcopyUntilNull
ENDM

; Copies null-terminated data from dataBuffer into the serial buffer and sends it (without the terminating null)
copyAndSendDataNullTerminated MACRO dataBuffer
	copyDataNullTerminated dataBuffer, serialBuffer
	callWriteSerialPortBytes
ENDM

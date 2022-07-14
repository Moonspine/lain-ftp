; LainFTP String Stack Library
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Pushes the null-terimated string in buffer to the string stack
; If there is not enough room, the string will be truncated with a premature null terminator
callPushStringToStack MACRO buffer
	mov di, SEG buffer
	mov ds, di
	mov di, OFFSET buffer
	call pushStringToStack
ENDM

; Pops a null-terminated string from the stack into the buffer in ds:di
; If the stack is empty, the buffer will contain an empty string
; Clobbers the contents of scratchBuffer
callPopStringFromStack MACRO buffer
	mov di, SEG buffer
	mov ds, di
	mov di, OFFSET buffer
	call popStringFromStack
ENDM

; Pushes the null-terimated string in ds:di to the string stack
; If there is not enough room, the string will be truncated with a premature null terminator
pushStringToStack PROC
	; Place string stack address in es:bx
	mov bx, SEG strStack
	mov es, bx
	mov bx, OFFSET strStack
	
	; Load offset of next string
	mov ax, strStackIndex
	add bx, ax
	
	; Load max offset index
	mov cx, strStackMaxOffset
	
	; Push until null or until end of stack
pushStringToStack_COPYNEXT:
	; If at end of stack, terminate and return
	cmp ax, cx
	je pushStringToStack_TERMINATE
	
	; Copy the next character
	mov dl, [ds:di]
	mov [es:bx], dl
	
	; Move to the next character index
	inc ax
	inc bx
	inc di
	
	; If null, return
	cmp dl, 0
	je pushStringToStack_RETURN
	
	; If not, continue
	jmp pushStringToStack_COPYNEXT
	
pushStringToStack_TERMINATE:
	; Terminate at end of stack
	mov dl, 0
	mov [es:bx], dl

pushStringToStack_RETURN:
	; Update the stack pointer
	mov strStackIndex, ax

	ret
pushStringToStack ENDP


; Pops a null-terminated string from the stack into the buffer in ds:di
; If the stack is empty, the buffer will contain an empty string
; Clobbers the contents of scratchBuffer
popStringFromStack PROC
	; First, check if the stack is empty
	mov ax, strStackIndex
	cmp ax, 0
	je popStringFromStack_STACKEMPTY
	
	; Next, decrement ax and check it again (i.e. guard against an empty string in the bottom of the stack)
	; (ax will point to the null terminator at this point)
	dec ax
	cmp ax, 0
	je popStringFromStack_STACKEMPTY
	
	jmp popStringFromStack_NOTEMPTY
	
popStringFromStack_STACKEMPTY:
	; Terminate the buffer and return
	mov cl, 0
	mov [ds:di], cl
	jmp popStringFromStack_RETURN
	
popStringFromStack_NOTEMPTY:
	; Push ds and di (we need to use those registers for a minute)
	push ds
	push di
	
	; Set the scratch buffer up
	mov bx, SEG scratchBuffer
	mov es, bx
	mov bx, OFFSET scratchBuffer
	
	; Decrement ax to point to the last character in the string (could be the null terminator for the previous string, if empty)
	dec ax
	
	; Set the stack pointer
	mov di, SEG strStack
	mov ds, di
	mov di, OFFSET strStack
	add di, ax
	
popStringFromStack_COPYNEXT:
	; Copy the next character into the scratch buffer
	mov cl, [ds:di]
	mov [es:bx], cl
	
	; Check for null terminator
	cmp cl, 0
	je popStringFromStack_REVERSE
	
	; Move to the next character in the scratch buffer
	inc bx
	
	; Check for the bottom of the stack
	cmp ax, 0
	jne popStringFromStack_COPYCONTINUE
	
	; If we're at the bottom of the stack, terminate the scratch buffer with an extra null
	mov cl, 0
	mov [es:bx], cl
	
	; Decrement ax before we begin the reversal process, as it will be incremented before being saved to RAM and we don't want to underflow the stack
	dec ax
	jmp popStringFromStack_REVERSE
	
popStringFromStack_COPYCONTINUE:
	; Move to the next character in the stack
	dec di
	dec ax

	; Copy the next character
	jmp popStringFromStack_COPYNEXT

popStringFromStack_REVERSE:
	; Before we do anything, let's update the stack pointer (it currently points to the null terminator of the next string, so we need to increment it first)
	inc ax
	mov strStackIndex, ax

	; Pop the target buffer address
	pop di
	pop ds
	
	; es:bx points to the null terminator, so we need to decrement bx before we start
	; However, if bx is pointing to the start of the scratch buffer, it's an empty string and we're done
	cmp bx, OFFSET scratchBuffer
	jne popStringFromStack_REVERSESTART
	
	; Terminate the buffer (empty string)
	jmp popStringFromStack_TERMINATE
	
popStringFromStack_REVERSESTART:
	; Copy the next character
	dec bx
	mov cl, [es:bx]
	mov [ds:di], cl
	
	; Move the buffer pointer
	inc di
	
	; Terminate?
	cmp bx, OFFSET scratchBuffer
	jne popStringFromStack_REVERSESTART
	
popStringFromStack_TERMINATE:
	; Terminate the buffer
	mov cl, 0
	mov [ds:di], cl

popStringFromStack_RETURN:
	ret
popStringFromStack ENDP

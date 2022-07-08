; DOS Serial Port Library
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Reads up to cx bytes from the serial port whose handle is in bx into ds:dx
; After the call, ax contains the number of bytes read
readSerialPortStandardDOS PROC
	call readFile
	ret
readSerialPortStandardDOS ENDP

; Sends cx bytes from ds:dx to the serial port whose handle is in bx
writeSerialPortBytesStandardDOS PROC
	call writeFile
	ret
writeSerialPortBytesStandardDOS ENDP

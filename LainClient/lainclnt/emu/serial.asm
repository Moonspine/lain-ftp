; Dummy Serial Port Library
; Copyright (c) 2022 Moonspine
; Available for use under the MIT license

; Dummy read function for emulators
readSerialPortImpl PROC
	ret
readSerialPortImpl ENDP

; Dummy write function for emulators
writeSerialPortImpl PROC
	ret
writeSerialPortImpl ENDP

; Dummy port initializer for emulators
setupSerialPort PROC
	ret
setupSerialPort ENDP

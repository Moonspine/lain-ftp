# lain-ftp
A simple RS232-based FTP program for transferring files to/from retro computers.

## What is it?
LainFTP is a simple client and server application pair that communicates via a standard RS232 serial port.  
The main goal with the project was to create a method to transfer files to and from retro computers (in my case, the HP-150) without needing any special hardware.  
All you need is a serial port (which... admittedly, you may need to buy for a modern PC) and a way to boot the retro computer into some kind of OS that supports Basic.  

## Why?
As legacy storage media continues to decline, it's becoming more and more necessary to find alternative methods for transferring files to and from retro computers.  
This project... doesn't exactly solve that. It still requires a computer which can boot into at least some form of basic.  
But! Once you're there, you can use this to transfer files using any modern PC and a simple USB-to-Serial adaptor that can be bought cheaply from sites like Amazon.  

## How do I use it?
First, you'll need to copy [LAINCIBM.EXE](Release/LAINCIBM.EXE), [LAINC150.EXE](Release/LAINC150.EXE), or [lainclnt.bas](LainClient/lainclnt.bas) onto the retro computer of choice. The method is entirely up to you, but if you have no existing method of doing this, it's going to get complicated.  
Let me start by saying that if you can't at least boot and run some form of Basic, this will not work. This project is meant to facilitate file transfer on machines that are bootable already. You'll need to figure that part out for yourself.  
Once you manage to get the Lain client program (either basic or exe) onto the host computer, you need to connect the serial cable.  
The HP version of the executable version of the program will use whatever your last serial port settings were, so you'll need to make that will work with the settings in the server.  
After you've got the retro computer set up, start the [LainFTP](Releast/LainFTP.exe) server on your modern PC, handing it the COM port and baud rate as command line parameters (it has a help feature if you run it without parameters).  
Note: You may have to enable DTR and RTS (the third parameter of LainFTP) in order to connect to an IBM PC!  
Note: LainFTP uses the following serial settings at all times (it's part of how the file transfer works), so you need to make sure the retro computer's serial port is configured this way:  
- No parity
- 8 data bits
- 1 stop bit
- No handshaking
Once the server is running, just run the Lain client on the retro computer. It should connect to the server and display a menu asking what you'd like to do.  
The entire client is menu-driven, so it's pretty self-explanatory.  

If you manage to successfully use this (like I said, I've only tested it with a very non-IBM PC, the HP-150), let me know anything odd you had to do and I'll update these instructions!  
If you don't manage to successfuly use this, let me know the difficulties you ran into and I'll try to fix it (and update these instructions).  

## Help! I can boot into Basic, but I have no way of transferring the client over!
You're in luck! In a worst case scenario, you can manually type the contents of [lainclnt-stub-ASCII.bas](LainClient/lainclnt-stub-ASCII.bas) into your favorite basic program (if it's not GWBasic... well, I hope it's compatible.)  
After that, you can run the program and download the full basic program ([lainclnt.bas](LainClient/lainclnt.bas)) or the executable version ([LAINCIBM.EXE](Release/LAINCIBM.EXE)).  

## Will it work for my computer?
The executable version? I don't know! I wrote this to work for the HP-150 ([LAINC150.EXE](Release/LAINC150.EXE)) and IBM PCs ([LAINCIBM.EXE](Release/LAINCIBM.EXE)).  
No matter which computer you're using, though, if you can run a GWBasic-compatible basic interpreter, you should be fine using [lainclnt.bas](LainClient/lainclnt.bas)  

## But how does it work?
The entire protocol is described in [Lain Protocol.txt](Lain Protocol.txt).  
Although... some of the error handling isn't exactly implemented to the spec (in particular, missed packets would tend to result in hung file transfers dur to the client code not properly timing out.)  
In practice, however, this has never been a problem for my usage with my HP-150. I don't expect one would have many communication errors without faulty hardware.  

## Can you explain the source code tree?
Sure!  
- [LainFTP](LainFTP) = The C# source for the LainFTP server program. This program runs the actual file server on the modern PC.
- [LainClient/lainclnt.bas](LainClient/lainclnt.bas) = The GWBasic program (binary format) for the Lain client. This one can be run on the retro computer in GWBasic to (slowly) transfer files to/from the LainFTP server.
- [LainClient/lainclnt-ASCII.bas](LainClient/lainclnt-ASCII.bas) = The GWBasic program (ASCII format) for the Lain client. Identical to lainclnt.bas, just... in ASCII. Useful if you need to translate to your favorite Basic dialect.
- [LainClient/lainclnt-stub-ASCII.bas](LainClient/lainclnt-stub-ASCII.bas) = A stubby version of the GWBasic client program designed specifically to download one file (namely a more full version of the client.)
- [LainClient/lainclnt](LainClient/lainclnt) = The 8086 assembly code for the Lain client executable. To build, just run MASM 4.0 (or a compatible version) on [lainc150.asm](LainClient/lainclnt/lainc150.asm) (HP-150), [laincibm.asm](LainClient/lainclnt/laincibm.asm) (IBM PC), or [laincemu.asm](LainClient/lainclnt/laincemu.asm) (emulators without serial support, like DOSBox). 
- [Release/LainFTP.exe](Release/LainFTP.exe) = Prebuilt Windows version of the LainFTP program. If you're running Linux, you'll need to build from [the source](LainFTP).
- [Release/LAINC150.EXE](Release/LAINC150.EXE) = The HP-150 version of the client executable for fast file transfer. You probably don't want this one, unless you just happen to have an HP-150 computer. It handles its serial ports a bit different from an IBM PC.
- [Release/LAINCIBM.EXE](Release/LAINCIBM.EXE) = The IBM PC version of the client executable for fast file transfer.

## What's with the name?
So when I started writing this, I needed a folder to put the code in. I was experimenting with serial file transfer, so I called it "Serial Experiments." Naturally, the connection to "Serial Experiments Lain" came to mind, and I had no choice but to call it LainFTP.  

## License
This project is licensed under the MIT license.

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
First, you'll need to copy [LAINCDOS.EXE](Release/LAINCDOS.EXE) or [lainclnt.bas](LainClient/lainclnt.bas) onto the retro computer of choice. The method is entirely up to you, but if you have no existing method of doing this, it's going to get complicated.  
Let me start by saying that if you can't at least boot and run some form of Basic, this will not work. This project is meant to facilitate file transfer on machines that are bootable already. You'll need to figure that part out for yourself.  
Once you manage to get the Lain client program (either basic or exe) onto the host computer, you need to connect the serial cable.  
The executable version of the program will use whatever your last serial port settings were, so you'll need to do whatever DOS-ish things you need to do to make that work with the settings in the server.  
After you've got the retro computer set up, start the [LainFTP](Releast/LainFTP.exe) server on your modern PC, handing it the COM port and baud rate as command line parameters (it has a help feature if you run it without parameters).  
Note: LainFTP uses the following serial settings at all times (it's part of how the file transfer works), so you need to make sure the retro computer's serial port is configured this way:  
- No parity
- 8 data bits
- 1 stop bit
- No handshaking

If you manage to successfully use this (like I said, I've only tested it with a very non-IBM PC, the HP-150), let me know anything odd you had to do and I'll update these instructions!  
If you don't manage to successfuly use this, let me know the difficulties you ran into and I'll try to fix it (and update these instructions).  

## Help! I can boot into Basic, but I have no way of transferring the client over!
You're in luck! In a worst case scenario, you can manually type the contents of [lainclnt-stub-ASCII.bas](LainClient/lainclnt-stub-ASCII.bas) into your favorite basic program (if it's not GWBasic... well, I hope it's compatible.)  
After that, you can run the program and download the full basic program ([lainclnt.bas](LainClient/lainclnt.bas)) or the executable version ([LAINCDOS.EXE](Release/LAINCDOS.EXE)).  

## Will it work for my computer?
The executable version? I don't know! I wrote this to work for the HP-150 ([LAINC150.EXE](Release/LAINC150.EXE)). I tried to create a fallback for standard DOS serial communications ([LAINCDOS.EXE](Release/LAINCDOS.EXE)), but I have not yet been able to test it.  
Please let me know if it does/doesn't work for you and I can try to fix it!  
No matter which computer you're using, though, if you can run a GWBasic-compatible basic interpreter, you should be fine using [lainclnt.bas](LainClient/lainclnt.bas)  

## What's with the name?
So when I started writing this, I needed a folder to put the code in. I was experimenting with serial file transfer, so I called it "Serial Experiments." Naturally, the connection to "Serial Experiments Lain" came to mind, and I had no choice but to call it LainFTP.  

## License
This project is licensed under the MIT license.

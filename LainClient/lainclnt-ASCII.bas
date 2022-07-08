10 CLS
20 OPEN "COM1:19200,N,8,1" AS #1
30 GOTO 1000
1000 REM =============
1010 REM | Main menu |
1020 REM =============
1030 PRINT "LainFTP Client Version 1.00"
1040 PRINT# 1, "DISK" + CHR$(10)
1050 INPUT# 1, DISKNAME$
1060 PRINT ""
1070 PRINT "Current disk: " + DISKNAME$
1080 PRINT# 1, "DIR" + CHR$(10)
1090 INPUT# 1, DIRNAME$
1100 PRINT "Current directory: " + DIRNAME$
1110 PRINT ""
1120 PRINT "Enter a choice from the following menu:"
1210 PRINT "1. Change disk"
1220 PRINT "2. Change directory"
1230 PRINT "3. List files"
1240 PRINT "4. Upload file to server"
1250 PRINT "5. Download file from server"
1260 PRINT "6. Quit"
1300 PRINT ""
1310 INPUT CHOICEINDEX
1320 IF CHOICEINDEX = 1 THEN GOSUB 2000
1330 IF CHOICEINDEX = 2 THEN GOSUB 3000
1340 IF CHOICEINDEX = 3 THEN GOSUB 4000
1350 IF CHOICEINDEX = 4 THEN GOSUB 5000
1360 IF CHOICEINDEX = 5 THEN GOSUB 6000
1370 IF CHOICEINDEX = 6 THEN END
1380 IF CHOICEINDEX < 1 OR CHOICEINDEX > 6 THEN PRINT "Invalid choice. Must be between 1 and 6, inclusive." : GOTO 1310
1390 GOTO 1000
2000 REM ================
2010 REM | DISK command |
2020 REM ================
2030 PRINT "Enter name of disk to switch to (empty line to cancel)"
2040 INPUT NEWDISKNAME$
2050 IF LEN(NEWDISKNAME$) = 0 THEN RETURN
2060 PRINT# 1, "DISK " + NEWDISKNAME$ + CHR$(10)
2070 INPUT# 1, RESPONSE$
2080 IF RESPONSE$ = "OK" THEN RETURN
2090 PRINT RESPONSE$
2100 PRINT "Hit enter to return to the menu"
2110 INPUT TEMP$
2120 RETURN
3000 REM ===============
3010 REM | DIR command |
3020 REM ===============
3030 PRINT "Enter name of directory to switch to (empty line to cancel)"
3040 INPUT NEWDIRNAME$
3050 IF LEN(NEWDIRNAME$) = 0 THEN RETURN
3060 PRINT# 1, "DIR " + NEWDIRNAME$ + CHR$(10)
3070 INPUT# 1, RESPONSE$
3080 IF RESPONSE$ = "OK" THEN RETURN
3090 PRINT RESPONSE$
3100 PRINT "Hit enter to return to the menu"
3110 INPUT TEMP$
3120 RETURN
4000 REM ================
4010 REM | LIST command |
4020 REM ================
4030 PRINT# 1, "LIST" + CHR$(10)
4040 LET FILECOUNT = 0
4050 INPUT# 1, FILENAME$
4060 IF FILENAME$ = "EOF" THEN GOTO 4200
4070 FILECOUNT = FILECOUNT + 1
4110 PRINT "    " + FILENAME$
4120 IF FILECOUNT MOD 20 = 0 THEN PRINT "Press enter to continue..." : INPUT TEMP$
4130 PRINT# 1, "OK" + CHR$(10)
4140 GOTO 4050
4200 PRINT ""
4210 PRINT STR$(FILECOUNT) + " files"
4220 PRINT ""
4230 PRINT "Press enter to continue..."
4240 INPUT TEMP$
4250 RETURN
5000 REM ==================
5010 REM | UPLOAD command |
5020 REM ==================
5030 PRINT "Enter filename to upload to server (empty line to cancel)"
5040 INPUT UPLOADFILENAME$
5050 IF LEN(UPLOADFILENAME$) = 0 THEN RETURN
5060 LET UPLOADNAME$ = UPLOADFILENAME$
5070 LET SLASHINDEX = INSTR(UPLOADNAME$,"\")
5080 IF SLASHINDEX > 0 THEN UPLOADNAME$ = MID$(UPLOADNAME$,SLASHINDEX + 1) : GOTO 5070
5090 PRINT "Enter filename to send as (empty line to send as " + UPLOADNAME$ + ")"
5100 INPUT NEWUPLOADNAME$
5110 IF LEN(NEWUPLOADNAME$) > 0 THEN LET UPLOADNAME$ = NEWUPLOADNAME$
5120 GOSUB 5200
5130 RETURN
5200 REM =================================================
5210 REM | Upload file in UPLOADFILENAME$ to UPLOADNAME$ |
5220 REM =================================================
5230 PRINT "Uploading " + UPLOADFILENAME$ + " as " UPLOADNAME$
5240 OPEN "R", #2, UPLOADFILENAME$, 1
5250 FIELD #2, 1 AS FILEDATA$
5260 LET FILELENGTH = LOF(2)
5270 LET PACKETSIZE = 128
5280 PRINT# 1, "UPLOADA " + UPLOADNAME$ + " " + STR$(FILELENGTH) + " " + STR$(PACKETSIZE) + " ASCII" + CHR$(10)
5290 INPUT# 1, FILESIZEECHO$
5300 IF VAL(FILESIZEECHO$) = FILELENGTH THEN GOTO 5400
5310 CLOSE #2
5320 PRINT "Error encountered"
5330 PRINT FILESIZEECHO$
5340 RETURN
5400 LET CURRENTINDEX = 0
5410 LET CURRENTPACKET = 1
5420 PACKETCOUNT = -INT(-FILELENGTH / PACKETSIZE)
5430 LET NEXTPACKETSIZE = FILELENGTH - CURRENTINDEX
5440 IF NEXTPACKETSIZE > PACKETSIZE THEN NEXTPACKETSIZE = PACKETSIZE
5450 PRINT "Sending packet " + STR$(CURRENTPACKET) + " / " + STR$(PACKETCOUNT) + " (" + STR$(NEXTPACKETSIZE) + " bytes)"
5460 FOR I = 1 TO NEXTPACKETSIZE
5470 GET #2
5480 DATABYTE = ASC(FILEDATA$)
5490 LET HIGHNYBBLE = (DATABYTE AND 240) / 16
5500 LET LOWNYBBLE = (DATABYTE AND 15)
5510 IF HIGHNYBBLE < 10 THEN HIGHCHAR$ = CHR$(ASC("0") + HIGHNYBBLE)
5520 IF HIGHNYBBLE >= 10 THEN HIGHCHAR$ = CHR$(ASC("A") + (HIGHNYBBLE - 10))
5530 IF LOWNYBBLE < 10 THEN LOWCHAR$ = CHR$(ASC("0") + LOWNYBBLE)
5540 IF LOWNYBBLE >= 10 THEN LOWCHAR$ = CHR$(ASC("A") + (LOWNYBBLE - 10))
5550 PRINT# 1, HIGHCHAR$ + LOWCHAR$
5560 NEXT I
5570 PRINT# 1, CHR$(10)
5580 CURRENTINDEX = CURRENTINDEX + NEXTPACKETSIZE
5590 CURRENTPACKET = CURRENTPACKET + 1
5600 INPUT# 1, RESPONSE$
5610 IF VAL(RESPONSE$) = NEXTPACKETSIZE AND CURRENTINDEX < FILELENGTH THEN GOTO 5430
5620 CLOSE #2
5630 IF VAL(RESPONSE$) <> NEXTPACKETSIZE THEN PRINT "Error" : PRINT RESPONSE$ : RETURN
5640 PRINT "File uploaded successfully"
5650 PRINT ""
5660 RETURN
6000 REM ====================
6010 REM | DOWNLOAD command |
6020 REM ====================
6030 PRINT "Enter filename to download from the server (empty line to cancel)"
6040 INPUT DOWNLOADFILENAME$
6050 IF LEN(DOWNLOADFILENAME$) = 0 THEN RETURN
6060 PRINT "Enter filename to save to (empty line to cancel)"
6070 INPUT TARGETFILENAME$
6080 IF LEN(TARGETFILENAME$) = 0 THEN RETURN
6090 GOSUB 6200
6100 RETURN
6200 REM =========================================================
6210 REM | Download file in DOWNLOADFILENAME$ to TARGETFILENAME$ |
6220 REM =========================================================
6230 PRINT "Downloading " + DOWNLOADFILENAME$ + " to " + TARGETFILENAME$
6240 LET PACKETSIZE = 32
6250 PRINT# 1, "DOWNLOADA " + DOWNLOADFILENAME$ + " " + STR$(PACKETSIZE) + " ASCII" + CHR$(10)
6260 INPUT# 1, EXPECTEDFILESIZESTRING$
6270 LET EXPECTEDFILESIZE = VAL(EXPECTEDFILESIZESTRING$)
6280 IF EXPECTEDFILESIZE < 1 THEN PRINT "Error encountered" : PRINT EXPECTEDFILESIZESTRING$ : RETURN
6290 REM Open and close the file to delete its contents safely
6300 OPEN "O", #2, TARGETFILENAME$
6310 CLOSE #2
6320 PRINT# 1, EXPECTEDFILESIZESTRING$ + CHR$(10)
6330 OPEN "R", #2, TARGETFILENAME$, 1
6340 FIELD #2, 1 AS FILEDATA$
6350 LET CURRENTOFFSET = 0
6360 LET TOTALPACKETS = -INT(-EXPECTEDFILESIZE / PACKETSIZE)
6370 LET CURRENTPACKET = 1
6400 LET EXPECTEDPACKETSIZE = EXPECTEDFILESIZE - CURRENTOFFSET
6410 IF EXPECTEDPACKETSIZE > PACKETSIZE THEN LET EXPECTEDPACKETSIZE = PACKETSIZE
6420 PRINT "Receiving packet " + STR$(CURRENTPACKET) + " / " + STR$(TOTALPACKETS) + " (" + STR$(EXPECTEDPACKETSIZE) + " bytes)"
6430 INPUT# 1, PACKET$
6440 IF LEN(PACKET$) < EXPECTEDPACKETSIZE * 2 THEN PRINT# 1, (LEN(PACKET$) / 2) : PRINT "Packet error; retrying" : GOTO 6400
6450 FOR I = 1 TO EXPECTEDPACKETSIZE
6460 LET OFFSET = I * 2 - 1
6470 LET NYBBLECHAR$ = MID$(PACKET$, OFFSET, 1)
6480 GOSUB 6800
6490 LET FILEBYTEDATA = NYBBLE * 16
6500 LET NYBBLECHAR$ = MID$(PACKET$, OFFSET + 1, 1)
6510 GOSUB 6800
6520 LET FILEBYTEDATA = FILEBYTEDATA + NYBBLE
6530 LSET FILEDATA$ = CHR$(FILEBYTEDATA)
6540 PUT #2
6550 NEXT I
6560 PRINT# 1, STR$(EXPECTEDPACKETSIZE) + CHR$(10)
6570 LET CURRENTOFFSET = CURRENTOFFSET + EXPECTEDPACKETSIZE
6580 IF CURRENTOFFSET < EXPECTEDFILESIZE THEN LET CURRENTPACKET = CURRENTPACKET + 1 : GOTO 6400
6590 CLOSE #2
6600 PRINT "File downloaded successfully"
6610 PRINT ""
6620 RETURN
6800 REM Converts nybble character in NYBBLECHAR$ to integer in NYBBLE
6810 LET NYBBLECHARASC = ASC(NYBBLECHAR$)
6820 IF NYBBLECHARASC >= 48 AND NYBBLECHARASC <= 57 THEN NYBBLE = NYBBLECHARASC - 48 : RETURN
6830 IF NYBBLECHARASC >= 65 AND NYBBLECHARASC <= 70 THEN NYBBLE = NYBBLECHARASC - 55 : RETURN
6840 IF NYBBLECHARASC >= 97 AND NYBBLECHARASC <= 102 THEN NYBBLE = NYBBLECHARASC - 87 : RETURN
6850 NYBBLE = 0
6860 RETURN

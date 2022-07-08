using System;
using System.IO;

namespace LainFTP.Lain.Functions {
    class LainFunctionUPLOADA : LainFunction {
        const uint DEFAULT_PACKET_SIZE = 16;

        FileStream openFile;
        long totalFileSize;

        byte[] binaryBuffer;
        LainLineBuffer asciiBuffer;

        public LainFunctionUPLOADA(LainFilesystem filesystem, LF_SEND_DATA sendData, LF_LOG_MESSAGE logMessage, LF_FINISHED finished) : base(filesystem, sendData, logMessage, finished) {
            openFile = null;
            totalFileSize = 0;
            binaryBuffer = null;
            asciiBuffer = new LainLineBuffer();
        }

        public override string getFunctionName() {
            return "UPLOADA";
        }

        public override void onDataReceived(byte[] data, int offset, int length) {
            receivePacketDataASCII(data, offset, length);
        }

        public override LF_START_CODE start(string commandName, string[] parameters) {
            if (commandName.ToUpper().Equals(getFunctionName())) {
                if (parameters.Length < 2) {
                    sendNewlineTerminatedErrorMessage("Command requires at least the <filename> and <size> parameters");
                    return LF_START_CODE.FAILED;
                }
                if (parameters.Length > 3) {
                    logMessage(SEVERITY_LEVEL.WARNING, getFunctionName(), "Command only takes 3 parameters. Ignoring " + (parameters.Length - 4) + " extra parameter(s).");
                }

                var currentFileInfo = filesystem.getFilePath(parameters[0]);
                if (currentFileInfo.Key == LainFilesystem.LainFSError.NO_DISK_SET) {
                    sendNewlineTerminatedErrorMessage("No disk is set. You must call DISK first to set a disk.");
                    return LF_START_CODE.FAILED;
                } else if (currentFileInfo.Key == LainFilesystem.LainFSError.INVALID_NAME) {
                    sendNewlineTerminatedErrorMessage("Invalid filename: " + parameters[0]);
                    return LF_START_CODE.FAILED;
                }

                long.TryParse(parameters[1], out totalFileSize);

                uint packetSize = DEFAULT_PACKET_SIZE;
                if (parameters.Length >= 3) {
                    if (!uint.TryParse(parameters[2], out packetSize)) {
                        logMessage(SEVERITY_LEVEL.WARNING, getFunctionName(), "Invalid packet size: " + parameters[2] + "; Defaulting to " + packetSize);
                    }
                }
                if (packetSize == 0) {
                    packetSize = DEFAULT_PACKET_SIZE;
                    logMessage(SEVERITY_LEVEL.WARNING, getFunctionName(), "Invalid packet size: " + parameters[2] + "; Defaulting to " + packetSize);
                }
                asciiBuffer.flushLines();
                asciiBuffer.flushData();
                binaryBuffer = new byte[packetSize];

                try {
                    openFile = File.Open(currentFileInfo.Value, FileMode.Create);
                } catch (Exception e) {
                    sendNewlineTerminatedErrorMessage(e.Message);
                    return LF_START_CODE.FAILED;
                }

                // Start the transfer
                sendNewlineTerminatedMessage(totalFileSize.ToString());
                logMessage(SEVERITY_LEVEL.INFO, getFunctionName(), "Receiving " + parameters[0] + " => " + currentFileInfo.Value);

                return LF_START_CODE.STARTED;
            }

            return LF_START_CODE.UNSUPPORTED;
        }

        public override void cancel() {
            if (openFile != null) {
                openFile.Close();
                openFile = null;
                logMessage(SEVERITY_LEVEL.WARNING, getFunctionName(), "Upload cancelled (timeout?)");
            }
        }

        private void receivePacketDataASCII(byte[] data, int offset, int length) {
            asciiBuffer.readData(data, offset, length);
            if (asciiBuffer.isReady()) {
                string line = asciiBuffer.getNextLine();
                asciiBuffer.flushData();
                asciiBuffer.flushLines();

                long remainingBytes = totalFileSize - openFile.Position;
                int expectedPacketBytes = Math.Min(binaryBuffer.Length, (int)remainingBytes);

                if (line.Length / 2 == expectedPacketBytes) {
                    for (int i = 0; i < expectedPacketBytes; ++i) {
                        int index = i * 2;
                        binaryBuffer[i] = getByteFromASCII(line[index], line[index + 1]);
                    }
                    printPacketProgressMessage(expectedPacketBytes);
                    openFile.Write(binaryBuffer, 0, expectedPacketBytes);
                } else {
                    logMessage(SEVERITY_LEVEL.WARNING, getFunctionName(), "Packet error; retrying...");
                }

                sendNewlineTerminatedMessage((line.Length / 2).ToString());
                if (openFile.Position >= totalFileSize) {
                    openFile.Close();
                    openFile = null;
                    logMessage(SEVERITY_LEVEL.INFO, getFunctionName(), "Upload completed successfully.");
                    finished();
                }
            }
        }

        private byte getByteFromASCII(char highNybble, char lowNybble) {
            return (byte)((getNybbleFromASCII(highNybble) << 4) | getNybbleFromASCII(lowNybble));
        }

        private byte getNybbleFromASCII(char nybble) {
            if (nybble >= '0' && nybble <= '9') {
                return (byte)(nybble - '0');
            } else if (nybble >= 'A' && nybble <= 'F') {
                return (byte)(nybble - 'A' + 10);
            } else if (nybble >= 'a' && nybble <= 'f') {
                return (byte)(nybble - 'a' + 10);
            }
            return 0;
        }

        private void printPacketProgressMessage(int expectedPacketBytes) {
            if (openFile != null) {
                long packetNumber = openFile.Position / binaryBuffer.LongLength + 1;
                long totalPackets = (long)Math.Ceiling((double)totalFileSize / binaryBuffer.Length);
                logMessage(SEVERITY_LEVEL.INFO, getFunctionName(), "Packet " + packetNumber + " / " + totalPackets + " received (" + expectedPacketBytes + " bytes)");
            }
        }
    }
}

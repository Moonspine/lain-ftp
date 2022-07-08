using System;
using System.IO;
using System.Text;

namespace LainFTP.Lain.Functions {
    class LainFunctionDOWNLOADA : LainFunction {
        const uint DEFAULT_PACKET_SIZE = 16;

        FileStream openFile;
        long totalFileSize;

        int expectedNextPacketSize;
        byte[] buffer;
        LainLineBuffer lineBuffer;

        public LainFunctionDOWNLOADA(LainFilesystem filesystem, LF_SEND_DATA sendData, LF_LOG_MESSAGE logMessage, LF_FINISHED finished) : base(filesystem, sendData, logMessage, finished) {
            openFile = null;
            totalFileSize = 0;
            expectedNextPacketSize = 0;
            buffer = null;
            lineBuffer = new LainLineBuffer();
        }


        public override string getFunctionName() {
            return "DOWNLOADA";
        }

        public override void onDataReceived(byte[] data, int offset, int length) {
            lineBuffer.readData(data, offset, length);

            if (lineBuffer.isReady()) {
                string line = lineBuffer.getNextLine();
                lineBuffer.flushData();
                lineBuffer.flushLines();

                int receivedBytes = 0;
                int.TryParse(line, out receivedBytes);

                if (receivedBytes != expectedNextPacketSize) {
                    logMessage(SEVERITY_LEVEL.WARNING, getFunctionName(), "Packet error; retrying...");
                    openFile.Seek(Math.Max(openFile.Position - expectedNextPacketSize, 0L), SeekOrigin.Begin);
                }

                sendNextPacket();
            }
        }

        public override LF_START_CODE start(string commandName, string[] parameters) {
            if (commandName.ToUpper().Equals(getFunctionName())) {
                if (parameters.Length < 1) {
                    sendNewlineTerminatedErrorMessage("Command requires at least the <filename> parameter");
                    return LF_START_CODE.FAILED;
                } if (parameters.Length > 3) {
                    logMessage(SEVERITY_LEVEL.WARNING, getFunctionName(), "Command only takes 2 parameters. Ignoring " + (parameters.Length - 2) + " extra parameter(s).");
                }

                var currentFileInfo = filesystem.getFilePath(parameters[0]);
                if (currentFileInfo.Key == LainFilesystem.LainFSError.NO_DISK_SET) {
                    sendNewlineTerminatedErrorMessage("No disk is set. You must call DISK first to set a disk.");
                    return LF_START_CODE.FAILED;
                } else if (currentFileInfo.Key == LainFilesystem.LainFSError.INVALID_NAME) {
                    sendNewlineTerminatedErrorMessage("Invalid filename: " + parameters[0]);
                    return LF_START_CODE.FAILED;
                }

                string filename = currentFileInfo.Value;
                if (!File.Exists(filename)) {
                    sendNewlineTerminatedErrorMessage("File does not exist: " + parameters[0]);
                    return LF_START_CODE.FAILED;
                }

                totalFileSize = new FileInfo(filename).Length;

                uint packetSize = DEFAULT_PACKET_SIZE;
                if (parameters.Length >= 2) {
                    if (!uint.TryParse(parameters[1], out packetSize)) {
                        logMessage(SEVERITY_LEVEL.WARNING, getFunctionName(), "Invalid packet size: " + parameters[1] + "; Defaulting to " + packetSize);
                    }
                }
                if (packetSize == 0) {
                    packetSize = DEFAULT_PACKET_SIZE;
                    logMessage(SEVERITY_LEVEL.WARNING, getFunctionName(), "Invalid packet size: " + parameters[1] + "; Defaulting to " + packetSize);
                }
                buffer = new byte[packetSize];

                try {
                    openFile = File.Open(filename, FileMode.Open);
                } catch (Exception e) {
                    sendNewlineTerminatedErrorMessage(e.Message);
                    return LF_START_CODE.FAILED;
                }

                logMessage(SEVERITY_LEVEL.INFO, getFunctionName(), "Sending " + filename + " => " + parameters[0]);
                sendNewlineTerminatedMessage(totalFileSize.ToString());

                return LF_START_CODE.STARTED;
            }

            return LF_START_CODE.UNSUPPORTED;
        }

        public override void cancel() {
            if (openFile != null) {
                openFile.Close();
                openFile = null;
                logMessage(SEVERITY_LEVEL.WARNING, getFunctionName(), "Download cancelled (timeout?)");
            }
        }

        private bool sendNextPacket() {
            if (openFile == null) {
                return false;
            }

            // Send data
            long previousFilePosition = openFile.Position;
            int readCount = openFile.Read(buffer, 0, buffer.Length);
            expectedNextPacketSize = readCount;
            if (readCount > 0) {
                sendBufferASCII(readCount);

                long packetNumber = previousFilePosition / buffer.Length + 1;
                long totalPackets = (long)Math.Ceiling((double)totalFileSize / buffer.Length);
                logMessage(SEVERITY_LEVEL.INFO, getFunctionName(), "Sending packet " + packetNumber + " / " + totalPackets + " (" + expectedNextPacketSize + " bytes)");
            }

            // Did we finish?
            if (readCount <= 0) {
                openFile.Close();
                openFile = null;
                logMessage(SEVERITY_LEVEL.INFO, getFunctionName(), "Download completed successfully.");
                finished();
                return false;
            }

            return true;
        }

        private void sendBufferASCII(int length) {
            StringBuilder result = new StringBuilder();

            for (int i = 0; i < length; ++i) {
                byte b = buffer[i];
                result.Append(getASCIIChar(b >> 4));
                result.Append(getASCIIChar(b));
            }

            sendNewlineTerminatedMessage(result.ToString());
        }

        private char getASCIIChar(int b) {
            int masked = b & 0xf;
            if (masked < 10) {
                return (char)('0' + masked);
            } else {
                return (char)('A' + (masked - 10));
            }
        }
    }
}

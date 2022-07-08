using System;
using System.IO;

namespace LainFTP.Lain.Functions {
    class LainFunctionDOWNLOADB : LainFunction {
        const uint DEFAULT_PACKET_SIZE = 16;

        FileStream openFile;
        long totalFileSize;

        int expectedNextPacketSize;
        byte[] buffer;
        LainLineBuffer lineBuffer;

        public LainFunctionDOWNLOADB(LainFilesystem filesystem, LF_SEND_DATA sendData, LF_LOG_MESSAGE logMessage, LF_FINISHED finished) : base(filesystem, sendData, logMessage, finished) {
            openFile = null;
            totalFileSize = 0;
            expectedNextPacketSize = 0;
            buffer = null;
            lineBuffer = new LainLineBuffer();
        }


        public override string getFunctionName() {
            return "DOWNLOADB";
        }

        public override void onDataReceived(byte[] data, int offset, int length) {
            lineBuffer.readData(data, offset, length);

            if (lineBuffer.isReady()) {
                string line = lineBuffer.getNextLine();
                lineBuffer.flushData();
                lineBuffer.flushLines();

                int receivedBytes = 0;
                int.TryParse(line, out receivedBytes);

                if (line.Equals("RETRY")) {
                    logMessage(SEVERITY_LEVEL.WARNING, getFunctionName(), "Packet error; retrying...");
                    openFile.Seek(Math.Max(openFile.Position - expectedNextPacketSize, 0L), SeekOrigin.Begin);
                } else if (line.Equals("OK")) {
                    sendNextPacket();
                } else {
                    cancel();
                    finished();
                }
            }
        }

        protected override void sendNewlineTerminatedErrorMessage(string message) {
            logMessage(SEVERITY_LEVEL.ERROR, getFunctionName(), message);
            sendNewlineTerminatedMessage("\0\0ERR: " + message);
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
                buffer = new byte[packetSize + 2];

                try {
                    openFile = File.Open(filename, FileMode.Open);
                } catch (Exception e) {
                    sendNewlineTerminatedErrorMessage(e.Message);
                    return LF_START_CODE.FAILED;
                }

                logMessage(SEVERITY_LEVEL.INFO, getFunctionName(), "Sending " + filename + " => " + parameters[0]);

                return sendNextPacket() ? LF_START_CODE.STARTED : LF_START_CODE.ALREADY_FINISHED;
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
            int packetSize = buffer.Length - 2;
            int readCount = openFile.Read(buffer, 2, packetSize);
            BitConverter.GetBytes((ushort)readCount).CopyTo(buffer, 0);
            expectedNextPacketSize = readCount;

            sendData(buffer, 0, readCount + 2);

            if (readCount > 0) {
                long packetNumber = previousFilePosition / packetSize + 1;
                long totalPackets = (long)Math.Ceiling((double)totalFileSize / packetSize);
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
    }
}

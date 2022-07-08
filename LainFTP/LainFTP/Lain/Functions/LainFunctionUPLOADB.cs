using System;
using System.IO;

namespace LainFTP.Lain.Functions {
    class LainFunctionUPLOADB : LainFunction {
        const uint DEFAULT_PACKET_SIZE = 16;

        FileStream openFile;

        int receivedCount;
        byte[] buffer;

        public LainFunctionUPLOADB(LainFilesystem filesystem, LF_SEND_DATA sendData, LF_LOG_MESSAGE logMessage, LF_FINISHED finished) : base(filesystem, sendData, logMessage, finished) {
            openFile = null;
            receivedCount = 0;
            buffer = null;
        }

        public override string getFunctionName() {
            return "UPLOADB";
        }

        public override void onDataReceived(byte[] data, int offset, int length) {
            receivePacketDataBinary(data, offset, length);
        }

        public override LF_START_CODE start(string commandName, string[] parameters) {
            if (commandName.ToUpper().Equals(getFunctionName())) {
                if (parameters.Length < 1) {
                    sendNewlineTerminatedErrorMessage("Command requires at least the <filename> parameter");
                    return LF_START_CODE.FAILED;
                }
                if (parameters.Length > 2) {
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

                uint packetSize = DEFAULT_PACKET_SIZE;
                if (parameters.Length >= 1) {
                    if (!uint.TryParse(parameters[1], out packetSize)) {
                        logMessage(SEVERITY_LEVEL.WARNING, getFunctionName(), "Invalid packet size: " + parameters[1] + "; Defaulting to " + packetSize);
                    }
                }
                if (packetSize == 0) {
                    packetSize = DEFAULT_PACKET_SIZE;
                    logMessage(SEVERITY_LEVEL.WARNING, getFunctionName(), "Invalid packet size: " + parameters[1] + "; Defaulting to " + packetSize);
                }
                buffer = new byte[packetSize + 2];
                receivedCount = 0;

                try {
                    openFile = File.Open(currentFileInfo.Value, FileMode.Create);
                } catch (Exception e) {
                    sendNewlineTerminatedErrorMessage(e.Message);
                    return LF_START_CODE.FAILED;
                }

                // Start the transfer
                sendNewlineTerminatedMessage("OK");
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

        private void receivePacketDataBinary(byte[] data, int offset, int length) {
            int totalReceived = receivedCount + length;
            for (int i = 0; i < length; ++i) {
                buffer[Math.Min(receivedCount++, buffer.Length - 1)] = data[offset + i];
            }

            if (totalReceived >= 2) {
                ushort expectedPacketBytes = BitConverter.ToUInt16(buffer, 0);

                // End of transfer
                if (expectedPacketBytes == 0) {
                    openFile.Close();
                    openFile = null;
                    logMessage(SEVERITY_LEVEL.INFO, getFunctionName(), "Upload completed successfully.");
                    finished();
                } else {
                    if (totalReceived == expectedPacketBytes + 2) {
                        receivedCount = 0;
                        printPacketProgressMessage(expectedPacketBytes);
                        openFile.Write(buffer, 2, expectedPacketBytes);
                        sendNewlineTerminatedMessage("OK");
                    }
                }
            }
        }

        private void printPacketProgressMessage(int expectedPacketBytes) {
            if (openFile != null) {
                long packetNumber = openFile.Position / (buffer.LongLength - 2) + 1;
                logMessage(SEVERITY_LEVEL.INFO, getFunctionName(), "Packet " + packetNumber + " received (" + expectedPacketBytes + " bytes)");
            }
        }
    }
}

using System;
using System.Collections.Generic;
using System.IO;

namespace LainFTP.Lain.Functions {
    class LainFunctionLIST : LainFunction {
        private List<FileSystemInfo> currentDirectoryInfo;
        private int nextIndex = 0;
        private LainLineBuffer readBuffer;

        public LainFunctionLIST(LainFilesystem filesystem, LF_SEND_DATA sendData, LF_LOG_MESSAGE logMessage, LF_FINISHED finished) : base(filesystem, sendData, logMessage, finished) {
            currentDirectoryInfo = null;
            nextIndex = 0;
            readBuffer = new LainLineBuffer();
        }

        public override string getFunctionName() {
            return "LIST";
        }

        public override void onDataReceived(byte[] data, int offset, int length) {
            readBuffer.readData(data, offset, length);

            if (readBuffer.isReady()) {
                string line = readBuffer.getNextLine();
                readBuffer.flushLines();
                readBuffer.flushData();
                if (line.ToUpper().Equals("OK")) {
                    sendNextListing();
                } else {
                    // Resend if we didn't get a response we're OK with
                    nextIndex = Math.Max(nextIndex - 1, 0);
                    sendNextListing();
                }
            }
        }

        public override LF_START_CODE start(string commandName, string[] parameters) {
            if (commandName.ToUpper().Equals(getFunctionName())) {
                if (parameters.Length > 0) {
                    logMessage(SEVERITY_LEVEL.WARNING, getFunctionName(), "Command does not take any parameters. Ignoring " + parameters.Length + " extra parameter(s).");
                }

                var currentDirectoryData = filesystem.getCurrentDirectory();
                if (currentDirectoryData.Key == LainFilesystem.LainFSError.NO_DISK_SET) {
                    sendNewlineTerminatedErrorMessage("No disk is set. You must call DISK first to set a disk.");
                    return LF_START_CODE.FAILED;
                }

                currentDirectoryInfo = new List<FileSystemInfo>(new DirectoryInfo(currentDirectoryData.Value).EnumerateFileSystemInfos());
                nextIndex = 0;

                return sendNextListing() ? LF_START_CODE.STARTED : LF_START_CODE.ALREADY_FINISHED;
            }

            return LF_START_CODE.UNSUPPORTED;
        }

        private bool sendNextListing() {
            if (currentDirectoryInfo == null) {
                return false;
            }

            if (nextIndex < currentDirectoryInfo.Count) {
                FileSystemInfo info = currentDirectoryInfo[nextIndex++];
                string filename = info.Name;
                string type = (info.Attributes & FileAttributes.Directory) > 0 ? "\\" : "";
                sendNewlineTerminatedMessage(filename + type);
                return true;
            } else {
                sendNewlineTerminatedMessage("EOF");
                currentDirectoryInfo = null;
                nextIndex = 0;
                finished();
                return false;
            }
        }
    }
}

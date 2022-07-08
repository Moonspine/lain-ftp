namespace LainFTP.Lain.Functions {
    class LainFunctionDIR : LainFunction {
        public LainFunctionDIR(LainFilesystem filesystem, LF_SEND_DATA sendData, LF_LOG_MESSAGE logMessage, LF_FINISHED finished) : base(filesystem, sendData, logMessage, finished) { }

        public override string getFunctionName() {
            return "DIR";
        }

        public override void onDataReceived(byte[] data, int offset, int length) {
            logMessage(SEVERITY_LEVEL.ERROR, getFunctionName(), "Command should not receive any additional data beyond the initial command string");
        }

        public override LF_START_CODE start(string commandName, string[] parameters) {
            if (commandName.ToUpper().Equals(getFunctionName())) {
                if (parameters.Length < 1) {
                    // Send the directory back
                    sendNewlineTerminatedMessage(filesystem.getDirectoryName());
                    return LF_START_CODE.ALREADY_FINISHED;
                } else if (parameters.Length > 2) {
                    logMessage(SEVERITY_LEVEL.WARNING, getFunctionName(), "Command only takes one parameter. Ignoring " + (parameters.Length - 1) + " extra parameter(s).");
                }

                // Change directories
                string dirName = parameters[0];
                LainFilesystem.LainFSError error = filesystem.changeDirectory(dirName);
                if (error == LainFilesystem.LainFSError.INVALID_NAME) {
                    sendNewlineTerminatedErrorMessage("Invalid directory name: " + dirName);
                    return LF_START_CODE.FAILED;
                } else if (error == LainFilesystem.LainFSError.NO_DISK_SET) {
                    sendNewlineTerminatedErrorMessage("No disk is set. You must call DISK first to set a disk.");
                    return LF_START_CODE.FAILED;
                }

                // Reply to the client
                sendNewlineTerminatedMessage("OK");
                logMessage(SEVERITY_LEVEL.INFO, getFunctionName(), "Current directory changed to \"" + dirName + "\"");

                return LF_START_CODE.ALREADY_FINISHED;
            }

            return LF_START_CODE.UNSUPPORTED;
        }
    }
}

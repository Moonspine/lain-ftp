namespace LainFTP.Lain.Functions {
    abstract class LainFunction {
        protected LainFilesystem filesystem;
        protected LF_SEND_DATA sendData;
        protected LF_LOG_MESSAGE logMessage;
        protected LF_FINISHED finished;

        public LainFunction(LainFilesystem filesystem, LF_SEND_DATA sendData, LF_LOG_MESSAGE logMessage, LF_FINISHED finished) {
            this.filesystem = filesystem;
            this.sendData = sendData;
            this.logMessage = logMessage;
            this.finished = finished;
        }

        public abstract string getFunctionName();

        public virtual void onDataReceived(byte[] data, int offset, int length) {
            // No base implementation
        }

        public virtual LF_START_CODE start(string commandName, string[] parameters) {
            // No base implementation
            return LF_START_CODE.UNSUPPORTED;
        }

        public virtual void cancel() {
            // No base implementation
        }


        protected void sendNewlineTerminatedMessage(string message) {
            byte[] data = new byte[message.Length + 2];
            for (int i = 0; i < message.Length; ++i) {
                data[i] = (byte)(message[i] & 0xff);
            }
            data[data.Length - 2] = 13;
            data[data.Length - 1] = 10;
            sendData(data, 0, data.Length);
        }

        protected virtual void sendNewlineTerminatedErrorMessage(string message) {
            logMessage(SEVERITY_LEVEL.ERROR, getFunctionName(), message);
            sendNewlineTerminatedMessage("ERR: " + message);
        }
    }

    delegate void LF_SEND_DATA(byte[] data, int offset, int length);
    delegate void LF_FINISHED();
    delegate void LF_LOG_MESSAGE(SEVERITY_LEVEL severityLevel, string functionName, string message);

    enum LF_START_CODE {
        UNSUPPORTED,     // This function Lain function does not support the given command string (proceed as normal)
        FAILED,          // The function failed to start, likely due to an invalid parameter 
        STARTED,         // The function has started
        ALREADY_FINISHED // The function has already finished (used when the function has no real data to send and does everything on start)
    };

    enum SEVERITY_LEVEL {
        INFO,
        WARNING,
        ERROR
    }
}

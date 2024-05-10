using LainFTP.Lain.Functions;
using System;
using System.Collections.Generic;
using System.IO.Ports;
using System.Text;

namespace LainFTP.Lain {
    public class LainFTPServer {
        const int TIMEOUT_MS = 10000;

        SerialPort port;

        List<LainFunction> allFunctions;
        LainFunction activeFunction;
        long lastFunctionActivityTimestamp;

        int lastCommandBufferOffset;
        byte[] buffer;

        public LainFTPServer(LainFilesystem filesystem, string comPort, uint baudRate, bool useDtrRts) {
            port = new SerialPort();

            port.PortName = comPort;
            port.BaudRate = (int)baudRate;
            port.Parity = Parity.None;
            port.DataBits = 8;
            port.StopBits = StopBits.One;
            port.Handshake = Handshake.None;
            port.ReadTimeout = TIMEOUT_MS;
            port.WriteTimeout = TIMEOUT_MS;

            if (useDtrRts) {
				port.DtrEnable = true;
				port.RtsEnable = true;
			}

			Console.Out.WriteLine("Bringing server up on " + comPort + " @ " + baudRate + " baud");
            Console.Out.WriteLine("No parity, 8 data bits, 1 stop bit, no handshaking");
            Console.Out.WriteLine("");

            port.DataReceived += dataReceived;
            port.ErrorReceived += errorReceived;

            allFunctions = new List<LainFunction>();
            allFunctions.Add(new LainFunctionDISK(filesystem, sendData, logMessage, functionFinished));
            allFunctions.Add(new LainFunctionDIR(filesystem, sendData, logMessage, functionFinished));
            allFunctions.Add(new LainFunctionLIST(filesystem, sendData, logMessage, functionFinished));
            allFunctions.Add(new LainFunctionDOWNLOADA(filesystem, sendData, logMessage, functionFinished));
            allFunctions.Add(new LainFunctionUPLOADA(filesystem, sendData, logMessage, functionFinished));
            allFunctions.Add(new LainFunctionDOWNLOADB(filesystem, sendData, logMessage, functionFinished));
            allFunctions.Add(new LainFunctionUPLOADB(filesystem, sendData, logMessage, functionFinished));
            activeFunction = null;

            buffer = new byte[1024];
            lastCommandBufferOffset = 0;
            lastFunctionActivityTimestamp = 0;
        }

        private void errorReceived(object sender, SerialErrorReceivedEventArgs e) {
            cancelFunction();
        }

        private void dataReceived(object sender, SerialDataReceivedEventArgs e) {
            long currentTimestamp = DateTime.Now.Ticks;
            if (activeFunction != null && ((currentTimestamp - lastFunctionActivityTimestamp) / TimeSpan.TicksPerMillisecond) > TIMEOUT_MS) {
                cancelFunction();
            }

            if (activeFunction == null) {
                while (port.BytesToRead > 0) {
                    int nextData = port.ReadByte();
                    if (nextData == 10) { // Commands are terminated by line feeds
                        // Command ended; time to execute
                        string commandString = Encoding.ASCII.GetString(buffer, 0, lastCommandBufferOffset);
                        string[] commandTokens = commandString.Split(new char[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);

                        if (commandTokens.Length > 0) {
                            // Grab the command and its parameters
                            string commandName = commandTokens[0];
                            string[] commandParameters = new string[commandTokens.Length - 1];
                            if (commandParameters.Length > 0) {
                                Array.Copy(commandTokens, 1, commandParameters, 0, commandParameters.Length);
                            }

                            // Start the command
                            for (int i = 0; i < allFunctions.Count && activeFunction == null; ++i) {
                                LF_START_CODE startCode = allFunctions[i].start(commandName, commandParameters);
                                if (startCode != LF_START_CODE.UNSUPPORTED) {
                                    if (startCode == LF_START_CODE.FAILED) {
                                        // Each function writes its own error message, so we can afford to be silent here
                                    } else if (startCode == LF_START_CODE.STARTED) {
                                        activeFunction = allFunctions[i];
                                        lastFunctionActivityTimestamp = DateTime.Now.Ticks;
                                    }
                                }
                            }
                        }

                        lastCommandBufferOffset = 0;
                    } else if (lastCommandBufferOffset >= buffer.Length) {
                        // Buffer overrun; a command should never be this long, so we'll truncate it by doing nothing
                    } else if (nextData < 0x20) {
                        // Ignore control characters other than newline
                    } else {
                        // Receive command byte
                        buffer[lastCommandBufferOffset++] = (byte)nextData;
                    }
                }
            } else {
                // If we're executing a Lain function, just read the buffer full and send it along
                try {
                    int count = port.Read(buffer, 0, buffer.Length);
                    activeFunction.onDataReceived(buffer, 0, count);
                    lastFunctionActivityTimestamp = DateTime.Now.Ticks;
                } catch (TimeoutException) {
                    cancelFunction();
                }
            }
        }

        private void sendData(byte[] data, int offset, int count) {
            try {
                port.Write(data, offset, count);
                lastFunctionActivityTimestamp = DateTime.Now.Ticks;
            } catch (TimeoutException) {
                cancelFunction();
            }
        }

        private void functionFinished() {
            activeFunction = null;
            lastCommandBufferOffset = 0;
        }

        private void cancelFunction() {
            if (activeFunction != null) {
                activeFunction.cancel();
                functionFinished();
            }
        }

        private void logMessage(SEVERITY_LEVEL severityLevel, string functionName, string message) {
            StringBuilder result = new StringBuilder();

            switch (severityLevel) {
                case SEVERITY_LEVEL.INFO:
                    result.Append("[Info] ");
                    break;
                case SEVERITY_LEVEL.WARNING:
                    result.Append("[Warning] ");
                    break;
                case SEVERITY_LEVEL.ERROR:
                    result.Append("[Error] ");
                    break;
            }

            result.Append(functionName);
            result.Append(": ");
            result.Append(message);

            Console.Out.WriteLine(result.ToString());
        }

        public void connect() {
            if (!port.IsOpen) {
                try {
                    port.Open();
                } catch (Exception) {
                    // Nothing to do here; it's an invalid port name
                }
            }
        }

        public bool isRunning() {
            return port.IsOpen;
        }

        public static string[] getPortNames() {
            return SerialPort.GetPortNames();
        }
    }
}

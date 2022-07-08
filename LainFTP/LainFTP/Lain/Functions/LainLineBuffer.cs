using System.Collections.Generic;
using System.Text;

namespace LainFTP.Lain.Functions {
    public class LainLineBuffer {
        StringBuilder builder;
        Queue<string> lines;

        public LainLineBuffer() {
            builder = new StringBuilder();
            lines = new Queue<string>();
        }

        public void readData(byte[] data, int offset, int length) {
            for (int i = 0; i < length; ++i) {
                byte b = data[i + offset];
                if (b == 10) {
                    if (builder.Length > 0) {
                        lines.Enqueue(builder.ToString());
                        builder.Clear();
                    }
                } else if (b < 0x20) {
                    // Ignore other control characters (they don't make good string data anyway)
                } else {
                    builder.Append((char)b);
                }
            }
        }

        public bool isReady() {
            return lines.Count > 0;
        }

        public string getNextLine() {
            if (lines.Count > 0) {
                return lines.Dequeue();
            }
            return "";
        }

        public void flushLines() {
            lines.Clear();
        }

        public void flushData() {
            builder.Clear();
        }
    }
}

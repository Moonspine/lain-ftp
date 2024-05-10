using LainFTP.Lain;
using System;
using System.Threading;

namespace LainFTP {
    class Program {

        static void Main(string[] args) {
            if (args.Length < 2) {
                printUsage();
                return;
            }

            LainFilesystem filesystem = new LainFilesystem(AppContext.BaseDirectory + "Disks\\");
            LainFTPServer server = new LainFTPServer(filesystem, args[0], uint.Parse(args[1]), args.Length > 2 ? bool.Parse(args[2]) : false);
            server.connect();

            if (!server.isRunning()) {
                Console.Out.WriteLine("Failed to open " + args[0]);
                Console.Out.WriteLine("Detected port names:");
                foreach (string portName in LainFTPServer.getPortNames()) {
                    Console.Out.WriteLine(portName);
                }
                Console.Out.WriteLine();
            } else {
                Console.Out.WriteLine("Port " + args[0] + " opened.");
            }

            while (server.isRunning()) {
                Thread.Sleep(100);
            }

            Console.Out.WriteLine("Server closed");
        }

        private static void printUsage() {
            Console.Out.WriteLine("Usage:");
            Console.Out.WriteLine("LainFTP <portName> [baudRate = 19200] [useDtrRts = false]");
            Console.Out.WriteLine();
            Console.Out.WriteLine("For example:");
            Console.Out.WriteLine("LainFTP COM1 9600 true");
        }
    }
}

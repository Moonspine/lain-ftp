using System;
using System.Collections.Generic;
using System.IO;

namespace LainFTP.Lain {
    public class LainFilesystem {
        static HashSet<char> INVALID_FILENAME_CHARS = new HashSet<char>(Path.GetInvalidFileNameChars());
        static HashSet<char> INVALID_PATHNAME_CHARS = new HashSet<char>(Path.GetInvalidPathChars());

        string root;
        string currentDisk;
        string currentDirectory;

        string currentDiskName;
        string currentDirectoryName;

        public enum LainFSError {
            OK,
            INVALID_NAME,
            NO_DISK_SET
        }

        public LainFilesystem(string root) {
            this.root = "\\\\?\\" + root;

            currentDisk = currentDirectory = "";
            currentDiskName = currentDirectoryName = "";
        }

        public LainFSError changeDisk(string diskName) {
            if (!isFilenameValid(diskName, false)) {
                return LainFSError.INVALID_NAME;
            }

            string newDisk = root + diskName + "\\";
            try {
                Directory.CreateDirectory(newDisk);
                currentDirectory = currentDisk = newDisk;
                currentDiskName = diskName;
                return LainFSError.OK;
            } catch (Exception) {
                // Whatever the reason, this failed
            }

            return LainFSError.INVALID_NAME;
        }

        public LainFSError changeDirectory(string directoryName) {
            if (!isFilenameValid(directoryName, true)) {
                return LainFSError.INVALID_NAME;
            }

            if (currentDisk.Length == 0) {
                return LainFSError.NO_DISK_SET;
            }

            string newDirectory = currentDisk + (directoryName.StartsWith("\\") ? directoryName.Substring(1) : directoryName);
            try {
                Directory.CreateDirectory(newDirectory);
                currentDirectory = newDirectory;
                currentDirectoryName = directoryName;
                return LainFSError.OK;
            } catch (Exception) {
                // Whatever the reason, this failed
            }

            return LainFSError.INVALID_NAME;
        }

        public KeyValuePair<LainFSError, string> getFilePath(string filename) {
            if (!isFilenameValid(filename, false)) {
                return new KeyValuePair<LainFSError, string>(LainFSError.INVALID_NAME, "");
            }

            if (currentDisk.Length == 0) {
                return new KeyValuePair<LainFSError, string>(LainFSError.NO_DISK_SET, "");
            }

            return new KeyValuePair<LainFSError, string>(LainFSError.OK, currentDirectory + (currentDirectory.EndsWith("\\") ? "" : "\\") + filename);
        }

        public KeyValuePair<LainFSError, string> getCurrentDirectory() {
            if (currentDisk.Length == 0) {
                return new KeyValuePair<LainFSError, string>(LainFSError.NO_DISK_SET, "");
            }
            return new KeyValuePair<LainFSError, string>(LainFSError.OK, currentDirectory);
        }

        public string getDiskName() {
            return currentDiskName.Length == 0 ? "<NONE>" : currentDiskName;
        }

        public string getDirectoryName() {
            return currentDirectoryName.Length == 0 ? "\\" : currentDirectoryName;
        }

        private bool isFilenameValid(string filename, bool isDirectory) {
            if (filename.IndexOf("..") >= 0) {
                return false;
            }
            HashSet<char> invalidChars = isDirectory ? INVALID_PATHNAME_CHARS : INVALID_FILENAME_CHARS;
            foreach (char c in filename) {
                if (invalidChars.Contains(c)) {
                    return false;
                }
            }
            return true;
        }
    }
}

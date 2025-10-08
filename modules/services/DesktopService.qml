pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string desktopDir: ""
    property bool initialLoadComplete: false

    property ListModel items: ListModel {
        id: itemsModel
    }

    function getDesktopDir() {
        getDesktopDirProcess.running = true;
    }

    function scanDesktop() {
        if (desktopDir) {
            scanProcess.running = true;
        }
    }

    function parseDesktopFile(filePath) {
        parseDesktopProcess.command = ["cat", filePath];
        parseDesktopProcess.running = true;
    }

    function executeDesktopFile(filePath) {
        execDesktopProcess.command = ["gtk-launch", filePath.split('/').pop().replace('.desktop', '')];
        execDesktopProcess.running = true;
    }

    function openFile(filePath) {
        openFileProcess.command = ["xdg-open", filePath];
        openFileProcess.running = true;
    }

    function getFileType(fileName) {
        var ext = fileName.toLowerCase().split('.').pop();
        
        if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp'].includes(ext)) {
            return 'image';
        } else if (['mp4', 'webm', 'mov', 'avi', 'mkv', 'mp3', 'wav', 'ogg', 'flac'].includes(ext)) {
            return 'media';
        } else if (['pdf'].includes(ext)) {
            return 'pdf';
        } else if (['txt', 'md', 'log'].includes(ext)) {
            return 'text';
        } else if (['zip', 'tar', 'gz', 'rar', '7z'].includes(ext)) {
            return 'archive';
        } else if (['doc', 'docx', 'odt'].includes(ext)) {
            return 'document';
        }
        return 'file';
    }

    function getIconForType(type) {
        switch(type) {
            case 'folder': return 'folder';
            case 'image': return 'image-x-generic';
            case 'media': return 'video-x-generic';
            case 'pdf': return 'application-pdf';
            case 'text': return 'text-x-generic';
            case 'archive': return 'package-x-generic';
            case 'document': return 'x-office-document';
            default: return 'text-x-generic';
        }
    }

    Component.onCompleted: {
        getDesktopDir();
    }

    Process {
        id: getDesktopDirProcess
        running: false
        command: ["sh", "-c", "echo ${XDG_DESKTOP_DIR:-$HOME/Desktop}"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.desktopDir = text.trim();
                console.log("Desktop directory:", root.desktopDir);
                scanDesktop();
                directoryWatcher.path = root.desktopDir;
                directoryWatcher.reload();
            }
        }
    }

    FileView {
        id: directoryWatcher
        path: ""
        watchChanges: true
        printErrors: false

        onFileChanged: {
            console.log("Desktop directory changed, rescanning...");
            scanDesktop();
        }
    }

    Process {
        id: scanProcess
        running: false
        command: ["sh", "-c", "ls -1ap " + root.desktopDir + " | grep -v '^\\.$' | grep -v '^\\.\\.$'"]

        stdout: StdioCollector {
            onStreamFinished: {
                var entries = text.trim().split("\n").filter(f => f.length > 0);
                var newItems = [];
                var pendingDesktopFiles = [];

                for (var i = 0; i < entries.length; i++) {
                    var entry = entries[i];
                    var isDir = entry.endsWith('/');
                    var name = isDir ? entry.slice(0, -1) : entry;
                    var fullPath = root.desktopDir + "/" + name;

                    if (name.startsWith('.')) {
                        continue;
                    }

                    if (isDir) {
                        newItems.push({
                            name: name,
                            path: fullPath,
                            type: 'folder',
                            icon: 'folder',
                            isDesktopFile: false,
                            sortOrder: 0
                        });
                    } else if (name.endsWith('.desktop')) {
                        pendingDesktopFiles.push({
                            name: name,
                            path: fullPath,
                            type: 'application',
                            icon: 'application-x-executable',
                            isDesktopFile: true,
                            sortOrder: 1
                        });
                    } else {
                        var fileType = root.getFileType(name);
                        newItems.push({
                            name: name,
                            path: fullPath,
                            type: fileType,
                            icon: root.getIconForType(fileType),
                            isDesktopFile: false,
                            sortOrder: 2
                        });
                    }
                }

                tempDesktopFiles = pendingDesktopFiles;
                tempItems = newItems;
                
                if (pendingDesktopFiles.length > 0) {
                    currentDesktopFileIndex = 0;
                    parseNextDesktopFile();
                } else {
                    finalizeItems();
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("Error scanning desktop:", text);
                }
            }
        }
    }

    property var tempDesktopFiles: []
    property var tempItems: []
    property int currentDesktopFileIndex: -1

    function parseNextDesktopFile() {
        if (currentDesktopFileIndex < tempDesktopFiles.length) {
            var item = tempDesktopFiles[currentDesktopFileIndex];
            parseDesktopFileProcess.command = ["cat", item.path];
            parseDesktopFileProcess.running = true;
        } else {
            finalizeItems();
        }
    }

    function finalizeItems() {
        var allItems = tempItems.concat(tempDesktopFiles);
        
        allItems.sort((a, b) => {
            if (a.sortOrder !== b.sortOrder) {
                return a.sortOrder - b.sortOrder;
            }
            return a.name.localeCompare(b.name);
        });

        items.clear();
        for (var i = 0; i < allItems.length; i++) {
            var item = allItems[i];
            items.append({
                name: item.name,
                path: item.path,
                type: item.type,
                icon: item.icon,
                isDesktopFile: item.isDesktopFile
            });
        }
        
        root.initialLoadComplete = true;
        console.log("Desktop scan complete. Found", allItems.length, "items");
    }

    Process {
        id: parseDesktopFileProcess
        running: false
        command: []

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n");
                var item = tempDesktopFiles[currentDesktopFileIndex];
                var name = "";
                var icon = "application-x-executable";
                
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.startsWith("Name=")) {
                        name = line.substring(5);
                    } else if (line.startsWith("Icon=")) {
                        icon = line.substring(5);
                    }
                }

                if (name) {
                    item.name = name;
                }
                item.icon = icon;
                
                currentDesktopFileIndex++;
                parseNextDesktopFile();
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("Error parsing .desktop file:", text);
                }
                currentDesktopFileIndex++;
                parseNextDesktopFile();
            }
        }
    }

    Process {
        id: execDesktopProcess
        running: false
        command: []

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.log("Desktop file execution:", text);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("Desktop file execution error:", text);
                }
            }
        }
    }

    Process {
        id: openFileProcess
        running: false
        command: []

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.log("File opened:", text);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("Error opening file:", text);
                }
            }
        }
    }
}

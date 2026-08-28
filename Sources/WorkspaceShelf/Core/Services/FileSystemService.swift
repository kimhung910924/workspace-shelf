import AppKit
import Foundation

enum FileSystemService {
    nonisolated static func listDirectory(
        at directoryURL: URL,
        showHiddenFiles: Bool = false
    ) -> DirectoryLoadResult {
        do {
            var options: FileManager.DirectoryEnumerationOptions = [.skipsSubdirectoryDescendants]
            if !showHiddenFiles {
                options.insert(.skipsHiddenFiles)
            }

            let keys: Set<URLResourceKey> = [
                .localizedNameKey,
                .isDirectoryKey,
                .isPackageKey,
                .isSymbolicLinkKey,
                .contentModificationDateKey,
                .fileSizeKey
            ]
            let urls = try FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: Array(keys),
                options: options
            )

            let entries = try urls.map { url in
                let values = try url.resourceValues(forKeys: keys)
                let isDirectory = values.isDirectory ?? false
                let isPackage = values.isPackage ?? false
                return FileEntry(
                    url: url.standardizedFileURL,
                    name: values.localizedName ?? url.lastPathComponent,
                    isDirectory: isDirectory,
                    isPackage: isPackage,
                    isSymbolicLink: values.isSymbolicLink ?? false,
                    modificationDate: values.contentModificationDate,
                    fileSize: isDirectory ? nil : values.fileSize.map(Int64.init)
                )
            }
            return .success(entries)
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    @MainActor
    static func open(_ url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }

    @MainActor
    static func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    @MainActor
    static func openInTerminal(_ url: URL) {
        let directoryURL: URL
        if (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
            directoryURL = url
        } else {
            directoryURL = url.deletingLastPathComponent()
        }

        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open(
            [directoryURL],
            withApplicationAt: URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"),
            configuration: configuration
        ) { _, _ in }
    }

    @MainActor
    static func copyToPasteboard(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }

    @MainActor
    static func copyFileURLsToPasteboard(_ urls: [URL]) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects(urls.map { $0 as NSURL })
    }

    @MainActor
    static func fileURLsFromPasteboard() -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true
        ]
        return (NSPasteboard.general.readObjects(
            forClasses: [NSURL.self],
            options: options
        ) as? [URL]) ?? []
    }
}

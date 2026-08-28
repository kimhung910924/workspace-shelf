import Foundation

/// Watches the folder currently on screen and reports when its contents
/// change behind the app's back.
///
/// Needed as soon as an outbound drag can be a *move*: Finder performs the
/// move itself, so without this the row would sit in the listing pointing at
/// a file that is no longer there. It also covers the ordinary case of the
/// same folder being edited in Finder while the shelf is open.
///
/// Only one folder is watched at a time — one file descriptor, replaced on
/// navigation.
@MainActor
final class DirectoryWatcher {
    private var source: DispatchSourceFileSystemObject?
    private var watchedURL: URL?
    private var pendingNotification: Task<Void, Never>?
    private let onChange: @MainActor () -> Void

    init(onChange: @escaping @MainActor () -> Void) {
        self.onChange = onChange
    }

    deinit {
        source?.cancel()
        pendingNotification?.cancel()
    }

    func watch(_ directoryURL: URL) {
        let url = directoryURL.standardizedFileURL
        guard url != watchedURL else { return }
        stop()

        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated {
                self?.scheduleNotification()
            }
        }
        source.setCancelHandler {
            close(descriptor)
        }

        watchedURL = url
        self.source = source
        source.resume()
    }

    func stop() {
        source?.cancel()
        source = nil
        watchedURL = nil
        pendingNotification?.cancel()
        pendingNotification = nil
    }

    /// A single file operation fires several events; this collapses a burst
    /// into one reload.
    private func scheduleNotification() {
        pendingNotification?.cancel()
        pendingNotification = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            self?.onChange()
        }
    }
}

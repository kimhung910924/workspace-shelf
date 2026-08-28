import Foundation

enum FileOperationResult: Sendable, Equatable {
    case success
    case failure(String)
}

enum FileOperationService {
    enum ValidationError: LocalizedError {
        case emptyName
        case reservedName
        case invalidCharacter
        case alreadyExists(String)
        case cannotMoveIntoDescendant

        var errorDescription: String? {
            switch self {
            case .emptyName:
                L10n.t("이름을 입력하세요.", "Enter a name.")
            case .reservedName:
                L10n.t("이 이름은 사용할 수 없습니다.", "This name can't be used.")
            case .invalidCharacter:
                L10n.t("이름에는 / 또는 :를 사용할 수 없습니다.", "Names can't contain / or :.")
            case .alreadyExists(let name):
                L10n.t("같은 위치에 \(name)이(가) 이미 있습니다.", "\"\(name)\" already exists in this location.")
            case .cannotMoveIntoDescendant:
                L10n.t("폴더를 자기 자신 또는 하위 폴더 안으로 이동할 수 없습니다.", "A folder can't be moved into itself or one of its subfolders.")
            }
        }
    }

    nonisolated static func validateName(_ value: String) throws -> String {
        let name = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw ValidationError.emptyName }
        guard name != ".", name != ".." else { throw ValidationError.reservedName }
        guard !name.contains("/"), !name.contains(":") else {
            throw ValidationError.invalidCharacter
        }
        return name
    }

    nonisolated static func createFolder(named value: String, in directoryURL: URL) -> FileOperationResult {
        do {
            let name = try validateName(value)
            let destinationURL = directoryURL.appendingPathComponent(name, isDirectory: true)
            guard !FileManager.default.fileExists(atPath: destinationURL.path) else {
                throw ValidationError.alreadyExists(name)
            }
            try FileManager.default.createDirectory(
                at: destinationURL,
                withIntermediateDirectories: false
            )
            return .success
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    nonisolated static func rename(_ sourceURL: URL, to value: String) -> FileOperationResult {
        do {
            let name = try validateName(value)
            let destinationURL = sourceURL.deletingLastPathComponent().appendingPathComponent(name)
            guard destinationURL.standardizedFileURL != sourceURL.standardizedFileURL else {
                return .success
            }
            guard !FileManager.default.fileExists(atPath: destinationURL.path) else {
                throw ValidationError.alreadyExists(name)
            }
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
            return .success
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    nonisolated static func moveToTrash(_ sourceURL: URL) -> FileOperationResult {
        do {
            _ = try FileManager.default.trashItem(at: sourceURL, resultingItemURL: nil)
            return .success
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    nonisolated static func copy(
        _ sourceURLs: [URL],
        to destinationDirectoryURL: URL,
        renameConflicts: Bool
    ) -> FileOperationResult {
        do {
            for sourceURL in sourceURLs {
                let normalizedSource = sourceURL.standardizedFileURL
                let proposedDestination = destinationDirectoryURL
                    .appendingPathComponent(normalizedSource.lastPathComponent)

                let destinationURL: URL
                if normalizedSource == proposedDestination.standardizedFileURL {
                    // Pasting into the folder the item already lives in.
                    // Finder duplicates it as "note copy.txt" instead of
                    // doing nothing, and so does this — skipping here made
                    // an in-place paste look silently broken.
                    destinationURL = nextAvailableCopyURL(
                        for: normalizedSource,
                        in: destinationDirectoryURL
                    )
                } else if FileManager.default.fileExists(atPath: proposedDestination.path) {
                    guard renameConflicts else {
                        throw ValidationError.alreadyExists(proposedDestination.lastPathComponent)
                    }
                    destinationURL = nextAvailableCopyURL(
                        for: normalizedSource,
                        in: destinationDirectoryURL
                    )
                } else {
                    destinationURL = proposedDestination
                }
                try FileManager.default.copyItem(at: normalizedSource, to: destinationURL)
            }
            return .success
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    /// Moves items to a new folder (a same-volume drag, matching Finder's
    /// default drag behavior). Used by the column browser's drag-between-
    /// columns gesture. Refuses to move a folder into itself or one of its
    /// own descendants, and refuses to overwrite an existing item rather
    /// than silently clobbering it.
    nonisolated static func move(
        _ sourceURLs: [URL],
        to destinationDirectoryURL: URL
    ) -> FileOperationResult {
        do {
            for sourceURL in sourceURLs {
                let normalizedSource = sourceURL.standardizedFileURL
                let normalizedDestination = destinationDirectoryURL.standardizedFileURL

                let isDirectory = (try? normalizedSource.resourceValues(
                    forKeys: [.isDirectoryKey]
                ).isDirectory) ?? false
                if isDirectory, WorkspacePathPolicy.contains(normalizedDestination, within: normalizedSource) {
                    throw ValidationError.cannotMoveIntoDescendant
                }

                let proposedDestination = normalizedDestination
                    .appendingPathComponent(normalizedSource.lastPathComponent)
                if normalizedSource == proposedDestination.standardizedFileURL {
                    continue
                }
                guard !FileManager.default.fileExists(atPath: proposedDestination.path) else {
                    throw ValidationError.alreadyExists(proposedDestination.lastPathComponent)
                }
                try FileManager.default.moveItem(at: normalizedSource, to: proposedDestination)
            }
            return .success
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    nonisolated static func hasConflicts(
        sourceURLs: [URL],
        destinationDirectoryURL: URL
    ) -> Bool {
        sourceURLs.contains { sourceURL in
            let destinationURL = destinationDirectoryURL
                .appendingPathComponent(sourceURL.lastPathComponent)
            return sourceURL.standardizedFileURL != destinationURL.standardizedFileURL
                && FileManager.default.fileExists(atPath: destinationURL.path)
        }
    }

    nonisolated static func nextAvailableCopyURL(
        for sourceURL: URL,
        in directoryURL: URL
    ) -> URL {
        let extensionName = sourceURL.pathExtension
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        var copyIndex = 1

        while true {
            let suffix = copyIndex == 1 ? " copy" : " copy \(copyIndex)"
            let name = extensionName.isEmpty
                ? baseName + suffix
                : baseName + suffix + "." + extensionName
            let candidate = directoryURL.appendingPathComponent(name)
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            copyIndex += 1
        }
    }
}

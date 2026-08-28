import Foundation

enum WorkspacePathPolicy {
    static func contains(_ candidateURL: URL, within rootURL: URL) -> Bool {
        let rootPath = normalizedPath(for: rootURL)
        let candidatePath = normalizedPath(for: candidateURL)

        if candidatePath == rootPath {
            return true
        }
        let rootPrefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
        return candidatePath.hasPrefix(rootPrefix)
    }

    static func relativePath(from rootURL: URL, to candidateURL: URL) -> String? {
        guard contains(candidateURL, within: rootURL) else {
            return nil
        }
        let rootPath = normalizedPath(for: rootURL)
        let candidatePath = normalizedPath(for: candidateURL)
        guard candidatePath != rootPath else {
            return ""
        }
        return String(candidatePath.dropFirst(rootPath.count + 1))
    }

    /// Directories strictly between `rootURL` and `candidateURL`, inclusive
    /// of `rootURL` itself but excluding `candidateURL`. Used to build the
    /// column chain for the Miller-column browser: each returned URL becomes
    /// one column, and `candidateURL`'s own contents form the final column.
    /// Returns an empty array when `candidateURL` is `rootURL` itself.
    static func ancestorChain(from rootURL: URL, to candidateURL: URL) -> [URL] {
        guard let relative = relativePath(from: rootURL, to: candidateURL), !relative.isEmpty else {
            return []
        }
        let components = relative.split(separator: "/").map(String.init)
        var chain: [URL] = [rootURL.standardizedFileURL]
        var current = rootURL.standardizedFileURL
        for component in components.dropLast() {
            current = current.appendingPathComponent(component)
            chain.append(current)
        }
        return chain
    }

    private static func normalizedPath(for url: URL) -> String {
        url.standardizedFileURL
            .resolvingSymlinksInPath()
            .path
    }
}


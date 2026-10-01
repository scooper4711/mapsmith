import Foundation
import UniformTypeIdentifiers

/// Saves images dropped as raw data (for example dragged out of another app) so they can be
/// opened like any other file.
public struct DroppedImageStore: Sendable {
    public static let defaultName = "Dropped Map"

    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    /// The app's cache folder: dropped images are working copies, not documents to keep.
    public static var standard: DroppedImageStore {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let folder = Bundle.main.bundleIdentifier ?? "FlipMapPrinter"
        return DroppedImageStore(directory: caches.appendingPathComponent(folder).appendingPathComponent("Dropped Maps"))
    }

    /// Writes the image under a name not already in use and returns where it went.
    public func save(_ data: Data, suggestedName: String?, type: UTType) throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = unusedURL(baseName: Self.baseName(from: suggestedName),
                            fileExtension: type.preferredFilenameExtension ?? "png")
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func baseName(from suggestedName: String?) -> String {
        let stem = suggestedName.map { ($0 as NSString).deletingPathExtension } ?? ""
        let safe = stem.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespaces)
        return safe.isEmpty ? defaultName : safe
    }

    private func unusedURL(baseName: String, fileExtension: String) -> URL {
        var candidate = directory.appendingPathComponent(baseName).appendingPathExtension(fileExtension)
        var suffix = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(baseName) \(suffix)").appendingPathExtension(fileExtension)
            suffix += 1
        }
        return candidate
    }
}

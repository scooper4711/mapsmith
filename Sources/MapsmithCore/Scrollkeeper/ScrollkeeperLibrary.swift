import Foundation
import UniformTypeIdentifiers

/// Scrollkeeper's list of the whole library, `library.json` in its folder in the App Group (`ScrollkeeperFolder`).
/// Mapsmith reads it directly, so the list of maps shows at once, with covers, without asking Scrollkeeper.
///
/// A mirror of the library list in Scrollkeeper's `docs/specs/app-handoff/design.md`, holding only what Mapsmith
/// uses; Scrollkeeper may add fields without a version change.
public struct ScrollkeeperLibrary: Decodable, Sendable {
    struct Title: Decodable, Sendable {
        var sku: String
        var title: String
        var kind: String
        var series: String?
        var number: Int?
        /// The cover's path in Scrollkeeper's folder.
        var cover: String?
        var downloaded: Bool
        var editions: [Edition]
    }

    struct Edition: Decodable, Sendable {
        /// Where the edition is kept, relative to the download folder.
        var path: String
        var isFolder: Bool
        var downloaded: Bool
        var outdated: Bool
    }

    struct DownloadFolder: Decodable, Sendable {
        /// False when the user chose a folder of their own, which Mapsmith can't read.
        var isShared: Bool
    }

    /// The newest format this version of Mapsmith understands.
    public static let supportedFormatVersion = 1
    public static let fileName = "library.json"
    /// The Darwin notification Scrollkeeper sends after it writes the list.
    public static let changeNotification = "io.github.scooper4711.tableside.library-changed"
    static let mapKind = "Maps"

    var formatVersion: Int
    var generatedAt: Date
    var downloadFolder: DownloadFolder
    var titles: [Title]

    /// The maps, as the window lists them, with their covers in `folder` and, for those on disk in the shared
    /// download folder, the files to open.
    func mapIndex(in folder: URL) -> ScrollkeeperIndex {
        let files = downloadFolder.isShared ? folder.appending(path: "Files", directoryHint: .isDirectory) : nil
        let maps = titles.filter { $0.kind == Self.mapKind }.map { $0.entry(in: folder, files: files) }
        return ScrollkeeperIndex(formatVersion: formatVersion, generatedAt: generatedAt, titles: maps)
    }
}

extension ScrollkeeperLibrary.Title {
    func entry(in folder: URL, files: URL?) -> ScrollkeeperIndex.Entry {
        var entry = ScrollkeeperIndex.Entry(sku: sku, title: title, series: series, number: number,
                                            downloaded: downloaded)
        entry.coverURL = cover.map { folder.appending(path: $0) }
        entry.localFiles = files.map(mapFiles(in:)) ?? []
        return entry
    }

    /// The files to open, chosen as Scrollkeeper would (its app-handoff requirements 2.3 and 2.5): an up-to-date
    /// single file first; otherwise an unpacked archive's PDFs, or its images when it has no PDF.
    func mapFiles(in files: URL) -> [URL] {
        let ready = editions.filter { $0.downloaded && !$0.outdated }
        if let single = ready.first(where: { !$0.isFolder && Self.opens(URL(filePath: $0.path)) }) {
            return [files.appending(path: single.path)]
        }
        guard let archive = ready.first(where: \.isFolder) else { return [] }
        let documents = Self.regularFiles(under: files.appending(path: archive.path)).filter(Self.opens)
        let pdfs = documents.filter { Self.type(of: $0)?.conforms(to: .pdf) == true }
        return pdfs.isEmpty ? documents : pdfs
    }

    /// True for a PDF or an image, the files Mapsmith opens.
    private static func opens(_ file: URL) -> Bool {
        guard let type = type(of: file) else { return false }
        return type.conforms(to: .pdf) || type.conforms(to: .image)
    }

    private static func type(of file: URL) -> UTType? {
        UTType(filenameExtension: file.pathExtension)
    }

    private static func regularFiles(under folder: URL) -> [URL] {
        let enumerator = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: [.isRegularFileKey],
                                                        options: .skipsHiddenFiles)
        let files = (enumerator?.compactMap { $0 as? URL } ?? []).filter { url in
            (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
        }
        return files.sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
    }
}

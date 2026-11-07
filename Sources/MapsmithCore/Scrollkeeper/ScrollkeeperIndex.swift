import Foundation

/// The map titles the user owns, as Scrollkeeper lists them in the file it hands Mapsmith.
///
/// A mirror of the title index Scrollkeeper defines in its `docs/specs/app-handoff/design.md`.
public struct ScrollkeeperIndex: Decodable, Equatable, Sendable {
    /// One map title Scrollkeeper can open in Mapsmith.
    public struct Entry: Decodable, Equatable, Hashable, Sendable, Identifiable {
        public var sku: String
        public var title: String
        public var series: String?
        public var number: Int?
        /// Whether an up-to-date copy is on disk.
        public var downloaded: Bool
        /// The cover Scrollkeeper keeps in the App Group; nil when the list came as a file or has none.
        public var coverURL: URL?
        /// The files to open straight from Scrollkeeper's shared download folder, without asking Scrollkeeper;
        /// empty when the title isn't there.
        public var localFiles: [URL] = []

        public init(sku: String, title: String, series: String? = nil, number: Int? = nil, downloaded: Bool = true) {
            self.sku = sku
            self.title = title
            self.series = series
            self.number = number
            self.downloaded = downloaded
        }

        public var id: String { sku }

        /// Series and number for display under the title, such as "Flip-Mat Classics #4"; empty when unknown.
        public var subtitle: String {
            [series, number.map { "#\($0)" }].compactMap { $0 }.joined(separator: " ")
        }

        fileprivate var searchText: String { Self.folded([title, series ?? ""].joined(separator: " ")) }

        fileprivate static func folded(_ text: String) -> String {
            text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        }
    }

    /// The newest format this version of Mapsmith understands.
    public static let supportedFormatVersion = 1
    /// The extension of the file Scrollkeeper hands over.
    public static let fileExtension = "scrollkeeperindex"

    public var formatVersion: Int
    public var generatedAt: Date
    public var titles: [Entry]

    public init(formatVersion: Int = supportedFormatVersion, generatedAt: Date, titles: [Entry]) {
        self.formatVersion = formatVersion
        self.generatedAt = generatedAt
        self.titles = titles
    }

    /// True for the file Scrollkeeper hands over, as opposed to a map to open.
    public static func isIndexFile(_ url: URL) -> Bool {
        url.pathExtension.lowercased() == fileExtension
    }

    /// The titles whose title or series contains every word of the query, in index order.
    public func search(_ query: String) -> [Entry] {
        let words = Entry.folded(query).split(whereSeparator: \.isWhitespace)
        return titles.filter { entry in
            let text = entry.searchText
            return words.allSatisfy { text.contains($0) }
        }
    }

    /// Marks the title as on disk, once Scrollkeeper reports its download done.
    mutating func markDownloaded(_ sku: String) {
        guard let position = titles.firstIndex(where: { $0.sku == sku }) else { return }
        titles[position].downloaded = true
    }
}

extension ScrollkeeperIndex.Entry {
    /// The fields of the handed-over index; `coverURL` and `localFiles` come from the library list instead.
    private enum CodingKeys: String, CodingKey {
        case sku, title, series, number, downloaded
    }
}

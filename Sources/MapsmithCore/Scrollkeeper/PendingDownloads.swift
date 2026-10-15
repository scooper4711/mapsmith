import Foundation

/// The titles the user asked Scrollkeeper to download from the search sheet, until the map list
/// shows them on disk.
public struct PendingDownloads: Equatable, Sendable {
    public private(set) var skus: Set<String> = []

    public init() {}

    public var isEmpty: Bool { skus.isEmpty }

    public func contains(_ entry: ScrollkeeperMapIndex.Entry) -> Bool { skus.contains(entry.sku) }

    public mutating func insert(_ entry: ScrollkeeperMapIndex.Entry) {
        skus.insert(entry.sku)
    }

    /// Drops the titles the fresh map list shows as downloaded, or no longer lists at all.
    public mutating func settle(with index: ScrollkeeperMapIndex) {
        let waiting = Set(index.titles.filter(\.needsDownload).map(\.sku))
        skus.formIntersection(waiting)
    }
}

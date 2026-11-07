import Foundation
import TablesideShared
import UniformTypeIdentifiers

/// Scrollkeeper's library list (`ScrollkeeperLibrary` in tabletop-kit's `TablesideShared`) as Mapsmith lists it.
extension ScrollkeeperLibrary {
    static let mapKind = "Maps"

    /// The maps, as the window lists them, with their covers in Scrollkeeper's `folder` and, for those on disk in
    /// the shared download folder, the PDFs or images to open.
    func mapIndex(in folder: URL) -> ScrollkeeperIndex {
        let files = downloadFolderURL(in: folder)
        let maps = titles.filter { $0.kind == Self.mapKind }.map { title in
            var entry = ScrollkeeperIndex.Entry(sku: title.sku, title: title.title, series: title.series,
                                                number: title.number, downloaded: title.downloaded)
            entry.coverURL = title.coverURL(in: folder)
            entry.localFiles = files.map { title.filesToOpen(in: $0, accepting: Self.opensInMapsmith) } ?? []
            return entry
        }
        return ScrollkeeperIndex(formatVersion: formatVersion, generatedAt: generatedAt, titles: maps)
    }

    /// PDFs and images, the files Mapsmith opens.
    private static func opensInMapsmith(_ type: UTType) -> Bool {
        type.conforms(to: .pdf) || type.conforms(to: .image)
    }
}

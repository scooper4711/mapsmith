import Foundation
import UniformTypeIdentifiers

/// What File ▸ New from Clipboard opens: PDFs or images copied as files (in Finder or Files), or else image data
/// copied from another app (Pluck, a browser, Preview, a screenshot).
public enum ClipboardMap: Equatable {
    case files([URL])
    case data(UTType)

    /// The name pasted data is saved under, so the window has a sensible title.
    public static let defaultName = "Pasted Map"

    /// Copied files win, as in a drop. When files are on the clipboard but none is a map, there is nothing to open:
    /// Finder also puts the files' icons there as images, which are not maps.
    public static func content(fileURLs: [URL], types: [UTType]) -> ClipboardMap? {
        guard fileURLs.isEmpty else {
            let maps = fileURLs.filter(isMapFile)
            return maps.isEmpty ? nil : .files(maps)
        }
        return preferredDataType(among: types).map(ClipboardMap.data)
    }

    /// PNG when offered, since it is lossless; then any other image; then a PDF.
    public static func preferredDataType(among types: [UTType]) -> UTType? {
        if types.contains(.png) { return .png }
        return types.first { $0.conforms(to: .image) } ?? types.first { $0.conforms(to: .pdf) }
    }

    /// A PDF or an image, judged by the file's extension.
    public static func isMapFile(_ url: URL) -> Bool {
        guard url.isFileURL, let type = UTType(filenameExtension: url.pathExtension) else { return false }
        return type.conforms(to: .pdf) || type.conforms(to: .image)
    }
}

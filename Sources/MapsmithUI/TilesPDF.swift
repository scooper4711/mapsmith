import SwiftUI
import UniformTypeIdentifiers

/// Rendered tiles, for the file exporter.
struct TilesPDF: FileDocument {
    static let readableContentTypes: [UTType] = [.pdf]

    let data: Data
    /// The suggested file name, without the extension.
    let name: String

    init(data: Data, name: String) {
        self.data = data
        self.name = name
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        self.data = data
        name = configuration.file.filename ?? "Tiles"
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

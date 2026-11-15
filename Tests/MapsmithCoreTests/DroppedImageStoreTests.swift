import Foundation
import Testing
import UniformTypeIdentifiers
@testable import MapsmithCore

@Suite struct DroppedImageStoreTests {
    let store = DroppedImageStore(directory: FileManager.default.temporaryDirectory
        .appendingPathComponent("MapsmithTests-\(UUID().uuidString)"))
    let data = Data([1, 2, 3])

    @Test func savesUnderTheSuggestedNameWithTheTypesExtension() throws {
        let url = try store.save(data, suggestedName: "Hellknight Hill-p012-03.webp", type: .png)

        #expect(url.lastPathComponent == "Hellknight Hill-p012-03.png")
        #expect(try Data(contentsOf: url) == data)
    }

    @Test func neverOverwritesAnEarlierDrop() throws {
        let names = try (0..<3).map { _ in
            try store.save(data, suggestedName: nil, type: .tiff).lastPathComponent
        }
        #expect(names == ["Dropped Map.tiff", "Dropped Map 2.tiff", "Dropped Map 3.tiff"])
    }

    @Test func copiesADroppedFileWithoutReplacingAnother() throws {
        let original = FileManager.default.temporaryDirectory.appendingPathComponent("drop-\(UUID().uuidString).pdf")
        try data.write(to: original)
        defer { try? FileManager.default.removeItem(at: original) }

        let first = try store.saveCopy(of: original, suggestedName: "Forest.pdf", type: .pdf)
        let second = try store.saveCopy(of: original, suggestedName: "Forest.pdf", type: .pdf)

        #expect([first, second].map(\.lastPathComponent) == ["Forest.pdf", "Forest 2.pdf"])
        #expect(try Data(contentsOf: second) == data)
        #expect(FileManager.default.fileExists(atPath: original.path))
    }

    @Test func keepsDropsInTheCachesFolder() {
        let path = DroppedImageStore.standard.directory.path
        #expect(path.contains("/Caches/") && path.hasSuffix("/Dropped Maps"))
    }

    @Test func unusableNamesFallBackToTheDefault() throws {
        #expect(try store.save(data, suggestedName: "  .png", type: .png).lastPathComponent == "Dropped Map.png")
        #expect(try store.save(data, suggestedName: "a/b:c", type: .jpeg).lastPathComponent == "a-b-c.jpeg")
    }
}

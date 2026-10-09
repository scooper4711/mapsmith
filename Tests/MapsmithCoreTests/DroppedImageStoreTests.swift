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

    @Test func unusableNamesFallBackToTheDefault() throws {
        #expect(try store.save(data, suggestedName: "  .png", type: .png).lastPathComponent == "Dropped Map.png")
        #expect(try store.save(data, suggestedName: "a/b:c", type: .jpeg).lastPathComponent == "a-b-c.jpeg")
    }
}

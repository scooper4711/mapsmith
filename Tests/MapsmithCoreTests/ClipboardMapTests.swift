import Foundation
import Testing
import UniformTypeIdentifiers
@testable import MapsmithCore

@Suite struct ClipboardMapTests {
    let map = URL(fileURLWithPath: "/Maps/Forest.pdf")
    let picture = URL(fileURLWithPath: "/Maps/Cave.webp")
    let notes = URL(fileURLWithPath: "/Maps/Notes.txt")

    @Test func copiedMapFilesOpenAsFiles() {
        let content = ClipboardMap.content(fileURLs: [map, notes, picture], types: [.fileURL, .tiff])
        #expect(content == .files([map, picture]))
    }

    @Test func copiedFilesThatAreNotMapsOpenNothingNotEvenTheirIcons() {
        #expect(ClipboardMap.content(fileURLs: [notes], types: [.fileURL, .tiff]) == nil)
    }

    @Test func imageDataPrefersPNG() {
        #expect(ClipboardMap.content(fileURLs: [], types: [.tiff, .png]) == .data(.png))
    }

    @Test func imageDataFallsBackToTheFirstImageType() {
        #expect(ClipboardMap.content(fileURLs: [], types: [.utf8PlainText, .jpeg, .tiff]) == .data(.jpeg))
    }

    @Test func pdfDataIsUsedOnlyWithoutAnImage() {
        #expect(ClipboardMap.content(fileURLs: [], types: [.pdf]) == .data(.pdf))
        #expect(ClipboardMap.content(fileURLs: [], types: [.pdf, .tiff]) == .data(.tiff))
    }

    @Test func textAloneIsNotAMap() {
        #expect(ClipboardMap.content(fileURLs: [], types: [.utf8PlainText, .url]) == nil)
        #expect(ClipboardMap.content(fileURLs: [], types: []) == nil)
    }

    @Test func onlyLocalFilesCount() throws {
        let remote = try #require(URL(string: "https://example.com/map.png"))
        #expect(!ClipboardMap.isMapFile(remote))
        #expect(!ClipboardMap.isMapFile(URL(fileURLWithPath: "/Maps/README")))
    }
}

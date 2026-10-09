import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import MapsmithCore

@Suite struct MapSourceTests {
    let map = TestSupport.gridImage(width: 600, height: 400, spacing: 50)

    /// Writes `image` as a PNG, with `dpi` in its metadata when given.
    func pngFile(_ image: CGImage, dpi: Double? = nil, name: String = "Map") throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appendingPathComponent("\(name).png")
        let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString,
                                                                       1, nil))
        let properties = dpi.map { [kCGImagePropertyDPIWidth: $0, kCGImagePropertyDPIHeight: $0] } ?? [:]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return url
    }

    @Test func anImageFileIsOneMapNamedAfterTheFile() throws {
        let url = try pngFile(map, name: "Goblin Cave")
        let items = try MapItem.items(in: url)
        #expect(items.map(\.title) == ["Goblin Cave"] && items.first?.source == .imageFile(url))
    }

    @Test func aPDFListsEachMapByPageNumberingSeveralOnOnePage() throws {
        let url = try TestSupport.writePDF(pages: [
            [(map, CGRect(x: 0, y: 0, width: 300, height: 200)), (map, CGRect(x: 0, y: 400, width: 300, height: 200))],
            [(map, CGRect(x: 0, y: 0, width: 600, height: 400))]
        ])
        let titles = try MapItem.items(in: url).map(\.title)
        #expect(titles.count == 3 && titles.last == "Page 2")
        #expect(titles.filter { $0.hasPrefix("Page 1 – map ") }.count == 2)
    }

    @Test func aFileThatIsNotAPDFCannotBeOpened() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID()).pdf")
        try Data("not a pdf".utf8).write(to: url)
        #expect(throws: MapLoadError.unreadableFile(url.lastPathComponent)) { try MapItem.items(in: url) }
        #expect(throws: MapLoadError.unreadableFile(url.lastPathComponent)) {
            try MapLoader.load(.imageFile(url))
        }
        #expect(MapLoadError.unreadableFile("a.pdf").description == "Cannot open a.pdf")
        #expect(MapLoadError.renderFailed("a.pdf").description == "Cannot render a.pdf")
    }

    @Test func anImageFallsBackOnItsDPIUnlessItIsTheDefault72() throws {
        let tagged = try MapLoader.load(.imageFile(pngFile(map, dpi: 150)))
        #expect(tagged.fallbackPixelsPerInch == 150 && tagged.fallbackDescription == "image metadata (150 DPI)")
        let untagged = try MapLoader.load(.imageFile(pngFile(map, dpi: 72)))
        #expect(untagged.fallbackPixelsPerInch == nil && untagged.fallbackDescription == "none")
        #expect((untagged.image.width, untagged.image.height) == (600, 400))
    }

    @Test func aPDFMapRendersAtNoLessThan300DPI() throws {
        // 600 × 400 px drawn over 8 × 5⅓ in is 75 DPI, raised to 300.
        let url = try TestSupport.writePDF(pages: [[(map, CGRect(x: 0, y: 0, width: 576, height: 384))]])
        let item = try #require(MapItem.items(in: url).first)
        guard case let .pdfRegion(_, region) = item.source else { Issue.record("Not a PDF map"); return }
        let loaded = try MapLoader.load(item.source)
        #expect(loaded.fallbackPixelsPerInch == 300 && loaded.fallbackDescription == "PDF page scale (300 DPI)")
        #expect(loaded.image.width == Int((region.rect.width * 300 / pointsPerInch).rounded()))
    }

    @Test func renderResolutionIsClampedAndCappedForHugeMaps() {
        let small = PDFMapRegion(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 72, height: 72),
                                 pixelSize: CGSize(width: 10_000, height: 10_000))
        #expect(MapLoader.renderDPI(for: small) == 600)
        let whole = PDFMapRegion(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 72, height: 72), pixelSize: .zero)
        #expect(MapLoader.renderDPI(for: whole) == 300)
        let huge = PDFMapRegion(pageIndex: 0, rect: CGRect(x: 0, y: 0, width: 72 * 100, height: 72 * 100),
                                pixelSize: .zero)
        #expect(MapLoader.renderDPI(for: huge) < 300)
    }

    @Test func thumbnailsFitTheMaximumSize() throws {
        let image = try MapLoader.thumbnail(.imageFile(pngFile(map)), maximumSize: 120)
        #expect(max(image.width, image.height) == 120)
        let url = try TestSupport.writePDF(pages: [[(map, CGRect(x: 0, y: 0, width: 144, height: 96))]])
        let item = try #require(MapItem.items(in: url).first)
        let pdfThumbnail = try MapLoader.thumbnail(item.source, maximumSize: 120)
        #expect(max(pdfThumbnail.width, pdfThumbnail.height) == 120)
    }

    @Test func missingFilesAndPagesFailToLoad() {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID()).png")
        #expect(throws: MapLoadError.unreadableFile(missing.lastPathComponent)) {
            try MapLoader.thumbnail(.imageFile(missing), maximumSize: 100)
        }
        let region = PDFMapRegion(pageIndex: 3, rect: CGRect(x: 0, y: 0, width: 72, height: 72), pixelSize: .zero)
        let pdf = missing.deletingPathExtension().appendingPathExtension("pdf")
        #expect(throws: MapLoadError.renderFailed(pdf.lastPathComponent)) {
            try MapLoader.load(.pdfRegion(pdf, region))
        }
    }
}

import CoreGraphics
import Foundation
import Testing
@testable import MapsmithCore

@Suite struct TileExporterTests {
    @Test func exportsOnePaperSizedPagePerTile() throws {
        let map = TestSupport.gridImage(width: 1000, height: 1000, spacing: 100)
        let settings = TileSettings(page: TestSupport.letterPage)
        let plan = TilePlanner.plan(mapSize: CGSize(width: 1000, height: 1000), pixelsPerInch: 100, settings: settings)
        let data = try TileExporter.pdfData(map: map, plan: plan, page: settings.page)

        let document = try #require(CGDataProvider(data: data as CFData).flatMap(CGPDFDocument.init))
        #expect(document.numberOfPages == plan.sheetCount)
        #expect(document.page(at: 1)?.getBoxRect(.mediaBox).size == CGSize(width: 612, height: 792))
    }

    @Test func tilesKeepTrueScaleAndSitInPrintableArea() throws {
        let map = TestSupport.gridImage(width: 1000, height: 1000, spacing: 100)
        let settings = TileSettings(page: TestSupport.letterPage)
        let plan = TilePlanner.plan(mapSize: CGSize(width: 1000, height: 1000), pixelsPerInch: 100, settings: settings)
        let data = try TileExporter.pdfData(map: map, plan: plan, page: settings.page)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID()).pdf")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let placements = PDFMapFinder.maps(in: try #require(CGPDFDocument(url as CFURL)))
        // First tile: 800 × 1000 px at 100 PPI → 8 × 10 in, top-left at the printable area's corner.
        let first = try #require(placements.first)
        #expect(first.rect.equalTo(CGRect(x: 18, y: 774 - 720, width: 576, height: 720)))
    }

    @Test func rotationSwapsDimensions() throws {
        let image = TestSupport.blankImage(width: 300, height: 100)
        let rotated = try TileExporter.rotatedClockwise(image)
        #expect((rotated.width, rotated.height) == (100, 300))
    }
}

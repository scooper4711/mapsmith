import CoreGraphics
import Foundation
import Testing
@testable import MapsmithCore

@Suite struct PDFMapFinderTests {
    let map = TestSupport.gridImage(width: 600, height: 600, spacing: 50)
    let logo = TestSupport.blankImage(width: 60, height: 20)

    func regions(_ pages: [[(CGImage, CGRect)]]) throws -> [PDFMapRegion] {
        let url = try TestSupport.writePDF(pages: pages)
        defer { try? FileManager.default.removeItem(at: url) }
        return PDFMapFinder.maps(in: try #require(CGPDFDocument(url as CFURL)))
    }

    @Test func findsLargeImageAndItsPlacement() throws {
        let found = try regions([[(map, CGRect(x: 72, y: 72, width: 288, height: 288))]])
        #expect(found.count == 1)
        #expect(found[0].rect.equalTo(CGRect(x: 72, y: 72, width: 288, height: 288)))
        #expect(found[0].pixelSize == CGSize(width: 600, height: 600))
        #expect(abs(found[0].nativeDPI - 150) < 0.01)
    }

    @Test func ignoresSmallDecorations() throws {
        let found = try regions([[(map, CGRect(x: 36, y: 36, width: 540, height: 540)),
                                  (logo, CGRect(x: 500, y: 700, width: 90, height: 30))]])
        #expect(found.count == 1)
    }

    @Test func mergesStackedImagesOnSameArea() throws {
        let rect = CGRect(x: 36, y: 36, width: 540, height: 540)
        let found = try regions([[(map, rect), (TestSupport.gridImage(width: 900, height: 900, spacing: 75), rect)]])
        #expect(found.count == 1)
        #expect(found[0].pixelSize == CGSize(width: 900, height: 900))
    }

    @Test func keepsSeparateMapsOnOnePage() throws {
        let found = try regions([[(map, CGRect(x: 36, y: 36, width: 250, height: 300)),
                                  (map, CGRect(x: 320, y: 36, width: 250, height: 300))]])
        #expect(found.count == 2)
    }

    @Test func reportsPageIndex() throws {
        let found = try regions([[(logo, CGRect(x: 0, y: 0, width: 60, height: 20))],
                                 [(map, CGRect(x: 36, y: 36, width: 540, height: 540))]])
        #expect(found.map(\.pageIndex) == [1])
    }

    @Test func documentWithoutImagesOffersWholePages() throws {
        let found = try regions([[], []])
        #expect(found.map(\.pageIndex) == [0, 1])
        #expect(found[0].rect.equalTo(CGRect(x: 0, y: 0, width: 612, height: 792)))
    }

    @Test(.enabled(if: TestSupport.hasSamplePDFs))
    func sampleFlipMatsHaveOneMapPerPage() throws {
        for url in TestSupport.samplePDFs {
            let found = PDFMapFinder.maps(in: try #require(CGPDFDocument(url as CFURL)))
            #expect(found.map(\.pageIndex) == [0, 1], "\(url.lastPathComponent)")
            for region in found {
                #expect(abs(region.rect.width / pointsPerInch - 24) < 0.1)
                #expect(abs(region.rect.height / pointsPerInch - 30) < 0.1)
                #expect(abs(region.nativeDPI - 150) < 2, "\(url.lastPathComponent): \(region.nativeDPI)")
            }
        }
    }
}

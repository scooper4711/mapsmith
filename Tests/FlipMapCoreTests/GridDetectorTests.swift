import CoreGraphics
import Foundation
import Testing
@testable import FlipMapCore

@Suite struct GridDetectorTests {
    @Test(arguments: [50.0, 72.0, 100.0, 150.0])
    func detectsCleanGrid(spacing: Double) throws {
        let image = TestSupport.gridImage(width: 1500, height: 1200, spacing: spacing)
        #expect(abs(try GridDetector.spacing(in: image) - spacing) / spacing < 0.005)
    }

    @Test func detectsGridThroughBusyArt() throws {
        let image = TestSupport.gridImage(width: 1600, height: 1600, spacing: 80, lineWidth: 2, noise: true)
        #expect(abs(try GridDetector.spacing(in: image) - 80) < 0.5)
    }

    @Test func detectsNonIntegerSpacingInLargeImage() throws {
        // Downsampled to 2000 px for analysis; result must scale back.
        let image = TestSupport.gridImage(width: 4000, height: 3000, spacing: 150.5, lineWidth: 2)
        #expect(abs(try GridDetector.spacing(in: image) - 150.5) < 0.75)
    }

    @Test func blankImageHasNoGrid() {
        #expect(throws: GridDetectionError.self) {
            try GridDetector.spacing(in: TestSupport.blankImage(width: 800, height: 800))
        }
    }

    @Test func tinyImageIsRejected() {
        #expect(throws: GridDetectionError.imageTooSmall) {
            try GridDetector.spacing(in: TestSupport.blankImage(width: 10, height: 10))
        }
    }

    /// Flip-Mat squares are about 1 in at PDF scale; PZO7303E's are drawn 2% large, which
    /// is exactly what detection is for, so allow 3%.
    @Test(.enabled(if: TestSupport.hasSamplePDFs))
    func sampleFlipMatsHaveRoughlyOneInchSquares() throws {
        for url in TestSupport.samplePDFs {
            for item in try MapItem.items(in: url) {
                let map = try MapLoader.load(item.source)
                let spacing = try GridDetector.spacing(in: map.image)
                let pdfScale = try #require(map.fallbackPixelsPerInch)
                #expect(abs(spacing - pdfScale) / pdfScale < 0.03, "\(url.lastPathComponent) \(item.title): \(spacing)")
            }
        }
    }
}

import CoreGraphics
import Testing
@testable import MapsmithCore

@Suite struct PaperChoiceTests {
    @Test func insetsThePaperByTheMargin() {
        let page = PaperChoice.letter.geometry(marginInches: 0.25)
        #expect(page.paperSize == CGSize(width: 612, height: 792))
        #expect(page.imageableRect == CGRect(x: 18, y: 18, width: 576, height: 756))
        #expect(page.imageableSizeInches == CGSize(width: 8, height: 10.5))
    }

    @Test func keepsTheMarginInRange() {
        #expect(PaperChoice.a4.geometry(marginInches: -1).imageableRect.minX == 0)
        #expect(PaperChoice.a4.geometry(marginInches: 9).imageableRect.minX == 2 * pointsPerInch)
    }

    @Test func everyPaperIsPortraitAndNamed() {
        for paper in PaperChoice.allCases {
            #expect(paper.size.height > paper.size.width)
            #expect(!paper.title.isEmpty)
            #expect(paper.id == paper.rawValue)
        }
    }

    @Test func picksLetterOrA4ByRegion() {
        #expect(PaperChoice.regionalDefault(regionCode: "US") == .letter)
        #expect(PaperChoice.regionalDefault(regionCode: "CA") == .letter)
        #expect(PaperChoice.regionalDefault(regionCode: "DE") == .a4)
        #expect(PaperChoice.regionalDefault(regionCode: nil) == .a4)
    }
}

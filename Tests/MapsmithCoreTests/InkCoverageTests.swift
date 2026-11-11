import CoreGraphics
import Testing
@testable import MapsmithCore

@Suite struct InkCoverageTests {
    @Test func whitePaperNeedsNoInk() throws {
        let pages = try coverage(of: TestSupport.blankImage(width: 1000, height: 1000))
        #expect(pages.allSatisfy { $0.cyan < 0.001 && $0.magenta < 0.001 && $0.yellow < 0.001 && $0.black < 0.001 })
    }

    @Test func blackMapIsMostlyBlackInk() throws {
        let total = try coverage(of: Self.solidImage(width: 800, height: 1000, gray: 0)).reduce(.zero, +)
        #expect(total.black > 0.5)
    }

    @Test func coverageIsTheTilesShareOfThePaper() throws {
        // 8 × 10 in of black on an 8.5 × 11 in sheet: the printed share of the sheet bounds the coverage.
        let page = try #require(coverage(of: Self.solidImage(width: 800, height: 1000, gray: 0)).first)
        let share = (8.0 * 10) / (8.5 * 11)
        #expect(page.black <= share + 0.01)
        #expect(page.black > share * 0.6)
    }

    @Test func cyanMapIsMostlyCyanInk() throws {
        let context = TestSupport.bitmapContext(width: 400, height: 400)
        context.setFillColor(CGColor(srgbRed: 0, green: 0.7, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 400, height: 400))
        let image = try #require(context.makeImage())
        let page = try #require(coverage(of: image).first)
        #expect(page.cyan > page.magenta)
        #expect(page.cyan > page.yellow)
        #expect(page.cyan > page.black)
    }

    @Test func aRotatedPlanIsEstimatedPerTile() throws {
        let map = Self.solidImage(width: 1050, height: 800, gray: 0)
        let settings = TileSettings(page: TestSupport.letterPage)
        let plan = TilePlanner.plan(mapSize: CGSize(width: 1050, height: 800), pixelsPerInch: 100, settings: settings)
        #expect(plan.rotated)
        let pages = try InkCoverageEstimator.coverage(map: map, plan: plan, page: settings.page)
        #expect(pages.count == plan.sheetCount)
    }

    @Test func aTileOutsideTheMapCannotBeEstimated() {
        let map = TestSupport.blankImage(width: 10, height: 10)
        let plan = Self.onePagePlan(pixelsPerInch: 10, mapSide: 10, tile: CGRect(x: 50, y: 50, width: 10, height: 10))
        #expect(throws: TileExportError.imageProcessingFailed("cropping a tile for the ink estimate")) {
            try InkCoverageEstimator.coverage(map: map, plan: plan, page: TestSupport.letterPage)
        }
    }

    @Test func paperWithNoAreaNeedsNoInk() throws {
        let map = TestSupport.blankImage(width: 100, height: 100)
        let plan = Self.onePagePlan(pixelsPerInch: 100, mapSide: 100, tile: CGRect(x: 0, y: 0, width: 100, height: 100))
        let page = PageGeometry(paperSize: .zero, imageableRect: .zero)
        #expect(try InkCoverageEstimator.coverage(map: map, plan: plan, page: page) == [.zero])
    }

    @Test func coveragesAddUpAndLookUpByInk() {
        let sum = InkCoverage(cyan: 0.1, magenta: 0.2, yellow: 0.3, black: 0.4) + InkCoverage(cyan: 0.1, black: 0.1)
        #expect(abs(sum[.cyan] - 0.2) < 1e-9)
        #expect(abs(sum[.magenta] - 0.2) < 1e-9)
        #expect(abs(sum[.yellow] - 0.3) < 1e-9)
        #expect(abs(sum[.black] - 0.5) < 1e-9)
        #expect(sum[.unused] == 0)
    }

    private func coverage(of map: CGImage) throws -> [InkCoverage] {
        let settings = TileSettings(page: TestSupport.letterPage)
        let size = CGSize(width: map.width, height: map.height)
        let plan = TilePlanner.plan(mapSize: size, pixelsPerInch: 100, settings: settings)
        return try InkCoverageEstimator.coverage(map: map, plan: plan, page: settings.page)
    }

    static func onePagePlan(pixelsPerInch: CGFloat, mapSide: CGFloat, tile: CGRect) -> TilePlan {
        TilePlan(rotated: false, columns: 1, rows: 1, pixelsPerInch: pixelsPerInch,
                 mapSize: CGSize(width: mapSide, height: mapSide), tiles: [tile])
    }

    static func solidImage(width: Int, height: Int, gray: CGFloat) -> CGImage {
        let context = TestSupport.bitmapContext(width: width, height: height)
        context.setFillColor(CGColor(gray: gray, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }
}

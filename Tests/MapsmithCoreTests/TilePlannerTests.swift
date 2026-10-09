import CoreGraphics
import Testing
@testable import MapsmithCore

@Suite struct TilePlannerTests {
    /// 8 × 10.5 in printable area at 100 PPI → 800 × 1050 px tiles.
    let settings = TileSettings(page: TestSupport.letterPage, minimumSliverInches: 0.5)

    @Test func exactFitUsesWholeTiles() {
        let plan = TilePlanner.plan(mapSize: CGSize(width: 1600, height: 1050), pixelsPerInch: 100, settings: settings)
        #expect((plan.columns, plan.rows, plan.rotated) == (2, 1, false))
        #expect(plan.tiles == [CGRect(x: 0, y: 0, width: 800, height: 1050), CGRect(x: 800, y: 0, width: 800, height: 1050)])
    }

    @Test func partialEdgeTileIsNarrower() {
        let plan = TilePlanner.plan(mapSize: CGSize(width: 1000, height: 1000), pixelsPerInch: 100, settings: settings)
        #expect(plan.columns == 2)
        #expect(plan.tiles.last?.width == 200)
    }

    @Test func thinSliverIsTrimmedFromBothSides() {
        // 1620 px = 2 tiles + 20 px (0.2 in < 0.5 in) → trim 10 px each side.
        let spans = TilePlanner.spans(length: 1620, tile: 800, minimumSliver: 50)
        #expect(spans == [10..<810, 810..<1610])
    }

    @Test func sliverAtThresholdIsKept() {
        #expect(TilePlanner.spans(length: 1650, tile: 800, minimumSliver: 50).count == 3)
    }

    @Test func mapSmallerThanOneTileIsNeverDropped() {
        #expect(TilePlanner.spans(length: 10, tile: 800, minimumSliver: 50) == [0..<10])
    }

    @Test func rotatesWhenThatSavesSheets() {
        // 21 × 8 in: upright needs 3 × 1 = 3 sheets; rotated (8 × 21) needs 1 × 2 = 2.
        let plan = TilePlanner.plan(mapSize: CGSize(width: 2100, height: 800), pixelsPerInch: 100, settings: settings)
        #expect(plan.rotated)
        #expect(plan.mapSize == CGSize(width: 800, height: 2100))
        #expect(plan.sheetCount == 2)
    }

    @Test func flipMatOnA4UsesNineSheets() {
        let plan = TilePlanner.plan(mapSize: CGSize(width: 7200, height: 9000), pixelsPerInch: 300,
                                    settings: TileSettings(page: .a4Default))
        #expect((plan.columns, plan.rows) == (3, 3))
    }
}

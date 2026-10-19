import CoreGraphics
import Testing
@testable import MapsmithCore

@Suite struct ScaleEntryTests {
    let mapSize = CGSize(width: 4200, height: 3000)

    @Test(arguments: [(ScaleEntry.pixelsPerSquare(150), 150.0), (.squaresAcross(28), 150), (.squaresDown(20), 150)])
    func turnsEachEntryIntoPixelsPerInch(entry: ScaleEntry, expected: Double) {
        #expect(entry.pixelsPerInch(mapSize: mapSize) == expected)
    }

    @Test(arguments: [ScaleEntry.pixelsPerSquare(0), .squaresAcross(-1), .squaresDown(0)])
    func refusesEntriesThatArentPositive(entry: ScaleEntry) {
        #expect(entry.pixelsPerInch(mapSize: mapSize) == nil)
    }

    @Test func needsAMapToCountSquares() {
        #expect(ScaleEntry.squaresAcross(28).pixelsPerInch(mapSize: .zero) == nil)
        #expect(ScaleEntry.pixelsPerSquare(150).pixelsPerInch(mapSize: .zero) == 150)
    }

    @Test func countsTheSquaresTheMapSpans() {
        #expect(ScaleEntry.squares(mapSize: mapSize, pixelsPerInch: 150) == CGSize(width: 28, height: 20))
        #expect(ScaleEntry.squares(mapSize: mapSize, pixelsPerInch: 0) == .zero)
    }
}
